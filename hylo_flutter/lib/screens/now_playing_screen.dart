// NowPlayingScreen — ported from Hylo/NowPlayingView.swift
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/navidrome_service.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  static const _yellow = Color(0xFFF9CC1B);
  static const _bg = Color(0xFF141414);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final song = player.currentSong;
        final artUrl = NavidromeService()
            .coverArtUrl(song?.coverArtId, size: 600);

        return Container(
          color: _bg,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  // MARK: Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Dismiss chevron
                        Semantics(
                          label: 'Close Now Playing',
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Now Playing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_horiz,
                              color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // MARK: Album Art
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: artUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: artUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => _artPlaceholder(),
                                    errorWidget: (_, __, ___) =>
                                        _artPlaceholder(),
                                  )
                                : _artPlaceholder(),
                          ),
                        ),
                        // Show Lyrics badge overlay
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.format_quote,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Show Lyrics',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // MARK: Track Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song?.title ?? 'Unknown Title',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song?.artist ?? 'Unknown Artist',
                                style: const TextStyle(
                                  color: _yellow,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                song?.album ?? 'Unknown Album',
                                style: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Heart / Like button
                        Semantics(
                          label: player.isLiked ? 'Unlike' : 'Like',
                          child: IconButton(
                            icon: Icon(
                              player.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: player.isLiked ? _yellow : Colors.white,
                              size: 24,
                            ),
                            onPressed: () => player.toggleLike(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // MARK: Scrubber
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _yellow,
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.2),
                            thumbColor: _yellow,
                            overlayColor: _yellow.withValues(alpha: 0.2),
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: player.playbackProgress.clamp(0.0, 1.0),
                            onChanged: (v) => player.seek(v),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatSeconds(player.currentTime),
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 11,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              _formatSeconds(player.duration),
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 11,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // MARK: Playback Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Repeat (stub)
                        const Icon(Icons.repeat,
                            color: Color(0xFF888888), size: 22),
                        // Skip back
                        Semantics(
                          label: 'Previous track',
                          child: IconButton(
                            icon: const Icon(Icons.skip_previous,
                                color: Colors.white, size: 32),
                            onPressed: () => player.skipBack(),
                          ),
                        ),
                        // Play/Pause circle (72px yellow)
                        Semantics(
                          label: player.isPlaying ? 'Pause' : 'Play',
                          child: GestureDetector(
                            onTap: () => player.togglePlayPause(),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: _yellow,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                player.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.black,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        // Skip forward
                        Semantics(
                          label: 'Next track',
                          child: IconButton(
                            icon: const Icon(Icons.skip_next,
                                color: Colors.white, size: 32),
                            onPressed: () => player.skipForward(),
                          ),
                        ),
                        // Shuffle (stub)
                        const Icon(Icons.shuffle,
                            color: Color(0xFF888888), size: 22),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // MARK: Up Next row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Up Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.list,
                                  color: Color(0xFF888888), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${(player.queue.length - player.queueIndex - 1).clamp(0, 9999)} tracks',
                                style: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _artPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.3)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.music_note, color: Color(0xFF888888), size: 64),
      ),
    );
  }

  static String _formatSeconds(double s) {
    if (!s.isFinite || s <= 0) return '0:00';
    final t = s.toInt();
    return '${t ~/ 60}:${(t % 60).toString().padLeft(2, '0')}';
  }
}
