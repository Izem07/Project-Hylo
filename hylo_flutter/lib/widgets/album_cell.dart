// AlbumCell — ported from Hylo/LibraryView.swift (AlbumCell struct)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/album.dart';
import '../services/navidrome_service.dart';

class AlbumCell extends StatelessWidget {
  final Album album;

  const AlbumCell({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final artUrl = NavidromeService().coverArtUrl(album.coverArt, size: 300);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: artUrl != null
              ? CachedNetworkImage(
                  imageUrl: artUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _placeholder(),
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        const SizedBox(height: 6),
        Text(
          album.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          album.artist ?? '',
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.08),
      child: const Icon(Icons.music_note, color: Color(0xFF888888), size: 36),
    );
  }
}
