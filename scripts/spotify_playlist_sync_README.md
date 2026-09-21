# Spotify playlist sync

Adds every song from `assets/lista_corrigida_apenas_musicas.txt` into your
Spotify playlist "Beatspan".

## Setup (one time)

1. Create an app at https://developer.spotify.com/dashboard (any name/description).
2. In the app settings, add a Redirect URI: `http://127.0.0.1:8888/callback`
3. Set environment variables (PowerShell):

   ```powershell
   $env:SPOTIPY_CLIENT_ID = "your-client-id"
   $env:SPOTIPY_CLIENT_SECRET = "your-client-secret"
   $env:SPOTIPY_REDIRECT_URI = "http://127.0.0.1:8888/callback"
   ```

4. Install dependencies:

   ```powershell
   pip install -r scripts/spotify_requirements.txt
   ```

## Running

```powershell
python scripts/spotify_playlist_sync.py --dry-run   # just check what would happen
python scripts/spotify_playlist_sync.py             # actually add the tracks
```

The first run opens a browser to authorize your Spotify account; a cached
token is stored locally (`.cache`) so you won't need to log in again.

A CSV report is written to `scripts/spotify_sync_report.csv` listing every
song's match status (`confident_match`, `low_confidence_match`, `not_found`,
`already_in_playlist`) so you can manually review anything uncertain —
several titles in the list (e.g. "Casa de Deus", "Restitui", "Preciso de
Ti") are recorded by multiple artists, and older hymns credited to a hymnal
(e.g. "Harpa Cristã") may not exist on Spotify under that name at all.
