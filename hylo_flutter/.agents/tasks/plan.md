# Implementation Plan — Hylo Flutter UI Redesign

## Available packages (pubspec.yaml — do not add new ones)
- `provider` ^6.1.2
- `just_audio` ^0.9.40
- `audio_session` ^0.1.21
- `cached_network_image` ^3.3.1
- `shared_preferences` ^2.2.3
- `connectivity_plus` ^6.0.3
- `crypto` ^3.0.3
- `path_provider` ^2.1.3
- `http` ^1.2.1
- `uuid` ^4.4.0

## Design decisions

**Color palette** — keep the existing brand colors (`#F9CC1B` yellow, `#141414` near-black background, `#1E1E1E` surface). All new surfaces use these so no theme changes are needed in `main.dart`.

**No phone-frame/container wrapper** — the old session had a phantom iOS device frame. All screens must fill the full Flutter surface with no outer container decoration.

**Navigation** — stay with the existing `BottomNavigationBar` in `_RootShell`. The three tabs (Library, Offline, Settings) are the right shape. No new routing mechanism needed.

**NowPlaying** — remains a modal bottom sheet (already the pattern). The redesign makes it full-height and polished rather than changing how it's invoked.

**Scrubber smoothness** — `PlayerProvider` already streams position every tick via `just_audio`. The fix is UI-side: use `StreamBuilder` on `_player.positionStream` directly in `NowPlayingScreen` rather than going through `notifyListeners` (which triggers a full widget rebuild and causes jank). `PlayerProvider` exposes the raw streams as public getters.

**Shuffle / Repeat** — wire the stub icons in `NowPlayingScreen` to real `shuffle` and `repeatMode` state in `PlayerProvider`.

**ConnectScreen "Confirm" disabled guard** — already coded correctly (`onPressed` is `null` unless all three fields are non-empty). No logic change needed, only cosmetic polish.

---

## Step-by-step plan

- [ ] 1. **Expose audio streams and add shuffle/repeat state in `PlayerProvider`**

  Add three public getters that expose the underlying `just_audio` streams so the Now Playing screen can subscribe directly without causing full-tree rebuilds:
  ```
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  ```
  Add `bool _shuffle = false` and `LoopMode _repeatMode = LoopMode.off` fields with their getters and a `toggleShuffle()` / `cycleRepeat()` method that call `_player.setShuffleModeEnabled()` / `_player.setLoopMode()` then `notifyListeners()`.

  Files: `lib/providers/player_provider.dart`

  Verify: `flutter analyze lib/providers/player_provider.dart` — zero errors.

---

- [ ] 2. **Create `lib/widgets/app_theme.dart` — shared constants**

  Create a single file that exports the color constants and text style helpers so every screen sources them from one place instead of repeating hex literals:
  ```dart
  const kBgColor       = Color(0xFF141414);
  const kSurfaceColor  = Color(0xFF1E1E1E);
  const kYellow        = Color(0xFFF9CC1B);
  const kMuted         = Color(0xFF888888);
  const kDivider       = Color(0xFF252525);
  ```
  Also export a `kHeadingStyle`, `kSubtitleStyle`, `kCaptionStyle` `TextStyle` const.

  Files: `lib/widgets/app_theme.dart` *(new file)*

  Verify: `flutter analyze lib/widgets/app_theme.dart` — zero errors.

---

- [ ] 3. **Redesign `lib/widgets/album_cell.dart`**

  Current: plain `Column` with a flat placeholder.
  Changes:
  - Square art fills the cell width (swap `height: 160` fixed for `AspectRatio(aspectRatio: 1)`).
  - Rounded corners increase from `10` to `12`.
  - Placeholder gets a subtle gradient (two `kSurfaceColor` shades) instead of flat opacity.
  - Title font bumps from 13 to 14; artist sub-label stays 12 but uses `kMuted` from `app_theme.dart`.
  - Import `app_theme.dart`; remove inline hex literals.

  Files: `lib/widgets/album_cell.dart`

  Verify: `flutter analyze lib/widgets/album_cell.dart` — zero errors.

---

- [ ] 4. **Redesign `lib/widgets/capsule_pill.dart`**

  Current: white 10% opacity background, no border.
  Changes:
  - Add a `1px` border using `kYellow.withValues(alpha: 0.35)`.
  - Background becomes `kYellow.withValues(alpha: 0.08)`.
  - Text color becomes `kYellow` instead of white.
  - Font size stays 12, weight stays w500.

  Files: `lib/widgets/capsule_pill.dart`

  Verify: `flutter analyze lib/widgets/capsule_pill.dart` — zero errors.

---

