#!/usr/bin/env python3
"""
Gera o texto para colar no campo "Colar em lote" da Prensa Beatspan
(docs/prensa-beatspan.html), no formato `codigo;ano;artista;musica`,
usando a MESMA ordem da playlist Spotify "Beatspan" que popula o Firestore
(scripts/firestore_musicas_import.py) — garante que o código 0001 no verso
da carta aponte para o mesmo doc 0001 no Firestore.

Usage:
    set the SPOTIPY_CLIENT_ID / SPOTIPY_CLIENT_SECRET / SPOTIPY_REDIRECT_URI
    env vars, then:

    python scripts/generate_prensa_bulk.py
    python scripts/generate_prensa_bulk.py --out scripts/prensa_bulk.txt
"""

import argparse
import csv
import re
import sys
from pathlib import Path

import spotipy
from spotipy.oauth2 import SpotifyOAuth

SCOPE = "playlist-read-private playlist-read-collaborative"
LINE_RE = re.compile(r"^\s*\d+:(\d{4})\s*-\s*(.+)$")


def split_title_artist(rest: str):
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


def parse_years(path: Path):
    years = {}
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw.strip()
        m = LINE_RE.match(line)
        if not m:
            continue
        title, _artist = split_title_artist(m.group(2))
        if not title:
            continue
        years[lineno] = m.group(1)
    return years


def load_uri_map(report_path: Path, years: dict):
    """uri -> (ano, artista, musica), keeping the first lineno occurrence."""
    uri_map = {}
    with report_path.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            uri = row["uri"]
            if not uri or uri in uri_map:
                continue
            lineno = int(row["lineno"])
            uri_map[uri] = (years.get(lineno, "?"), row["artist"], row["title"])
    return uri_map


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


def get_playlist_tracks(sp, playlist_id: str):
    tracks = []
    offset = 0
    while True:
        page = sp.playlist_items(
            playlist_id,
            offset=offset,
            fields="items.track.id,items.track.uri,items.track.name,items.track.artists.name,next",
            additional_types=["track"],
        )
        for item in page["items"]:
            track = item.get("track")
            if track and track.get("id"):
                tracks.append(track)
        if not page.get("next"):
            break
        offset += len(page["items"])
    return tracks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--playlist", default="Beatspan")
    parser.add_argument("--file", default="assets/lista_corrigida_apenas_musicas.txt")
    parser.add_argument("--report", default="scripts/spotify_sync_report.csv")
    parser.add_argument("--out", default="scripts/prensa_bulk.txt")
    args = parser.parse_args()

    years = parse_years(Path(args.file))
    uri_map = load_uri_map(Path(args.report), years)

    auth_manager = SpotifyOAuth(scope=SCOPE, open_browser=True)
    sp = spotipy.Spotify(auth_manager=auth_manager)

    playlist = find_playlist(sp, args.playlist)
    if not playlist:
        print(f"Playlist '{args.playlist}' not found in your account.", file=sys.stderr)
        sys.exit(1)

    tracks = get_playlist_tracks(sp, playlist["id"])
    print(f"Playlist '{playlist['name']}' has {len(tracks)} tracks")

    lines = []
    missing = []
    for i, track in enumerate(tracks, start=1):
        codigo = f"{i:04d}"
        uri = track["uri"]
        info = uri_map.get(uri)
        if info:
            ano, artista, musica = info
        else:
            ano, artista, musica = "?", ", ".join(a["name"] for a in track["artists"]), track["name"]
            missing.append((codigo, uri, track["name"]))
        # sanitize accidental ';' in fields so the bulk format doesn't shift columns
        artista = artista.replace(";", ",")
        musica = musica.replace(";", ",")
        lines.append(f"{codigo};{ano};{artista};{musica}")

    out_path = Path(args.out)
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"\nWrote {len(lines)} lines to {out_path}")

    if missing:
        print(f"\nWARNING: {len(missing)} tracks had no match in the report (used Spotify metadata as fallback):")
        for codigo, uri, name in missing:
            print(f"  {codigo} [{uri}] {name}")

    print("\nFirst lines:")
    for l in lines[:5]:
        print(" ", l)
    print("  ...")
    for l in lines[-5:]:
        print(" ", l)


if __name__ == "__main__":
    main()
