// OfflineScreen — ported from Hylo/OfflineView.swift
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_monitor.dart';
import '../services/offline_manager.dart';
import '../widgets/song_row.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  static const _yellow = Color(0xFFF9CC1B);

  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkMonitor, OfflineManager>(
      builder: (context, monitor, offline, _) {
        final songs = offline.downloadedSongs;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: const Text(
                    'Offline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Status banner
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          monitor.isConnected ? Icons.wifi : Icons.bolt,
                          color: _yellow,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monitor.isConnected
                                  ? 'Online — Offline Tracks'
                                  : 'Offline Mode Active',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Only downloaded audio files are stored locally.',
                              style: TextStyle(
                                  color: Color(0xFF888888), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Count badge
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cached Tracks',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${songs.length} audio files on device',
                                style: const TextStyle(
                                    color: Color(0xFF888888), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.download_done,
                            color: _yellow, size: 22),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Track list or empty state
                Expanded(
                  child: songs.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          itemCount: songs.length,
                          itemBuilder: (context, i) {
                            final song = songs[i];
                            return Dismissible(
                              key: Key(song.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) =>
                                  offline.deleteDownload(song.id),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: SongRow(
                                  song: song,
                                  queue: songs.toList(),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.music_note, color: Color(0xFF888888), size: 60),
            SizedBox(height: 12),
            Text(
              'No offline tracks yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Browse the Library, then tap the download button on any track.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
