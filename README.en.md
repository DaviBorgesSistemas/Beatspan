# Beatspan

*[Leia em português](README.md)*

Beatspan is a Flutter app that companions a **Hitster**-style music card game: each physical card has a QR code pointing to `beatspangame.com/<code>`. Scanned inside the app, the code is resolved on Firestore (`musicas` collection) to the corresponding Spotify track and played; scanned by any other QR reader, it opens the download landing page hosted on Firebase Hosting (`hosting/`). Players try to guess the song, artist and year by placing the card on a timeline.

## Features

- **Splash screen** on first launch, with local persistence of preferences. App is Portuguese (pt-BR) only — no language/country selection.
- **QR code scanning** via camera (`mobile_scanner`), validating links from the `beatspangame.com` domain (and the Firebase Hosting domains used during development).
- **Track resolution via Firestore** — the code extracted from the URL is looked up in the `musicas` collection, which returns the track's `spotify_uri` (see `docs/2-SECURITY_REPORT.md` for the schema and security rules).
- **Track playback via Spotify** — Premium users play the full track through Spotify App Remote (`spotify_sdk`); Free plan users fetch the 30s preview via the Spotify Web API, with a fallback to the iTunes Search API.
- **Rules screen** with illustrations.
- **FAQ** loaded from a local JSON file (`assets/json/faq.json`), with a dedicated repository and use case.
- **Settings**: switch Spotify account, upgrade to Premium, contact, and app sharing.

## Tech stack

| Category | Package |
|---|---|
| Dependency injection | `get_it` |
| Result/Either | `dartz` |
| Local persistence | `shared_preferences` |
| Environment configuration | `--dart-define-from-file` (compile-time) |
| Backend / music catalog | `firebase_core`, `cloud_firestore` |
| Network / connectivity | `http`, `connectivity_plus` |
| Spotify integration | `spotify_sdk` (App Remote + Auth), Web API via `http` |
| QR code scanning | `mobile_scanner` |
| Audio (local preview) | `just_audio` |
| App splash / icon | `flutter_native_splash`, `flutter_launcher_icons` |

## Architecture

Simplified Clean Architecture, with `presentation/` organized by feature and generic `data/`/`domain/` layers:

```
lib/
├── app/            # App widget, AppPreferences (shared_preferences), DI setup (get_it)
├── data/
│   ├── data_source/    # e.g. FaqLocalDataSource (reads assets/json/faq.json)
│   ├── network/         # SpotifyService (App Remote), SpotifyWebApi (REST), MusicaFirestoreDataSource, ItunesSearchApi, NetworkInfo
│   └── repository/      # repository implementations (FaqRepositoryImpl, MusicaRepositoryImpl)
├── domain/
│   ├── enum/            # FlowState, PlanType, TurnPhoneMode, GameModeType
│   ├── exception/        # domain exceptions (e.g. MusicaNaoEncontradaException)
│   ├── model/            # domain models (e.g. Faqs, Musica)
│   ├── repository/       # abstract contracts (FaqRepository, MusicaRepository)
│   └── usecase/          # use cases (e.g. FaqsUsecase, GetMusicaUseCase)
└── presentation/
    ├── splash, home, game, rules, settings, faqs, contact,
    │   change_spotify, connect_spotify_premium, share
    └── resource/         # color, font, style, theme, screen and asset managers
```

> Note: the FAQ and music-lookup-by-code (Firestore) features implement the full stack (repository + usecase + datasource). The Spotify/iTunes playback flow inside `GameView` still talks directly to `SpotifyService`/`SpotifyWebApi`/`ItunesSearchApi`, without a repository/usecase — see `docs/1-ARCHITECTURAL_REVIEW.md`, finding `ARQ-001`.

## Main game flow

