import 'dart:async';
import 'dart:math';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../providers/settings_provider.dart';
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
  List<Song> _originalQueue = [];
  int _queueIndex = 0;

  bool _isShuffleEnabled = false;
  bool _isLoopEnabled = false;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  double get playbackProgress => _playbackProgress;
  double get currentTime => _currentTime;
  double get duration => _duration;
  bool get isLiked => _isLiked;
  String? get playbackError => _playbackError;
  List<Song> get queue => List.unmodifiable(_queue);
  int get queueIndex => _queueIndex;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isLoopEnabled => _isLoopEnabled;

  PlayerProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      }

      _player.positionStream.listen((position) {
        _currentTime = position.inMilliseconds / 1000.0;
        if (_duration > 0) {
          _playbackProgress = (_currentTime / _duration).clamp(0.0, 1.0);
        }
        notifyListeners();
      });

      _player.durationStream.listen((dur) {
        _duration = dur != null ? dur.inMilliseconds / 1000.0 : 0.0;
        notifyListeners();
      });

      _player.playingStream.listen((playing) {
        _isPlaying = playing;
        notifyListeners();
      });

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          skipForward();
        }
      });
    } catch (e) {
      debugPrint('PlayerProvider._init error (non-fatal): $e');
    }
  }

  // MARK: - Play

  Future<void> play(Song song, {List<Song>? queue}) async {
    _currentSong = song;
    _isLiked = song.isLiked;
    _playbackError = null;

    if (queue != null && queue.isNotEmpty) {
      _originalQueue = List.from(queue);
      _queue = List.from(queue);
      _queueIndex = _queue.indexWhere((s) => s.id == song.id);
      if (_queueIndex < 0) _queueIndex = 0;

      // Re-apply shuffle if enabled
      if (_isShuffleEnabled) {
        final current = _queue[_queueIndex];
        _queue.removeAt(_queueIndex);
        _queue.shuffle(Random());
        _queue.insert(0, current);
        _queueIndex = 0;
      }
    }

    String? urlString;
    final offlineMgr = OfflineManager();
    if (offlineMgr.isDownloaded(song.id)) {
      urlString = await offlineMgr.localFileUrl(song.id);
    } else if (NetworkMonitor().isConnected) {
      urlString = NavidromeService().streamUrl(song.id);
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
      if (uri.isScheme('http') || uri.isScheme('https')) {
        await _player.setUrl(urlString);
      } else if (!kIsWeb) {
        await _player.setFilePath(urlString);
      } else {
        _playbackError = 'Local file playback not supported on web.';
        notifyListeners();
        return;
      }

      // Crossfade: fade in over crossfadeDuration seconds
      final crossfade = SettingsProvider().crossfadeDuration;
      if (crossfade > 0) {
        await _player.setVolume(0.0);
        await _player.play();
        final steps = crossfade * 10;
        for (var i = 1; i <= steps; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          await _player.setVolume((i / steps).clamp(0.0, 1.0));
        }
      } else {
        await _player.setVolume(1.0);
        await _player.play();
      }
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
      await play(_queue[_queueIndex]);
    } else if (_isLoopEnabled && _queue.isNotEmpty) {
      // Loop: reshuffle if shuffle is on, then restart
      if (_isShuffleEnabled) {
        _queue.shuffle(Random());
      }
      _queueIndex = 0;
      await play(_queue[_queueIndex]);
    }
  }

  Future<void> skipBack() async {
    if (_currentTime > 3) {
      await seek(0);
    } else if (_queueIndex > 0) {
      _queueIndex--;
      await play(_queue[_queueIndex]);
    } else {
      await seek(0);
    }
  }

  // MARK: - Shuffle

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    final current = _currentSong;

    if (_isShuffleEnabled && current != null) {
      _queue = List.from(_originalQueue);
      _queue.removeWhere((s) => s.id == current.id);
      _queue.shuffle(Random());
      _queue.insert(0, current);
      _queueIndex = 0;
    } else {
      // Restore original order, find current position
      _queue = List.from(_originalQueue);
      if (current != null) {
        _queueIndex = _queue.indexWhere((s) => s.id == current.id);
        if (_queueIndex < 0) _queueIndex = 0;
      }
    }
    notifyListeners();
  }

  // MARK: - Loop

  void toggleLoop() {
    _isLoopEnabled = !_isLoopEnabled;
    notifyListeners();
  }

  // MARK: - Like

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
