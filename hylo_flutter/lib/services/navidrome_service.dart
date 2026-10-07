// NavidromeService — ported from Hylo/NavidromeService.swift
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/api_models.dart';
import '../providers/settings_provider.dart';

class NavidromeService extends ChangeNotifier {
  static final NavidromeService _instance = NavidromeService._internal();
  factory NavidromeService() => _instance;
  NavidromeService._internal();

  static const _urlKey = 'hylo_url';
  static const _userKey = 'hylo_user';
  static const _passKey = 'hylo_pass';
  static const _insecureKey = 'hylo_insecure';

  String _serverURL = '';
  String _username = '';
  String _password = '';
  bool _allowInsecure = false;
  bool _isServerReachable = false;

  String get serverURL => _serverURL;
  String get username => _username;
  String get password => _password;
  bool get allowInsecure => _allowInsecure;
  bool get isServerReachable => _isServerReachable;

  set serverURL(String v) {
    _serverURL = v;
    _prefs?.setString(_urlKey, v);
    notifyListeners();
  }

  set username(String v) {
    _username = v;
    _prefs?.setString(_userKey, v);
    notifyListeners();
  }

  set password(String v) {
    _password = v;
    _prefs?.setString(_passKey, v);
    notifyListeners();
  }

  set allowInsecure(bool v) {
    _allowInsecure = v;
    _prefs?.setBool(_insecureKey, v);
    notifyListeners();
  }

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _serverURL = _prefs!.getString(_urlKey) ?? '';
    _username = _prefs!.getString(_userKey) ?? '';
    _password = _prefs!.getString(_passKey) ?? '';
    _allowInsecure = _prefs!.getBool(_insecureKey) ?? false;
    notifyListeners();
  }

  // MARK: - Auth

  String get _authParams {
    final salt = const Uuid().v4().replaceAll('-', '').substring(0, 12);
    final token = md5.convert(utf8.encode(_password + salt)).toString();
    return 'u=$_username&t=$token&s=$salt&v=1.16.1&c=Hylo&f=json';
  }

  /// Real server base URL (used for iOS/Android).
  /// Real server base URL. Respects the allowInsecure toggle:
  /// - allowInsecure ON  → keeps http:// as-is (LAN / Tailscale IP)
  /// - allowInsecure OFF → always uses https://
  String get baseURL {
    var url = _serverURL.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = _allowInsecure ? 'http://$url' : 'https://$url';
    } else if (!_allowInsecure && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  /// On web, route through local CORS proxy only if NAVIDROME_PROXY is set.
  /// Otherwise use baseURL directly (works when Tailscale is active on the machine).
  String get _effectiveBase => baseURL;

  // MARK: - URL helpers

  String? streamUrl(String songId) {
    if (baseURL.isEmpty) return null;
    final quality = SettingsProvider().streamQuality;
    final bitRate = quality == 'medium'
        ? 192
        : quality == 'low'
            ? 128
            : 320;
    return '$_effectiveBase/rest/stream.view?id=$songId&$_authParams&maxBitRate=$bitRate';
  }

  String? coverArtUrl(String? coverId, {int size = 300}) {
    if (coverId == null || coverId.isEmpty || baseURL.isEmpty) return null;
    return '$_effectiveBase/rest/getCoverArt.view?id=$coverId&size=$size&$_authParams';
  }

  /// Marks the server as reachable. Called after any successful API response.
  void _markReachable() {
    if (!_isServerReachable) {
      _isServerReachable = true;
      notifyListeners();
    }
  }

  // MARK: - Albums

  Future<List<Album>> fetchAlbums() async {
    if (baseURL.isEmpty) return [];
    try {
      final uri = Uri.parse(
          '$_effectiveBase/rest/getAlbumList2.view?type=alphabeticalByName&size=100&$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final albums = (body?['albumList2'] as Map<String, dynamic>?)?['album']
          as List<dynamic>?;
      final result = albums
              ?.map((a) => Album.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [];
      _markReachable();
      return result;
    } catch (e) {
      debugPrint('fetchAlbums error: $e');
      return [];
    }
  }

  // MARK: - Album tracks

  Future<List<Song>> fetchTracks(String albumId) async {
    if (baseURL.isEmpty) return [];
    try {
      final uri = Uri.parse(
          '$_effectiveBase/rest/getAlbum.view?id=$albumId&$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final songs =
          (body?['album'] as Map<String, dynamic>?)?['song'] as List<dynamic>?;
      final result = songs
              ?.map((s) => Song.fromSubsonic(s as Map<String, dynamic>))
              .toList() ??
          [];
      _markReachable();
      return result;
    } catch (e) {
      debugPrint('fetchTracks error: $e');
      return [];
    }
  }

  // MARK: - Playlists

  Future<List<Playlist>> fetchPlaylists() async {
    if (baseURL.isEmpty) return [];
    try {
      final uri =
          Uri.parse('$_effectiveBase/rest/getPlaylists.view?$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final playlists = (body?['playlists']
          as Map<String, dynamic>?)?['playlist'] as List<dynamic>?;
      final result = playlists
              ?.map((p) => Playlist.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [];
      _markReachable();
      return result;
    } catch (e) {
      debugPrint('fetchPlaylists error: $e');
      return [];
    }
  }

  // MARK: - Playlist tracks

  Future<List<Song>> fetchPlaylistTracks(String playlistId) async {
    if (baseURL.isEmpty) return [];
    try {
      final uri = Uri.parse(
          '$_effectiveBase/rest/getPlaylist.view?id=$playlistId&$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final entries = (body?['playlist'] as Map<String, dynamic>?)?['entry']
          as List<dynamic>?;
      final result = entries
              ?.map((s) => Song.fromSubsonic(s as Map<String, dynamic>))
              .toList() ??
          [];
      _markReachable();
      return result;
    } catch (e) {
      debugPrint('fetchPlaylistTracks error: $e');
      return [];
    }
  }

  // MARK: - Search

  Future<List<Song>> search(String query) async {
    if (baseURL.isEmpty || query.isEmpty) return [];
    try {
      final encoded = Uri.encodeQueryComponent(query);
      final uri = Uri.parse(
          '$_effectiveBase/rest/search3.view?query=$encoded&$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final songs = (body?['searchResult3'] as Map<String, dynamic>?)?['song']
          as List<dynamic>?;
      return songs
              ?.map((s) => Song.fromSubsonic(s as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      debugPrint('search error: $e');
      return [];
    }
  }

  // MARK: - Star / Unstar

  Future<bool> setStarred(String songId, bool starred) async {
    final endpoint = starred ? 'star.view' : 'unstar.view';
    try {
      final uri =
          Uri.parse('$_effectiveBase/rest/$endpoint?id=$songId&$_authParams');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('setStarred error: $e');
      return false;
    }
  }

  // MARK: - Liked Songs

  Future<List<Song>> fetchLikedSongs() async {
    if (baseURL.isEmpty) return [];
    try {
      final uri =
          Uri.parse('$_effectiveBase/rest/getStarred.view?$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final songs = (body?['starred'] as Map<String, dynamic>?)?['song']
          as List<dynamic>?;
      final result = songs
              ?.map((s) => Song.fromSubsonic(s as Map<String, dynamic>))
              .toList() ??
          [];
      _markReachable();
      return result;
    } catch (e) {
      debugPrint('fetchLikedSongs error: $e');
      return [];
    }
  }

  // MARK: - Connection test

  Future<(bool, String?)> testConnection() async {
    if (baseURL.isEmpty) return (false, 'Server URL is empty.');
    try {
      final uri = Uri.parse('$_effectiveBase/rest/ping.view?$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        _isServerReachable = false;
        notifyListeners();
        return (false, 'Server returned HTTP ${response.statusCode}.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final root = data['subsonic-response'] as Map<String, dynamic>?;
      if (root == null) {
        _isServerReachable = false;
        notifyListeners();
        return (false, 'Unexpected server response.');
      }
      final error = root['error'] as Map<String, dynamic>?;
      if (error != null) {
        _isServerReachable = false;
        notifyListeners();
        final code = error['code'];
        if (code == 40 || code == 41)
          return (false, 'Authentication failed — check your credentials.');
        return (false, error['message']?.toString() ?? 'Server error.');
      }
      if (root['status'] == 'ok') {
        _isServerReachable = true;
        notifyListeners();
        return (true, null);
      }
      _isServerReachable = false;
      notifyListeners();
      return (false, 'Server returned an error.');
    } catch (e) {
      _isServerReachable = false;
      notifyListeners();
      return (false, e.toString());
    }
  }
}
