# Hylo Flutter

Flutter port of the Hylo iOS Navidrome client. Full feature parity with the original SwiftUI app.

## How to run

### Web (for testing — iPhone XS dimensions)
```sh
cd hylo_flutter
flutter run -d chrome
```
The `web/index.html` centres a 375×812 phone frame in the browser when the viewport is wider than 420px, matching the iPhone XS screen size for testing.

### iOS simulator / device
```sh
flutter run
```

### Android
```sh
flutter run -d android
```

## What was ported

| Swift source | Dart equivalent |
|---|---|
| `Song.swift` | `lib/models/song.dart` |
| `Models.swift` | `lib/models/album.dart`, `lib/models/playlist.dart`, `lib/models/api_models.dart` |
| `NavidromeService.swift` | `lib/services/navidrome_service.dart` |
| `OfflineManager.swift` | `lib/services/offline_manager.dart` |
| `PlayerViewModel.swift` | `lib/providers/player_provider.dart` |
| `NetworkMonitor.swift` | `lib/services/network_monitor.dart` |
| `ContentView.swift` + `MiniPlayerView` | `lib/main.dart` + `lib/widgets/mini_player.dart` |
| `LibraryView.swift` | `lib/screens/library_screen.dart` |
| `NowPlayingView.swift` | `lib/screens/now_playing_screen.dart` |
| `OfflineView.swift` | `lib/screens/offline_screen.dart` |
| `ConnectView.swift` | `lib/screens/connect_screen.dart` |
| `CapsulePill` | `lib/widgets/capsule_pill.dart` |
| `AlbumCell` | `lib/widgets/album_cell.dart` |
| `SongRow` | `lib/widgets/song_row.dart` |

## Key library replacements

| iOS / Swift | Flutter / Dart |
|---|---|
| `AVPlayer` | `just_audio` |
| `NWPathMonitor` | `connectivity_plus` |
| `URLSession` | `http` |
| `UserDefaults` | `shared_preferences` |
| `FileManager` / `DocumentDirectory` | `path_provider` |
| `CryptoKit MD5` | `crypto` package |
| `UUID` | `uuid` package |
| `AsyncImage` | `cached_network_image` |
| `MPRemoteCommandCenter` | `audio_session` (session config; lock-screen commands require `audio_service` if needed later) |

## Known limitations

- **Lock-screen / notification controls** on iOS and Android are not wired up. The `just_audio` package handles playback but background notification controls need the `audio_service` package. Add it to `pubspec.yaml` and wrap `PlayerProvider` in an `AudioHandler` to enable this.
- **Web audio**: streaming works on Chrome via `just_audio_web`, but local file playback (offline cached tracks) is not available on web because browsers do not expose a filesystem.
- **Lyrics**: the "Show Lyrics" badge is a stub. The Navidrome `/rest/getLyrics.view` endpoint can be wired in later.
- **Repeat / Shuffle**: buttons are rendered but are stubs — the queue logic plays straight through.
- **Search**: `NavidromeService.search()` is implemented but no search UI screen was in scope. Wire a search bar to `navidrome.search(query)` to surface it.
