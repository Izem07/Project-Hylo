// NavidromeService — ported from Hylo/NavidromeService.swift
// Uses HTTP package instead of URLSession, crypto for MD5, uuid for salt.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/api_models.dart';

class NavidromeService extends ChangeNotifier {
  static final NavidromeService _instance = NavidromeService._internal();
  factory NavidromeService() => _instance;
  NavidromeService._internal();

  // Preference keys (matching Swift UserDefaults keys)
  static const _urlKey = 'hylo_url';
  static const _userKey = 'hylo_user';
  static const _passKey = 'hylo_pass';
  static const _insecureKey = 'hylo_insecure';

  String _serverURL = '';
  String _username = '';
  String _password = '';
  bool _allowInsecure = false;

  String get serverURL => _serverURL;
  String get username => _username;
  String get password => _password;
  bool get allowInsecure => _allowInsecure;

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

  // MARK: - Auth helpers

  /// Generate a fresh salt + MD5 token on every call (Subsonic auth spec).
  String get _authParams {
    final salt =
        const Uuid().v4().replaceAll('-', '').substring(0, 12);
    final tokenInput = _password + salt;
    final token =
        md5.convert(utf8.encode(tokenInput)).toString();
    return 'u=$_username&t=$token&s=$salt&v=1.16.1&c=Hylo&f=json';
  }

  /// Normalised base URL: trim trailing slash, prepend https:// when no scheme.
  String get baseURL {
    var url = _serverURL.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  // MARK: - URL helpers

  String? streamUrl(String songId) {
    if (baseURL.isEmpty) return null;
    return '$baseURL/rest/stream.view?id=$songId&$_authParams';
  }

  String? coverArtUrl(String? coverId, {int size = 300}) {
    if (coverId == null || coverId.isEmpty || baseURL.isEmpty) return null;
    return '$baseURL/rest/getCoverArt.view?id=$coverId&size=$size&$_authParams';
  }

  // MARK: - Albums

  Future<List<Album>> fetchAlbums() async {
    if (baseURL.isEmpty) return [];
    try {
      final uri = Uri.parse(
          '$baseURL/rest/getAlbumList2.view?type=alphabeticalByName&size=100&$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final albumList = body?['albumList2'] as Map<String, dynamic>?;
      final albums = albumList?['album'] as List<dynamic>?;
      return albums
              ?.map((a) => Album.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [];
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
          '$baseURL/rest/getAlbum.view?id=$albumId&$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final album = body?['album'] as Map<String, dynamic>?;
      final songs = album?['song'] as List<dynamic>?;
      return songs
              ?.map((s) => Song.fromSubsonic(s as Map<String, dynamic>))
              .toList() ??
          [];
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
          Uri.parse('$baseURL/rest/getPlaylists.view?$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final wrapper = body?['playlists'] as Map<String, dynamic>?;
      final playlists = wrapper?['playlist'] as List<dynamic>?;
      return playlists
              ?.map((p) => Playlist.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [];
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
          '$baseURL/rest/getPlaylist.view?id=$playlistId&$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final playlist = body?['playlist'] as Map<String, dynamic>?;
      final entries = playlist?['entry'] as List<dynamic>?;
      return entries
              ?.map((s) => Song.fromSubsonic(s as Map<String, dynamic>))
              .toList() ??
          [];
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
          '$baseURL/rest/search3.view?query=$encoded&$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final body = data['subsonic-response'] as Map<String, dynamic>?;
      final result = body?['searchResult3'] as Map<String, dynamic>?;
      final songs = result?['song'] as List<dynamic>?;
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
      final uri = Uri.parse(
          '$baseURL/rest/$endpoint?id=$songId&$_authParams');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('setStarred error: $e');
      return false;
    }
  }

  // MARK: - Connection test

  Future<(bool, String?)> testConnection() async {
    if (baseURL.isEmpty) {
      return (false, 'Server URL is empty.');
    }
    try {
      final uri =
          Uri.parse('$baseURL/rest/ping.view?$_authParams');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return (false, 'Server returned HTTP ${response.statusCode}.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final root = data['subsonic-response'] as Map<String, dynamic>?;
      if (root == null) {
        return (false, 'Unexpected server response.');
      }
      final error = root['error'] as Map<String, dynamic>?;
      if (error != null) {
        final code = error['code'];
        if (code == 40 || code == 41) {
          return (false, 'Authentication failed — check your credentials.');
        }
        return (false, error['message']?.toString() ?? 'Server error.');
      }
      if (root['status'] == 'ok') {
        return (true, null);
      }
      return (false, 'Server returned an error.');
    } catch (e) {
      return (false, e.toString());
    }
  }
}
