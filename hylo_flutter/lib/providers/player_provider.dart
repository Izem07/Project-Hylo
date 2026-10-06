// PlayerProvider — ported from Hylo/PlayerViewModel.swift
// Uses just_audio instead of AVPlayer. No lock-screen metadata on web.
import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';
import '../services/offline_manager.dart';
import '../services/network_monitor.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  Song? _currentSong;
  bool _isPlaying = false;
  double _playbackProgress = 0.0;
  double _currentTime = 0.0;
  double _duration = 0.0;
  bool _isLiked = false;
  String? _playbackError;

  List<Song> _queue = [];
  int _queueIndex = 0;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  double get playbackProgress => _playbackProgress;
  double get currentTime => _currentTime;
  double get duration => _duration;
  bool get isLiked => _isLiked;
  String? get playbackError => _playbackError;
  List<Song> get queue => List.unmodifiable(_queue);
  int get queueIndex => _queueIndex;

  PlayerProvider() {
    _init();
  }

  Future<void> _init() async {
    // Configure audio session for playback (equivalent to AVAudioSession .playback)
    if (!kIsWeb) {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    }

    // Position stream — update progress every ~500ms
    _player.positionStream.listen((position) {
      _currentTime = position.inMilliseconds / 1000.0;
      if (_duration > 0) {
        _playbackProgress = (_currentTime / _duration).clamp(0.0, 1.0);
      }
      notifyListeners();
    });

    // Duration stream
    _player.durationStream.listen((dur) {
      _duration = dur?.inMilliseconds != null ? dur!.inMilliseconds / 1000.0 : 0.0;
      notifyListeners();
    });

    // Playing state stream
    _player.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    // Auto-advance when track ends
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipForward();
      }
    });
  }

  // MARK: - Play

  Future<void> play(Song song, {List<Song>? queue}) async {
    _currentSong = song;
    _isLiked = song.isLiked;
    _playbackError = null;

    if (queue != null && queue.isNotEmpty) {
      _queue = queue;
      _queueIndex = queue.indexWhere((s) => s.id == song.id);
      if (_queueIndex < 0) _queueIndex = 0;
    }

    String? urlString;

    final offlineMgr = OfflineManager();
    if (offlineMgr.isDownloaded(song.id)) {
      urlString = await offlineMgr.localFileUrl(song.id);
      debugPrint('Playing from local cache: ${song.title}');
    } else if (NetworkMonitor().isConnected) {
      urlString = NavidromeService().streamUrl(song.id);
      debugPrint('Streaming from server: ${song.title}');
    } else {
      _playbackError =
          'No connection. Download this track for offline listening.';
      notifyListeners();
      return;
    }

    if (urlString == null) {
      _playbackError = 'Could not resolve playback URL.';
      notifyListeners();
      return;
    }

    try {
      final uri = Uri.parse(urlString);
      // Use setUrl for http/https streams, setFilePath for local files
      if (uri.isScheme('http') || uri.isScheme('https')) {
        await _player.setUrl(urlString);
      } else {
        await _player.setFilePath(urlString);
      }
      await _player.play();
    } catch (e) {
      _playbackError = 'Playback error: ${e.toString()}';
      debugPrint('PlayerProvider.play error: $e');
    }
    notifyListeners();
  }

  // MARK: - Controls

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(double progress) async {
    if (_duration <= 0) return;
    final ms = (progress * _duration * 1000).round();
    await _player.seek(Duration(milliseconds: ms));
  }

  Future<void> skipForward() async {
    if (_queueIndex + 1 < _queue.length) {
      _queueIndex++;
      await play(_queue[_queueIndex], queue: _queue);
    }
  }

  Future<void> skipBack() async {
    if (_currentTime > 3) {
      await seek(0);
    } else if (_queueIndex > 0) {
      _queueIndex--;
      await play(_queue[_queueIndex], queue: _queue);
    } else {
      await seek(0);
    }
  }

  Future<void> toggleLike() async {
    _isLiked = !_isLiked;
    notifyListeners();
    final song = _currentSong;
    if (song == null) return;
    await NavidromeService().setStarred(song.id, _isLiked);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