1. From `HomeView`, the player taps "Start a game".
2. `GameView` opens the camera to scan the card's QR code.
3. The app validates that the scanned URL belongs to the `beatspangame.com` domain and extracts the short code (e.g. `0006`).
4. The code is looked up in the `musicas` Firestore collection, which returns the track's `spotify_uri`.
5. Based on the saved plan (`PlanType`):
   - **Premium**: connects to Spotify App Remote and plays the full track.
   - **Free**: fetches the 30s preview URL via the Spotify Web API, with a fallback to the iTunes Search API if the preview is unavailable.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.9.2`
- A developer account on [Spotify for Developers](https://developer.spotify.com/) to obtain a `Client ID` and `Redirect URI`
- Spotify app installed on the test device (required for App Remote)
- A [Firebase Console](https://console.firebase.google.com/) project with Firestore and Hosting enabled
- Android Studio / Xcode configured to run on an emulator or physical device

## Spotify setup

The app needs Spotify credentials (Client ID and Redirect URI) to authenticate and play tracks.

- Copy `env.json.example` to `env.json` and fill in `SPOTIFY_CLIENT_ID` and `SPOTIFY_REDIRECT_URL` with your credentials. The app reads these at compile time via `String.fromEnvironment` in [lib/app/di.dart](lib/app/di.dart) — without them defined, the app throws a clear error on launch. Run/build passing the file: `flutter run --dart-define-from-file=env.json` (already wired into the VS Code configurations in `.vscode/launch.json`). `env.json` is gitignored and must never be committed or packaged as an asset — unlike the previous `.env` approach, `--dart-define` values are not shipped as an extractable file inside the APK/IPA.

## Firebase setup

The app uses Firestore to resolve the QR code's short code into a Spotify track (`musicas` collection) and Firebase Hosting for the landing page served to anyone who scans the card outside the app.

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

This generates `lib/firebase_options.dart` and the native config files. See `firestore.rules` for the already-versioned security rules.

## Getting started

```bash
# install dependencies
flutter pub get

# run on a connected device/emulator
flutter run
```

### Generate app icon and splash screen

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Commit convention

The project follows [Conventional Commits](https://www.conventionalcommits.org/): `<type>: <description>`, with types `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `security`, `style`, `perf`. Generic messages (`...`, `..`, bare screen names) should no longer be used — commits predating this convention were not rewritten (see `docs/1-ARCHITECTURAL_REVIEW.md`, finding `DOC-004`).

Example: `fix: correctly validates track links without a locale prefix`.

## Documentation

The [docs/](docs/) folder contains a full architectural analysis (fundamentals, security, experience, operations, documentation, performance):

- [1-ARCHITECTURAL_REVIEW.md](docs/1-ARCHITECTURAL_REVIEW.md) — full technical report, all findings with an ID (Portuguese)
- [2-SECURITY_REPORT.md](docs/2-SECURITY_REPORT.md) — security findings, LGPD/GDPR checklist, supply chain status (Portuguese)
- [3-TECH_DEBT_REGISTER.md](docs/3-TECH_DEBT_REGISTER.md) — prioritized technical debt catalog (Portuguese)
- [4-ACTION_PLAN.md](docs/4-ACTION_PLAN.md) — action plan by timeframe, with a progress checklist (Portuguese)
- [5-IMPROVEMENT_ROADMAP.md](docs/5-IMPROVEMENT_ROADMAP.md) — improvement roadmap by phase (Portuguese)

## Project status

Actively under development, pre-launch (not yet published on app stores). Known open points:

- Rounds, scoring and the timeline are managed by the players themselves with the physical cards (the year is printed on the card) — by design, the app only covers the scan-and-play flow and doesn't need to model that digitally.
- No multiplayer or state sync across devices.
- Test coverage still early-stage (see `test/`) — `GameView`/players still need coverage.
- iOS build not configured — only Android is functional today.

See [docs/1-ARCHITECTURAL_REVIEW.md](docs/1-ARCHITECTURAL_REVIEW.md) for the full technical breakdown and [docs/4-ACTION_PLAN.md](docs/4-ACTION_PLAN.md) for the prioritized fix plan, with a progress checklist.
