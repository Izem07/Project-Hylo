# Hylo 🎵

Hylo is a beautiful, custom iOS Navidrome client built with SwiftUI. It features seamless live streaming, local caching for offline playback, and a dedicated offline listening mode designed around a sleek dark theme with golden-yellow accents.

## Features
- **Navidrome Integration**: Stream your entire music library directly from your personal Navidrome server.
- **Offline Mode**: Download tracks to your local device and listen completely disconnected from the internet.
- **Modern UI**: Dark mode-first design with glassmorphism effects, custom playback controls, and beautiful album art displays.
- **Favorites**: Like and unlike tracks (syncs directly with the Navidrome star system).

## Tech Stack
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Audio Playback**: AVFoundation
- **Project Generation**: [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Building the App

### Option 1: GitHub Actions (No Mac Required)
If you are on Windows or Linux, you can still compile this app using the included GitHub Actions workflow.
1. Push this repository to GitHub.
2. Go to the **Actions** tab in your GitHub repository.
3. The `iOS Build` workflow will automatically run on a macOS server, install XcodeGen, generate the project file, and compile the app for the iOS Simulator.

### Option 2: Building Locally (macOS)
Because this project uses `XcodeGen`, the `.xcodeproj` file is not tracked in version control to keep the repository clean.
1. Install XcodeGen using Homebrew:
   ```bash
   brew install xcodegen
   ```
2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```
3. Open `Hylo.xcodeproj` in Xcode and press **Run** (`Cmd + R`).

## License
MIT License

## Changelog

### Pass 1 — Feature completion
- **PlayerViewModel**: added `currentTime` and `duration` published properties; scrubber now tracks real elapsed/total time.
- **PlayerViewModel**: added `seek(to:)` for user-initiated scrubbing.
- **PlayerViewModel**: added `queue`, `queueIndex`, `skipForward()`, `skipBack()`; `play(song:queue:)` now accepts a queue; `nextTrackCommand` and `previousTrackCommand` wired to remote command center.
- **PlayerViewModel**: lock screen now shows live elapsed time and duration via `MPNowPlayingInfoPropertyElapsedPlaybackTime`.
- **NowPlayingView**: Slider is fully interactive (writes back via `seek(to:)`); time labels show real seconds; backward/forward buttons wired to `skipBack()`/`skipForward()`.
- **NowPlayingView**: album art replaced with `AsyncImage` showing real cover art from Navidrome; gradient shown as fallback.
- **LibraryView / SongRow**: `SongRow` now takes an optional `queue` parameter; `AlbumDetailView` and `PlaylistDetailView` pass the full songs array as queue so skip works across tracks.
- **OfflineManager**: downloads now write a `.json` sidecar beside each `.mp3`; `downloadedSongs: [Song]` rebuilt from sidecar files at init and after each download/delete; delete also removes the sidecar.
- **OfflineView**: offline track list now uses `SongRow` with real metadata from sidecar files, replacing the ID-only display.
- **NavidromeService**: added `testConnection(completion:)` using Subsonic `ping.view` with proper auth and error-code handling.
- **ConnectView**: connection test now delegates to `NavidromeService.shared.testConnection`; surfaces authentication errors distinctly.
- **project.yml**: `Info.plist` confirmed in sources excludes list (no change required).
