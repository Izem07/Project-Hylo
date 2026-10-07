import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/navidrome_service.dart';
import '../services/offline_manager.dart';

class SongRow extends StatelessWidget {
  final Song song;
  final List<Song> queue;

  const SongRow({super.key, required this.song, this.queue = const []});

  static const _yellow = Color(0xFFF9CC1B);

  @override
  Widget build(BuildContext context) {
    final artUrl = NavidromeService().coverArtUrl(song.coverArtId, size: 60);

    return Consumer2<PlayerProvider, OfflineManager>(
      builder: (context, player, offline, _) {
        final downloaded = offline.isDownloaded(song.id);
        final isCurrentAndPlaying =
            player.currentSong?.id == song.id && player.isPlaying;

        return GestureDetector(
          onTap: () => player.play(song, queue: queue.isEmpty ? [song] : queue),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: artUrl != null
                          ? CachedNetworkImage(
                              imageUrl: artUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _thumb(),
                              errorWidget: (_, __, ___) => _thumb(),
                            )
                          : _thumb(),
                    ),
                    const SizedBox(width: 12),

                    // Title + artist — Expanded so it never overflows
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              if (isCurrentAndPlaying) ...[
                                const _PlayingBars(),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  song.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            song.artist,
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Duration
                    Text(
                      song.duration,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 11,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),

                    // Download button
                    Semantics(
                      label: downloaded ? 'Downloaded' : 'Download',
                      child: IconButton(
                        icon: Icon(
                          downloaded
                              ? Icons.check_circle_outline
                              : Icons.arrow_circle_down_outlined,
                          color: downloaded ? _yellow : const Color(0xFF888888),
                          size: 20,
                        ),
                        onPressed:
                            downloaded ? null : () => offline.download(song),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ),

                    // Play button
                    Semantics(
                      label: 'Play ${song.title}',
                      child: IconButton(
                        icon: const Icon(Icons.play_circle_filled,
                            color: _yellow, size: 26),
                        onPressed: () => player.play(song,
                            queue: queue.isEmpty ? [song] : queue),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
            ],
          ),
        );
      },
    );
  }

  Widget _thumb() => Container(
        width: 50,
        height: 50,
        color: Colors.white.withValues(alpha: 0.08),
        child: const Icon(Icons.music_note, color: Color(0xFF888888), size: 18),
      );
}

// Animated playing bars indicator
class _PlayingBars extends StatefulWidget {
  const _PlayingBars();
  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars> {
  static const _frames = [
    [8.0, 14.0, 10.0],
    [14.0, 8.0, 14.0],
    [10.0, 14.0, 8.0],
  ];
  int _frame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (mounted) setState(() => _frame = (_frame + 1) % _frames.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heights = _frames[_frame];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
          3,
          (i) => Padding(
                padding: EdgeInsets.only(right: i < 2 ? 2.0 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 3,
                  height: heights[i],
                  color: const Color(0xFFF9CC1B),
                ),
              )),
    );
  }
}
