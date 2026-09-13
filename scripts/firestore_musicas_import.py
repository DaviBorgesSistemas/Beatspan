#!/usr/bin/env python3
"""
Popula a coleção `musicas` do Firestore a partir das faixas da playlist
Spotify "Beatspan", atribuindo códigos sequenciais 0001, 0002, ... na ordem
em que as faixas aparecem na playlist.

Usage:
    pip install -r scripts/spotify_requirements.txt
    set the SPOTIPY_CLIENT_ID / SPOTIPY_CLIENT_SECRET / SPOTIPY_REDIRECT_URI
    env vars (see scripts/spotify_playlist_sync_README.md), then:

    python scripts/firestore_musicas_import.py --service-account path/to/key.json --dry-run
    python scripts/firestore_musicas_import.py --service-account path/to/key.json
"""

import argparse
import sys

import spotipy
from spotipy.oauth2 import SpotifyOAuth

SCOPE = "playlist-read-private playlist-read-collaborative"


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
            if not track or not track.get("id"):
                continue
            tracks.append(track)
        if not page.get("next"):
            break
        offset += len(page["items"])
    return tracks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--playlist",
        default="Beatspan",
        help="Target playlist name, ID, URL, or spotify:playlist: URI",
    )
    parser.add_argument(
        "--service-account",
        required=True,
        help="Path to the Firebase Admin SDK service account JSON key",
    )
    parser.add_argument(
        "--collection",
        default="musicas",
        help="Firestore collection to write to",
    )
    parser.add_argument(
        "--start",
        type=int,
        default=1,
        help="First sequential code number (default: 1 -> '0001')",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only print what would be written, don't touch Firestore",
    )
    args = parser.parse_args()

    auth_manager = SpotifyOAuth(scope=SCOPE, open_browser=True)
    sp = spotipy.Spotify(auth_manager=auth_manager)

    playlist = find_playlist(sp, args.playlist)
    if not playlist:
        print(f"Playlist '{args.playlist}' not found in your account.", file=sys.stderr)
        sys.exit(1)

    tracks = get_playlist_tracks(sp, playlist["id"])
    print(f"Playlist '{playlist['name']}' has {len(tracks)} tracks")

    docs = []
    for i, track in enumerate(tracks, start=args.start):
        codigo = f"{i:04d}"
        artists = ", ".join(a["name"] for a in track["artists"])
        docs.append(
            {
                "codigo": codigo,
                "spotify_id": track["id"],
                "spotify_uri": track["uri"],
                "_label": f"{track['name']} ({artists})",
            }
        )

    print(f"\nWill write {len(docs)} documents to collection '{args.collection}':")
    for d in docs[:5]:
        print(f"  {d['codigo']} -> {d['_label']}  [{d['spotify_uri']}]")
    print("  ...")
    for d in docs[-5:]:
        print(f"  {d['codigo']} -> {d['_label']}  [{d['spotify_uri']}]")

    if args.dry_run:
        print("\nDry run: nothing was written to Firestore.")
        return

    import firebase_admin
    from firebase_admin import credentials, firestore

    cred = credentials.Certificate(args.service_account)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    batch = db.batch()
    batch_count = 0
    written = 0
    for d in docs:
        doc_ref = db.collection(args.collection).document(d["codigo"])
        batch.set(doc_ref, {"spotify_id": d["spotify_id"], "spotify_uri": d["spotify_uri"]})
        batch_count += 1
        written += 1
        if batch_count == 400:
            batch.commit()
            batch = db.batch()
            batch_count = 0
    if batch_count:
        batch.commit()

    print(f"\nWrote {written} documents to Firestore collection '{args.collection}'.")


if __name__ == "__main__":
    main()
