// SongRow — ported from Hylo/LibraryView.swift (SongRow struct)
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

  const SongRow({
    super.key,
    required this.song,
    this.queue = const [],
  });

  static const _yellow = Color(0xFFF9CC1B);

  @override
  Widget build(BuildContext context) {
    final navidrome = NavidromeService();
    final artUrl = navidrome.coverArtUrl(song.coverArtId, size: 60);

    return Consumer2<PlayerProvider, OfflineManager>(
      builder: (context, player, offline, _) {
        final downloaded = offline.isDownloaded(song.id);
        return Container(
          color: const Color(0xFF141414),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: artUrl != null
                    ? CachedNetworkImage(
                        imageUrl: artUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _thumb(),
                        errorWidget: (_, __, ___) => _thumb(),
                      )
                    : _thumb(),
              ),
              const SizedBox(width: 12),
              // Title + artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Duration
              Text(
                song.duration,
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              // Download button
              Semantics(
                label: downloaded ? 'Downloaded' : 'Download',
                child: IconButton(
                  icon: Icon(
                    downloaded ? Icons.check_circle : Icons.download_outlined,
                    color: downloaded ? _yellow : const Color(0xFF888888),
                    size: 20,
                  ),
                  onPressed: downloaded ? null : () => offline.download(song),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
              // Play button
              Semantics(
                label: 'Play ${song.title}',
                child: IconButton(
                  icon: const Icon(
                    Icons.play_arrow,
                    color: _yellow,
                    size: 20,
                  ),
                  onPressed: () => player.play(
                    song,
                    queue: queue.isEmpty ? [song] : queue,
                  ),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _thumb() {
    return Container(
      width: 44,
      height: 44,
      color: Colors.white.withValues(alpha: 0.08),
      child: const Icon(Icons.music_note, color: Color(0xFF888888), size: 18),
    );
  }
}
