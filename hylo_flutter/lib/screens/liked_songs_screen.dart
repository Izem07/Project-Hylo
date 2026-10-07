import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/navidrome_service.dart';
import '../widgets/song_row.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  static const _yellow = Color(0xFFF9CC1B);

  @override
  void initState() {
    super.initState();
    NavidromeService().fetchLikedSongs().then((songs) {
      if (mounted) setState(() { _songs = songs; _isLoading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A1A00), Color(0xFF0A0A0A)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.favorite, color: _yellow, size: 48),
                        const SizedBox(height: 12),
                        const Text('Liked Songs',
                            style: TextStyle(color: Colors.white,
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          _isLoading ? 'Loading...' : '${_songs.length} tracks',
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Play All + Shuffle buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _yellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Play All',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _songs.isEmpty ? null : () {
                      player.play(_songs.first, queue: _songs);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.shuffle, color: _yellow),
                    onPressed: _songs.isEmpty ? null : () {
                      final shuffled = List<Song>.from(_songs)..shuffle(Random());
                      player.play(shuffled.first, queue: shuffled);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ]),
            ),
          ),

          // Track list
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: _yellow)),
            )
          else if (_songs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        color: Color(0xFF888888), size: 52),
                    SizedBox(height: 14),
                    Text('No liked songs yet',
                        style: TextStyle(color: Colors.white,
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Tap the heart on any track to add it here.',
                        style: TextStyle(
                            color: Color(0xFF888888), fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SongRow(song: _songs[i], queue: _songs),
                ),
                childCount: _songs.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
