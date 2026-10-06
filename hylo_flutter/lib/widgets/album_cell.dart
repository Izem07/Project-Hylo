// AlbumCell — ported from Hylo/LibraryView.swift (AlbumCell struct)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/album.dart';
import '../services/navidrome_service.dart';

class AlbumCell extends StatefulWidget {
  final Album album;

  const AlbumCell({super.key, required this.album});

  @override
  State<AlbumCell> createState() => _AlbumCellState();
}

class _AlbumCellState extends State<AlbumCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final artUrl =
        NavidromeService().coverArtUrl(widget.album.coverArt, size: 300);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cover image
                artUrl != null
                    ? CachedNetworkImage(
                        imageUrl: artUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),

                // Gradient overlay (transparent → dark at bottom)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.55, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),

                // Text overlay at the bottom
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.album.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.album.artist ?? '',
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white.withValues(alpha: 0.08),
      child: const Icon(Icons.music_note, color: Color(0xFF888888), size: 36),
    );
  }
}