- [ ] 5. **Redesign `lib/widgets/song_row.dart`**

  Current: bare Row with a flat thumbnail, two icon buttons, duration text.
  Changes:
  - Wrap the entire row in a `Material` + `InkWell` (replaces the bare `Container`) so the tap target covers the title/artist area and plays the track — matching the user's expectation that tapping a row plays it.
  - Thumbnail stays 44×44 with `radius: 8` (up from 6).
  - Title font stays 13 w600; artist stays 12.
  - Remove the explicit play `IconButton` at the end — the whole row is now tappable.
  - Keep the download `IconButton` on the right.
  - Add a "currently playing" indicator: if `player.currentSong?.id == song.id`, show a small animated bar icon (use `Icons.equalizer`) in `kYellow` before the title column instead of the thumbnail border.
  - Import `app_theme.dart`; remove inline hex literals.

  Files: `lib/widgets/song_row.dart`

  Verify: `flutter analyze lib/widgets/song_row.dart` — zero errors.

---

- [ ] 6. **Redesign `lib/widgets/mini_player.dart`**

  Current: a bordered container with cover art, title/artist, heart icon, play/pause icon.
  Changes:
  - Add a thin progress bar (`LinearProgressIndicator`) across the very top of the mini player (height 2px, `kYellow` value, no track), using `player.playbackProgress`.
  - Make the play/pause button a filled circle (40px, `kYellow` background, black icon) instead of a flat icon.
  - Increase thumbnail radius to 8.
  - Add a "skip forward" `IconButton` (`Icons.skip_next`, white, size 22) after the play/pause button.
  - Remove the heart button from the mini player (it's redundant with NowPlaying).
  - Import `app_theme.dart`; remove inline hex literals.

  Files: `lib/widgets/mini_player.dart`

  Verify: `flutter analyze lib/widgets/mini_player.dart` — zero errors.

---

- [ ] 7. **Redesign `lib/screens/now_playing_screen.dart`**

  This is the most substantial change. Goals: smooth scrubber, wired shuffle/repeat, full polish.

  Changes:
  - **Scrubber smoothness**: Replace the `Consumer<PlayerProvider>` slider with a `StreamBuilder` on `player.positionStream` and `player.durationStream` so position updates drive only the slider subtree. Wrap the full screen in `Consumer` for play state, but use a nested `StreamBuilder` for the position/duration display to avoid rebuilding the whole screen on every tick.
  - **Shuffle button**: wire `onTap` to `player.toggleShuffle()`. Icon color = `kYellow` when `player.shuffle` is true, else `kMuted`.
  - **Repeat button**: wire `onTap` to `player.cycleRepeat()`. Show `Icons.repeat_one` when `player.repeatMode == LoopMode.one`, `Icons.repeat` in `kYellow` when `LoopMode.all`, `Icons.repeat` in `kMuted` when off.
  - **Album art**: increase corner radius to 20. Add a `BoxShadow` (black, blur 40, opacity 0.5) behind the art for depth.
  - **Track info section**: title font size → 22 bold; artist font size → 16 `kYellow` w600; album label stays 14 `kMuted`.
  - **Time labels**: remain 11px, use `FontFeature.tabularFigures()` (already there — keep).
  - **"Show Lyrics" badge**: keep the overlay but style it with a `BackdropFilter` blur (use `dart:ui`'s `ImageFilter.blur`) for a frosted-glass look.
  - **"Up Next" row**: keep as-is, already looks clean.
  - **Remove** the `const _bg` and `const _yellow` inline constants — import from `app_theme.dart`.
  - Import `app_theme.dart` and `dart:ui`.

  Files: `lib/screens/now_playing_screen.dart`

  Verify: `flutter analyze lib/screens/now_playing_screen.dart` — zero errors.

---

- [ ] 8. **Redesign `lib/screens/library_screen.dart`**

  Changes across all four inner classes (`_LibraryScreenState`, `_PlaylistRow`, `AlbumDetailScreen`, `PlaylistDetailScreen`):

  **LibraryScreen header**:
  - Title "Library" → 32px (up from 28).
  - Connection dot + label stays; refactor to import `kMuted` from `app_theme.dart`.
  - Add a search `IconButton` in the top-right corner (navigates to a `showSearch`-based modal — use Flutter's built-in `SearchDelegate`). The search filters the currently visible list (`_albums` or `_playlists`) client-side by name.

  **Segment picker (`_tabButton`)**:
  - Selected tab: background `kYellow`, text `Colors.black` (unchanged).
  - Unselected: background `kSurfaceColor` (swap from `withValues(alpha:0.1)` to explicit `kSurfaceColor`), text white.
  - Border radius stays 10.

  **Album grid**:
  - `crossAxisCount` → 2 (unchanged).
  - `childAspectRatio` → `0.82` (slightly taller cards to accommodate the new square `AspectRatio(1)` art from step 3 plus two lines of text).
  - Spacing stays 16.

  **`_PlaylistRow`**:
  - Thumbnail size → 56×56 (up from 52).
  - Title font → 14 (up from 13).
  - Song count sub-label uses `kMuted`.
  - Chevron stays.

  **`AlbumDetailScreen`**:
  - Art thumbnail in header → 96×96 (up from 80).
  - Track count sub-label replaced with `${_songs.length} tracks · ${widget.album.artist ?? ''}` on one line.
  - Add a "Play All" button (`ElevatedButton` with `kYellow` background) below the header row that calls `player.play(_songs.first, queue: _songs)` — requires a `Consumer<PlayerProvider>` wrapper around the button.

  **`PlaylistDetailScreen`**:
  - Same "Play All" button as album detail.

  Remove all inline `_yellow` / hex constant declarations; import from `app_theme.dart`.

  Files: `lib/screens/library_screen.dart`

  Verify: `flutter analyze lib/screens/library_screen.dart` — zero errors.

---

- [ ] 9. **Redesign `lib/screens/offline_screen.dart`**

  Changes:
  - **Status banner**: replace the generic `Icons.wifi` / `Icons.bolt` with `Icons.cloud_done` (online) / `Icons.cloud_off` (offline). Card background → `kSurfaceColor` (instead of `withValues(alpha:0.05)`).
  - **Count badge**: merge into the status banner as a second row inside the same card — saves vertical space.
  - **Empty state**: replace `Icons.music_off` with `Icons.download_for_offline_outlined` (larger, 56px). Headline "No offline tracks yet" stays. Body text stays.
  - **Dismissible delete**: add a `BorderRadius.circular(8)` clip on the row so the red background is rounded.
  - Remove inline hex literals; import `app_theme.dart`.

  Files: `lib/screens/offline_screen.dart`

  Verify: `flutter analyze lib/screens/offline_screen.dart` — zero errors.

---

- [ ] 10. **Redesign `lib/screens/connect_screen.dart`**

  Changes:
  - **Branding header**: "Hylo" title stays 36px bold. Subtitle line → 20px w600 (up from 18). Description text → 14px `kMuted` (unchanged). Background shifts from `Colors.black` to `kBgColor` (they are different: black is `#000000`, kBgColor is `#141414`).
  - **CapsulePill pills**: now styled per step 4 (yellow tint, border).
  - **Form card**: increase `borderRadius` from 20 to 24. Background `Colors.white.withValues(alpha:0.04)` → `kSurfaceColor` (`#1E1E1E`).
  - **Text fields**: increase border radius from 12 to 14. Fill color stays `Colors.white.withValues(alpha:0.08)`.
  - **"Allow Insecure HTTP" toggle card**: border radius 12 → 14. Background matches text fields.
  - **Result banner**: success color stays `Colors.green`; failure stays `Colors.red`. No logic change.
  - **Connect button**: stays `kYellow` background. Already disabled when fields are empty — no logic change. Label text "Connect to Server" stays. Padding stays.
  - Remove `static const _yellow`; import from `app_theme.dart`.

  Files: `lib/screens/connect_screen.dart`

  Verify: `flutter analyze lib/screens/connect_screen.dart` — zero errors.

---

- [ ] 11. **Update `lib/main.dart` — theme tokens and no-connection banner polish**

  Changes:
  - In `ThemeData`, update `colorScheme.surface` to `kSurfaceColor` from `app_theme.dart` (already `0xFF1E1E1E` — verify it matches exactly).
  - The "No connection" banner: increase `vertical` padding from 6 to 8. Banner color stays `kYellow`.
  - Import `app_theme.dart` and replace the one inline `Color(0xFF141414)` scaffold background reference with `kBgColor`.
  - No structural changes to `_RootShell` — `IndexedStack`, `BottomNavigationBar`, and `MiniPlayer` layout are all correct and should not change.

  Files: `lib/main.dart`

  Verify: `flutter analyze lib/` — zero errors across all files.

---

- [ ] 12. **Full build verification**

  Run the full build to confirm no analysis errors or compile failures have been introduced by the redesign across all files.

  Verify:
  ```
  flutter analyze
  flutter build apk --debug
  ```
  Expected: `flutter analyze` exits with "No issues found." `flutter build apk --debug` completes without error.

---

## File change summary

| File | Status |
|---|---|
| `lib/widgets/app_theme.dart` | **New** |
| `lib/providers/player_provider.dart` | Modified |
| `lib/widgets/album_cell.dart` | Modified |
| `lib/widgets/capsule_pill.dart` | Modified |
| `lib/widgets/song_row.dart` | Modified |
| `lib/widgets/mini_player.dart` | Modified |
| `lib/screens/now_playing_screen.dart` | Modified |
| `lib/screens/library_screen.dart` | Modified |
| `lib/screens/offline_screen.dart` | Modified |
| `lib/screens/connect_screen.dart` | Modified |
| `lib/main.dart` | Modified |

No new packages required. No files deleted.
