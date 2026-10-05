# Hylo 🎵

Hylo is a beautiful, custom iOS Navidrome client built with SwiftUI. It features seamless live streaming, local caching for offline playback, and a dedicated offline listening mode — all wrapped in a sleek dark theme with golden-yellow accents.

## Features

- **Navidrome Integration** — Stream your entire music library directly from your personal Navidrome server
- **Offline Mode** — Download tracks to your device and listen completely disconnected
- **Modern UI** — Dark mode-first design with glassmorphism effects, custom playback controls, and beautiful album art
- **Favorites** — Like and unlike tracks, synced with the Navidrome star system

## Tech Stack

| | |
|---|---|
| Language | Swift |
| UI Framework | SwiftUI |
| Audio Playback | AVFoundation |
| Project Generation | [XcodeGen](https://github.com/yonaskolb/XcodeGen) |

---

## Building the App

### Option 1: GitHub Actions (No Mac Required)

The easiest way to get a build if you're on Windows or Linux.

1. Push this repository to GitHub (or fork it)
2. Go to the **Actions** tab
3. The `Build IPA` workflow runs automatically on every push to `main`
4. When it finishes, download **Hylo-IPA** from the workflow's **Artifacts** section

### Option 2: Building Locally (macOS)

The `.xcodeproj` is not tracked in version control — XcodeGen generates it on demand.

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```
2. Generate the Xcode project:
   ```bash
   cd Hylo
   xcodegen generate
   ```
3. Open `Hylo.xcodeproj` in Xcode and press **Run** (`⌘R`)

---

## Releases

Tagged releases are built and published automatically via GitHub Actions.

To create a new release, push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `iOS Release` workflow will build the app, package it as an IPA, and attach it to a new GitHub Release. You can find all releases at:

**[github.com/Izem07/Project-Hylo/releases](https://github.com/Izem07/Project-Hylo/releases)**

### Installing the IPA

The IPA shipped in releases is **unsigned**. To sideload it onto your iPhone:

- **[Sideloadly](https://sideloadly.io)** — drag the IPA in, sign with your Apple ID
- **[AltStore](https://altstore.io)** — open-source alternative, same idea
- **Xcode** — drag `Hylo.app` onto a connected device in the Devices window

> A paid Apple Developer account is required to install without the 7-day re-signing limit.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
