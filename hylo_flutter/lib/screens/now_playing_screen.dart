// NowPlayingScreen — ported from Hylo/NowPlayingView.swift
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/navidrome_service.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  static const _yellow = Color(0xFFF9CC1B);
  static const _bg = Color(0xFF0A0A0A);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final song = player.currentSong;
        final artUrl =
            NavidromeService().coverArtUrl(song?.coverArtId, size: 600);

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
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song?.artist ?? 'Unknown Artist',
                                style: const TextStyle(
                                  color: _yellow,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                song?.album ?? 'Unknown Album',
                                style: const TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Animated Like button
                        _AnimatedLikeButton(
                          isLiked: player.isLiked,
                          onTap: () => player.toggleLike(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // MARK: Scrubber (isolated subtree)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _ScrubberWidget(),
                  ),

                  const SizedBox(height: 8),

                  // MARK: Playback Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Repeat (stub)
                        Icon(
                          Icons.repeat,
                          color: const Color(0xFF888888).withValues(alpha: 0.6),
                          size: 22,
                        ),
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
                        Icon(
                          Icons.shuffle,
                          color: const Color(0xFF888888).withValues(alpha: 0.6),
                          size: 22,
                        ),
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
                            color: const Color(0xFF1A1A1A),
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
            Colors.black.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(Icons.music_note, color: Color(0xFF888888), size: 64),
      ),
    );
  }
}

// MARK: - Scrubber (isolated rebuild subtree)

class _ScrubberWidget extends StatefulWidget {
  const _ScrubberWidget();

  @override
  State<_ScrubberWidget> createState() => _ScrubberWidgetState();
}

class _ScrubberWidgetState extends State<_ScrubberWidget> {
  static const _yellow = Color(0xFFF9CC1B);
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _yellow,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: _yellow,
            overlayColor: _yellow.withValues(alpha: 0.2),
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: _dragging ? 6 : 0,
            ),
            trackHeight: 3,
          ),
          child: Slider(
            value: player.playbackProgress.clamp(0.0, 1.0),
            onChangeStart: (_) => setState(() => _dragging = true),
            onChangeEnd: (_) => setState(() => _dragging = false),
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
    );
  }

  static String _formatSeconds(double s) {
    if (!s.isFinite || s <= 0) return '0:00';
    final t = s.toInt();
    return '${t ~/ 60}:${(t % 60).toString().padLeft(2, '0')}';
  }
}

// MARK: - Animated like button

class _AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;

  const _AnimatedLikeButton({
    required this.isLiked,
    required this.onTap,
  });

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton> {
  double _scale = 1.0;

  static const _yellow = Color(0xFFF9CC1B);

  Future<void> _animate() async {
    setState(() => _scale = 1.3);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.isLiked ? 'Unlike' : 'Like',
      child: GestureDetector(
        onTap: () {
          _animate();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              widget.isLiked ? Icons.favorite : Icons.favorite_border,
              color: widget.isLiked ? _yellow : Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
