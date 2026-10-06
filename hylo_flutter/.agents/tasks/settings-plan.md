# Implementation Plan — Expanded Settings

## Context

- **Worktree:** `c:\Users\lionp\OneDrive\Documents\Workspace\Project-Hylo\hylo_flutter`
- **Branch:** `main`
- **Build command:** `flutter analyze lib` (no separate compile step)
- **Test command:** `flutter analyze lib` (no unit tests in project; verification is analyze + manual)

Key observations from the codebase:

1. `NavidromeService` and `OfflineManager` are singletons initialised before `runApp` and registered as `ChangeNotifierProvider.value` in `MultiProvider`.
2. `main.dart` uses a `const ColorScheme.dark(primary: Color(0xFFF9CC1B))` — accent color is hardcoded; needs to become dynamic via `SettingsProvider`.
3. `connect_screen.dart` holds a `static const _yellow` — must be replaced with theme lookup after accent wiring.
4. `library_screen.dart` has `crossAxisCount: 2` hardcoded in `_albumGrid()`.
5. `navidrome_service.dart` `streamUrl()` builds the URL without a bitrate param — needs `maxBitRate` injected from `SettingsProvider`.
6. No packages to add — `shared_preferences` is already listed in `pubspec.yaml`.

---

## Plan

- [ ] 1. Create `lib/providers/settings_provider.dart` — the `SettingsProvider` ChangeNotifier.
      Implements all seven preferences (accentColor, streamQuality, skipSilence, crossfadeDuration, downloadOnWifiOnly, albumGridColumns, showAlbumArtistInRow) backed by SharedPreferences keys prefixed `hylo_settings_`. Provide an `init()` async method that loads all values from prefs. Follow the exact same singleton + factory pattern as `NavidromeService`.
      Files: `lib/providers/settings_provider.dart`
      Verify: `flutter analyze lib` — no errors.

- [ ] 2. Register `SettingsProvider` in `main.dart`.
      Instantiate `SettingsProvider()`, call `await settings.init()` in `main()` alongside `navidrome.init()` and `offline.init()`. Add `ChangeNotifierProvider<SettingsProvider>.value(value: settings)` to the `MultiProvider` list. Wrap `HyloApp`'s `build` in a `Consumer<SettingsProvider>` so the theme rebuilds on accent change. Wire `accentColor` into `ColorScheme.dark(primary:)`, `BottomNavigationBarThemeData(selectedItemColor:)`, and `SliderThemeData(activeTrackColor:, thumbColor:)`.
      Files: `lib/main.dart`
      Verify: `flutter analyze lib` — no errors; app still launches.

- [ ] 3. Wire `streamQuality` to `NavidromeService.streamUrl()`.
      In `streamUrl(songId)`, read `SettingsProvider().streamQuality` and append `&maxBitRate=X` (320 / 192 / 128). Access via the singleton `SettingsProvider()`. No other methods change.
      Files: `lib/services/navidrome_service.dart`
      Verify: `flutter analyze lib` — no errors.

- [ ] 4. Wire `albumGridColumns` to `LibraryScreen._albumGrid()`.
      Replace `crossAxisCount: 2` with `context.watch<SettingsProvider>().albumGridColumns`. Import `SettingsProvider`.
      Files: `lib/screens/library_screen.dart`
      Verify: `flutter analyze lib` — no errors.

- [ ] 5. Redesign `connect_screen.dart` into the full Settings screen.
      Replace the existing branding/hero layout with a `SingleChildScrollView` of sectioned cards. Keep every line of the existing connect logic (fields, toggle, button enabled check, `_testConnection`, `_ConnectionResult` sealed class). Add four new sections after the Server Connection card:

      **Playback section:**
      - Stream Quality: `SegmentedButton<String>` with segments High/Medium/Low, reads/writes `SettingsProvider.streamQuality`.
      - Skip Silence: Switch, reads/writes `SettingsProvider.skipSilence`.
      - Crossfade: `Slider` 0.0–10.0, divisions: 10, label shows `'${v}s'` or `'Off'` when 0, reads/writes `SettingsProvider.crossfadeDuration`.

      **Downloads section:**
      - Download on Wi-Fi Only: Switch, reads/writes `SettingsProvider.downloadOnWifiOnly`.
      - Storage Used: read-only row `context.watch<OfflineManager>().downloadedSongs.length` + `' files cached'`.
      - Clear All Downloads: `TextButton` with red text, shows `showDialog` confirm before iterating `offlineManager.downloadedSongs` and calling `deleteDownload` on each id.

      **Appearance section:**
      - Accent Color: `Row` of 5 `GestureDetector`-wrapped color circles (40×40, `BoxShape.circle`). Colors: yellow 0xFFF9CC1B, blue 0xFF3B82F6, purple 0xFF8B5CF6, green 0xFF10B981, red 0xFFEF4444. Selected circle has a white border ring. Tapping writes `SettingsProvider.accentColor`.
      - Album Grid: `SegmentedButton<int>` with '2 Columns' / '3 Columns', reads/writes `SettingsProvider.albumGridColumns`.
      - Show Artist in Track Rows: Switch, reads/writes `SettingsProvider.showAlbumArtistInRow`.

      **About section:**
      - App version row: `'Hylo v1.0.0'`
      - Subtitle: `'Your music server, built for the drive.'`

      Replace `static const _yellow` usages with `Theme.of(context).colorScheme.primary` so the accent applies. Use `context.watch<SettingsProvider>()` for reads and `context.read<SettingsProvider>()` for writes.
      Files: `lib/screens/connect_screen.dart`
      Verify: `flutter analyze lib` — no errors.

- [ ] 6. Run final analysis and commit.
      Run `flutter analyze lib` — must return "No issues found." Fix any remaining issues before committing. Commit all changed files with message `feat: expanded settings with playback, appearance, and download options`.
      Files: all modified files above
      Verify: `flutter analyze lib` returns exit code 0 with no issues; `git log --oneline -1` shows the commit.
