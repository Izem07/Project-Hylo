# Hylo 🎵

A Navidrome music client built with Flutter. Stream your library, download tracks for offline listening, and control playback from the lock screen — all in a dark theme with gold accents.

## Features

- **Live Streaming** — connects directly to your Navidrome server
- **Albums & Playlists** — browse your full library with cover art
- **Offline Mode** — download any track, listen without a connection
- **Now Playing** — full-screen player with scrubber, skip, and like
- **Lock Screen Controls** — play/pause/skip from the notification shade and AirPods
- **iOS + Android + Web** — one codebase, runs everywhere

## Tech Stack

| | |
|---|---|
| Language | Dart |
| Framework | Flutter |
| Audio | just_audio |
| State | Provider |
| Storage | shared_preferences + path_provider |
| Images | cached_network_image |

## Running Locally

```bash
cd hylo_flutter
flutter pub get

# Live web preview (hot reload with r key)
flutter run -d chrome

# iOS (requires Mac + Xcode)
flutter run

# Android
flutter run -d android
```

## Building a Release IPA

Go to **Actions → iOS Build & Release → Run workflow**, enter a version tag (e.g. `v1.0.0`), and hit Run. GitHub Actions will build and attach the IPA to a GitHub Release automatically.

### Installing the unsigned IPA

- **[Sideloadly](https://sideloadly.io)** — drag the IPA in, sign with your Apple ID
- **[AltStore](https://altstore.io)** — open-source alternative

## Releases

**[github.com/Izem07/Project-Hylo/releases](https://github.com/Izem07/Project-Hylo/releases)**

## License

MIT — see [LICENSE](LICENSE)
