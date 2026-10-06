// LibraryScreen — ported from Hylo/LibraryView.swift
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';
import '../services/network_monitor.dart';
import '../widgets/album_cell.dart';
import '../widgets/song_row.dart';

// MARK: - Library root

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  List<Album> _albums = [];
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  int _selectedTab = 0; // 0 = Albums, 1 = Playlists
  String _lastServerURL = ''; // track credential changes

  // Pulsing dot animation
  late AnimationController _dotController;
  late Animation<double> _dotOpacity;

  static const _yellow = Color(0xFFF9CC1B);

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _dotOpacity = Tween<double>(begin: 1.0, end: 0.4).animate(_dotController);

    // Delay so providers are available in context
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContent());
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload whenever the server URL changes (e.g. after connecting in Settings)
    final navidrome = context.read<NavidromeService>();
    if (navidrome.serverURL != _lastServerURL) {
      _lastServerURL = navidrome.serverURL;
      _loadContent();
    }
  }

  Future<void> _loadContent() async {
    final navidrome = context.read<NavidromeService>();
    final monitor = context.read<NetworkMonitor>();

    if (navidrome.serverURL.trim().isEmpty ||
        navidrome.username.trim().isEmpty) {
      return;
    }
    if (!monitor.isConnected) return;

    setState(() => _isLoading = true);

    if (_selectedTab == 0) {
      final albums = await navidrome.fetchAlbums();
      if (mounted) {
        setState(() {
          _albums = albums;
          _isLoading = false;
        });
      }
    } else {
      final playlists = await navidrome.fetchPlaylists();
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<NetworkMonitor>();
    context.watch<
        NavidromeService>(); // trigger didChangeDependencies on credential changes

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _dotOpacity,
                        builder: (context, child) {
                          return Opacity(
                            opacity:
                                monitor.isConnected ? _dotOpacity.value : 1.0,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: monitor.isConnected
                                    ? Colors.green
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Text(
                        monitor.isConnected
                            ? 'Live from server'
                            : 'Server unreachable',
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Segment picker — animated pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SegmentControl(
                selectedTab: _selectedTab,
                onTabChanged: (i) {
                  setState(() => _selectedTab = i);
                  _loadContent();
                },
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _yellow))
                  : _selectedTab == 0
                      ? _albumGrid()
                      : _playlistList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _albumGrid() {
    final navidrome = context.read<NavidromeService>();
    final notConfigured =
        navidrome.serverURL.trim().isEmpty || navidrome.username.trim().isEmpty;

    if (notConfigured) {
      return _emptyState(
        icon: Icons.settings_outlined,
        message:
            'Enter your server URL, username, and password in Settings, then tap Connect.',
      );
    }
    if (_albums.isEmpty) {
      return _emptyState(
        icon: Icons.library_music,
        message:
            'No albums found.\nMake sure your server is reachable and credentials are correct.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, i) {
        final album = _albums[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlbumDetailScreen(album: album),
            ),
          ),
          child: AlbumCell(album: album),
        );
      },
    );
  }

  Widget _playlistList() {
    if (_playlists.isEmpty) {
      return _emptyState(
        icon: Icons.queue_music,
        message: 'No playlists found on your server.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _playlists.length,
      itemBuilder: (context, i) {
        final playlist = _playlists[i];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(playlist: playlist),
            ),
          ),
          child: _PlaylistRow(playlist: playlist),
        );
      },
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF888888), size: 52),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Animated segment control

class _SegmentControl extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const _SegmentControl({
    required this.selectedTab,
    required this.onTabChanged,
  });

  static const _labels = ['Albums', 'Playlists'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pillWidth = constraints.maxWidth / 2;
        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              // Sliding yellow indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: selectedTab * pillWidth,
                top: 3,
                bottom: 3,
                width: pillWidth - 3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9CC1B),
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
              // Labels on top
              Row(
                children: List.generate(_labels.length, (i) {
                  final selected = i == selectedTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTabChanged(i),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          _labels[i],
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

// MARK: - Playlist row

class _PlaylistRow extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistRow({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final artUrl = NavidromeService().coverArtUrl(playlist.coverArt, size: 80);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: artUrl != null
                ? CachedNetworkImage(
                    imageUrl: artUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _thumbPlaceholder(),
                    errorWidget: (_, __, ___) => _thumbPlaceholder(),
                  )
                : _thumbPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${playlist.songCount} songs',
                  style:
                      const TextStyle(color: Color(0xFF999999), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF888888), size: 16),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.white.withValues(alpha: 0.08),
      child: const Icon(Icons.queue_music, color: Color(0xFF888888), size: 22),
    );
  }
}

// MARK: - Album detail screen

class AlbumDetailScreen extends StatefulWidget {
  final Album album;
  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  static const _yellow = Color(0xFFF9CC1B);

  @override
  void initState() {
    super.initState();
    NavidromeService().fetchTracks(widget.album.id).then((songs) {
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final artUrl =
        NavidromeService().coverArtUrl(widget.album.coverArt, size: 120);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        title: Text(widget.album.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _yellow))
          : ListView(
              children: [
                // Album header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: artUrl != null
                            ? CachedNetworkImage(
                                imageUrl: artUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _artPlaceholder(),
                                errorWidget: (_, __, ___) => _artPlaceholder(),
                              )
                            : _artPlaceholder(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.album.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.album.artist != null)
                              Text(
                                widget.album.artist!,
                                style: const TextStyle(
                                    color: Color(0xFF888888), fontSize: 14),
                              ),
                            Text(
                              '${_songs.length} tracks',
                              style: const TextStyle(
                                  color: Color(0xFF888888), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                // Track list
                ..._songs.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SongRow(song: s, queue: _songs),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _artPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.white.withValues(alpha: 0.1),
      child: const Icon(Icons.music_note, color: Color(0xFF888888), size: 32),
    );
  }
}

// MARK: - Playlist detail screen

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  static const _yellow = Color(0xFFF9CC1B);

  @override
  void initState() {
    super.initState();
    NavidromeService().fetchPlaylistTracks(widget.playlist.id).then((songs) {
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        title: Text(widget.playlist.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _yellow))
          : _songs.isEmpty
              ? const Center(
                  child: Text('This playlist is empty.',
                      style: TextStyle(color: Color(0xFF888888))))
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SongRow(song: _songs[i], queue: _songs),
                  ),
                ),
    );
  }
}
