#!/usr/bin/env python3
"""
Adds every song from a text list into a Spotify playlist.

Usage:
    pip install -r scripts/spotify_requirements.txt
    set the SPOTIPY_CLIENT_ID / SPOTIPY_CLIENT_SECRET / SPOTIPY_REDIRECT_URI
    env vars (see scripts/spotify_playlist_sync_README.md), then:

    python scripts/spotify_playlist_sync.py
    python scripts/spotify_playlist_sync.py --dry-run
    python scripts/spotify_playlist_sync.py --file path/to/list.txt --playlist "Beatspan"
"""

import argparse
import csv
import re
import sys
import time
import unicodedata
from pathlib import Path

import spotipy
from spotipy.oauth2 import SpotifyOAuth

SCOPE = (
    "playlist-modify-public playlist-modify-private "
    "playlist-read-private playlist-read-collaborative"
)

LINE_RE = re.compile(r"^\s*\d+:\d{4}\s*-\s*(.+)$")


def normalize(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    return text.lower().strip()


def split_title_artist(rest: str):
    """rest is 'Title (Artist)', where Artist can itself contain parentheses."""
    rest = rest.strip()
    if not rest.endswith(")"):
        return rest, ""
    depth = 0
    for i in range(len(rest) - 1, -1, -1):
        ch = rest[i]
        if ch == ")":
            depth += 1
        elif ch == "(":
            depth -= 1
            if depth == 0:
                title = rest[:i].strip()
                artist = rest[i + 1 : -1].strip()
                return title, artist
    return rest, ""


def parse_songs(path: Path):
    songs = []
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw.strip()
        if not line:
            continue
        m = LINE_RE.match(line)
        if not m:
            continue  # skip headers / annotation lines like "— todas do álbum ..."
        title, artist = split_title_artist(m.group(1))
        if not title:
            continue
        songs.append({"lineno": lineno, "title": title, "artist": artist})
    return songs


PLAYLIST_ID_RE = re.compile(r"^[A-Za-z0-9]{22}$")
PLAYLIST_URL_RE = re.compile(r"open\.spotify\.com/playlist/([A-Za-z0-9]{22})")
PLAYLIST_URI_RE = re.compile(r"^spotify:playlist:([A-Za-z0-9]{22})$")


def extract_playlist_id(value: str):
    match = PLAYLIST_URL_RE.search(value)
    if match:
        return match.group(1)
    match = PLAYLIST_URI_RE.match(value)
    if match:
        return match.group(1)
    if PLAYLIST_ID_RE.match(value):
        return value
    return None


def find_playlist(sp, name: str):
    offset = 0
    while True:
        page = sp.current_user_playlists(limit=50, offset=offset)
        for pl in page["items"]:
            if pl["name"].strip().lower() == name.strip().lower():
                return pl
        if not page["next"]:
            break
        offset += 50
    return None


def get_existing_track_ids(sp, playlist_id: str):
    ids = set()
    offset = 0
    while True:
        page = sp.playlist_items(
            playlist_id,
            fields="items.track.id,next",
            additional_types=["track"],
            limit=100,
            offset=offset,
        )
        for item in page["items"]:
            track = item.get("track")
            if track and track.get("id"):
                ids.add(track["id"])
        if not page["next"]:
            break
        offset += 100
    return ids


def artist_matches(expected_artist: str, result_artists) -> bool:
    if not expected_artist:
        return True
    expected_tokens = set(normalize(expected_artist).replace("/", " ").split())
    expected_tokens = {t for t in expected_tokens if len(t) > 2}
    if not expected_tokens:
        return True
    for a in result_artists:
        name_tokens = set(normalize(a["name"]).split())
        if expected_tokens & name_tokens:
            return True
    return False


def search_track(sp, title: str, artist: str):
    """Try increasingly loose queries; return (track, confident) or (None, False)."""
    queries = []
    if artist:
        queries.append(f'track:"{title}" artist:"{artist}"')
    queries.append(f"{title} {artist}".strip())
    queries.append(f'track:"{title}"')

    for q in queries:
        try:
            res = sp.search(q=q, type="track", limit=5)
        except spotipy.SpotifyException as e:
            print(f"  ! search error for {q!r}: {e}", file=sys.stderr)
            time.sleep(1)
            continue
        items = res.get("tracks", {}).get("items", [])
        if not items:
            continue
        for item in items:
            if artist_matches(artist, item["artists"]):
                return item, True
        return items[0], False
    return None, False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--file",
        default="assets/lista_corrigida_apenas_musicas.txt",
        help="Path to the song list text file",
    )
    parser.add_argument(
        "--playlist",
        default="Beatspan",
        help="Target playlist name, ID, URL, or spotify:playlist: URI",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Only produce the report, don't modify the playlist"
    )
    parser.add_argument(
        "--report",
        default="scripts/spotify_sync_report.csv",
        help="Where to write the CSV report",
    )
    args = parser.parse_args()

    songs = parse_songs(Path(args.file))
    print(f"Parsed {len(songs)} songs from {args.file}")

    auth_manager = SpotifyOAuth(scope=SCOPE, open_browser=True)
    sp = spotipy.Spotify(auth_manager=auth_manager)

    playlist_id = extract_playlist_id(args.playlist)
    if playlist_id:
        try:
            playlist = sp.playlist(playlist_id)
        except spotipy.SpotifyException:
            playlist = None
    else:
        playlist = find_playlist(sp, args.playlist)
    if not playlist:
        print(f"Playlist '{args.playlist}' not found in your account.", file=sys.stderr)
        sys.exit(1)
    print(f"Target playlist: {playlist['name']} ({playlist['id']})")

    existing_ids = get_existing_track_ids(sp, playlist["id"])
    print(f"Playlist already has {len(existing_ids)} tracks")

    to_add = []
    seen_this_run = set()
    report_rows = []

    for i, song in enumerate(songs, start=1):
        title, artist = song["title"], song["artist"]
        print(f"[{i}/{len(songs)}] {title} ({artist})")

        track, confident = search_track(sp, title, artist)
        if not track:
            report_rows.append(
                {**song, "status": "not_found", "spotify_track": "", "spotify_artist": "", "uri": ""}
            )
            continue

        track_id = track["id"]
        status = "confident_match" if confident else "low_confidence_match"

        if track_id in existing_ids or track_id in seen_this_run:
            status = "already_in_playlist"
        else:
            to_add.append(track_id)
            seen_this_run.add(track_id)

        report_rows.append(
            {
                **song,
                "status": status,
                "spotify_track": track["name"],
                "spotify_artist": ", ".join(a["name"] for a in track["artists"]),
                "uri": track["uri"],
            }
        )
        time.sleep(0.05)

    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    with report_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["lineno", "title", "artist", "status", "spotify_track", "spotify_artist", "uri"],
        )
        writer.writeheader()
        writer.writerows(report_rows)
    print(f"\nReport written to {report_path}")

    not_found = sum(1 for r in report_rows if r["status"] == "not_found")
    low_conf = sum(1 for r in report_rows if r["status"] == "low_confidence_match")
    print(f"Not found: {not_found}  |  Low-confidence matches: {low_conf}  |  New tracks to add: {len(to_add)}")

    if args.dry_run:
        print("Dry run: nothing was added to the playlist.")
        return

    for start in range(0, len(to_add), 100):
        batch = to_add[start : start + 100]
        sp.playlist_add_items(playlist["id"], batch)
        print(f"Added {len(batch)} tracks (batch starting at {start})")

    print("Done.")


if __name__ == "__main__":
    main()
