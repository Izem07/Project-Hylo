// OfflineManager — ported from Hylo/OfflineManager.swift
// Uses http package for downloading, path_provider for documents dir,
// shared_preferences for persisting IDs.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'navidrome_service.dart';

class OfflineManager extends ChangeNotifier {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  static const _idsKey = 'hylo_offline_ids';

  Set<String> _downloadedIds = {};
  List<Song> _downloadedSongs = [];

  Set<String> get downloadedSongIds => Set.unmodifiable(_downloadedIds);
  List<Song> get downloadedSongs => List.unmodifiable(_downloadedSongs);

  Future<void> init() async {
    await _loadIds();
  }

  // MARK: - Paths

  Future<Directory> get _documentsDir async =>
      getApplicationDocumentsDirectory();

  Future<String> localFilePath(String songId) async {
    final dir = await _documentsDir;
    return '${dir.path}/$songId.mp3';
  }

  Future<String> _sidecarPath(String songId) async {
    final dir = await _documentsDir;
    return '${dir.path}/$songId.json';
  }

  bool isDownloaded(String songId) {
    return _downloadedIds.contains(songId);
  }

  // Returns local file URL string if downloaded, null otherwise.
  Future<String?> localFileUrl(String songId) async {
    if (!isDownloaded(songId)) return null;
    return localFilePath(songId);
  }

  // MARK: - Download

  Future<bool> download(Song song) async {
    if (isDownloaded(song.id)) return true;

    final streamUrl = NavidromeService().streamUrl(song.id);
    if (streamUrl == null) return false;

    try {
      final response = await http.get(Uri.parse(streamUrl));
      if (response.statusCode != 200) return false;

      final mp3Path = await localFilePath(song.id);
      final sidecarPath = await _sidecarPath(song.id);

      await File(mp3Path).writeAsBytes(response.bodyBytes);
      await File(sidecarPath)
          .writeAsString(jsonEncode(song.toJson()));

      _downloadedIds.add(song.id);
      await _saveIds();
      await _rebuildDownloadedSongs();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('OfflineManager.download error: $e');
      return false;
    }
  }

  // MARK: - Delete

  Future<void> deleteDownload(String songId) async {
    try {
      final mp3Path = await localFilePath(songId);
      final sidecarPath = await _sidecarPath(songId);
      final mp3 = File(mp3Path);
      final sidecar = File(sidecarPath);
      if (await mp3.exists()) await mp3.delete();
      if (await sidecar.exists()) await sidecar.delete();
    } catch (e) {
      debugPrint('OfflineManager.deleteDownload error: $e');
    }
    _downloadedIds.remove(songId);
    await _saveIds();
    await _rebuildDownloadedSongs();
    notifyListeners();
  }

  // MARK: - Rebuild metadata list

  Future<void> _rebuildDownloadedSongs() async {
    final songs = <Song>[];
    for (final id in _downloadedIds) {
      try {
        final path = await _sidecarPath(id);
        final file = File(path);
        if (await file.exists()) {
          final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          songs.add(Song.fromJson(json));
        }
      } catch (e) {
        debugPrint('OfflineManager._rebuildDownloadedSongs error for $id: $e');
      }
    }
    songs.sort((a, b) => a.title.compareTo(b.title));
    _downloadedSongs = songs;
  }

  // MARK: - Persistence

  Future<void> _saveIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_idsKey, _downloadedIds.toList());
  }

  Future<void> _loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_idsKey) ?? [];

    // Validate each ID still has a file on disk
    final validated = <String>[];
    for (final id in stored) {
      final path = await localFilePath(id);
      if (await File(path).exists()) {
        validated.add(id);
      }
    }
    _downloadedIds = validated.toSet();
    await _rebuildDownloadedSongs();
    notifyListeners();
  }
}
