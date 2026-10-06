// MiniPlayer — ported from Hylo/ContentView.swift (MiniPlayerView struct)
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

        return GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const NowPlayingScreen(),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withValues(alpha: 0.97),
              border: const Border(
                top: BorderSide(color: Color(0x1AFFFFFF), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Cover art thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: artUrl != null
                      ? CachedNetworkImage(
                          imageUrl: artUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _thumbPlaceholder(),
                          errorWidget: (_, __, ___) => _thumbPlaceholder(),
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
                      player.isLiked ? Icons.favorite : Icons.favorite_border,
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
                      player.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => player.togglePlayPause(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF9CC1B).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 18),
    );
  }
}
