// MiniPlayer — ported from Hylo/ContentView.swift (MiniPlayerView struct)
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../screens/now_playing_screen.dart';
import '../services/navidrome_service.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static const _yellow = Color(0xFFF9CC1B);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        if (player.currentSong == null) return const SizedBox.shrink();

        final song = player.currentSong!;
        final artUrl =
            NavidromeService().coverArtUrl(song.coverArtId, size: 80);
        final progress = player.playbackProgress.clamp(0.0, 1.0);

        return GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const NowPlayingScreen(),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: SizedBox(
                height: 64,
                child: Stack(
                  children: [
                    // Frosted glass background
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF111111),
                        border: Border(
                          top: BorderSide(color: Color(0x1AFFFFFF), width: 1),
                        ),
                      ),
                    ),
                    // Progress bar at top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 2,
                            width: constraints.maxWidth * progress,
                            color: _yellow,
                          );
                        },
                      ),
                    ),
                    // Content row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          // Cover art thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: artUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: artUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => _thumbPlaceholder(),
                                    errorWidget: (_, __, ___) =>
                                        _thumbPlaceholder(),
                                  )
                                : _thumbPlaceholder(),
                          ),
                          const SizedBox(width: 12),
                          // Title + artist
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  song.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song.artist,
                                  style: const TextStyle(
                                    color: _yellow,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Heart button
                          Semantics(
                            label: player.isLiked ? 'Unlike' : 'Like',
                            child: IconButton(
                              icon: Icon(
                                player.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: player.isLiked ? _yellow : Colors.white,
                              ),
                              onPressed: () => player.toggleLike(),
                            ),
                          ),
                          // Play/Pause button
                          Semantics(
                            label: player.isPlaying ? 'Pause' : 'Play',
                            child: IconButton(
                              icon: Icon(
                                player.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () => player.togglePlayPause(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF9CC1B).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 18),
    );
  }
}
