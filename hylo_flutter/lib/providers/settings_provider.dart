import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  factory SettingsProvider() => _instance;
  SettingsProvider._internal();

  // Preference keys
  static const _keyAccentColor = 'hylo_settings_accentColor';
  static const _keyStreamQuality = 'hylo_settings_streamQuality';
  static const _keySkipSilence = 'hylo_settings_skipSilence';
  static const _keyCrossfadeDuration = 'hylo_settings_crossfadeDuration';
  static const _keyDownloadOnWifiOnly = 'hylo_settings_downloadOnWifiOnly';
  static const _keyAlbumGridColumns = 'hylo_settings_albumGridColumns';
  static const _keyShowAlbumArtistInRow = 'hylo_settings_showAlbumArtistInRow';

  // Fields with defaults
  int _accentColor = 0xFFF9CC1B;
  String _streamQuality = 'high';
  bool _skipSilence = false;
  int _crossfadeDuration = 0;
  bool _downloadOnWifiOnly = true;
  int _albumGridColumns = 2;
  bool _showAlbumArtistInRow = true;

  // Getters
  int get accentColor => _accentColor;
  String get streamQuality => _streamQuality;
  bool get skipSilence => _skipSilence;
  int get crossfadeDuration => _crossfadeDuration;
  bool get downloadOnWifiOnly => _downloadOnWifiOnly;
  int get albumGridColumns => _albumGridColumns;
  bool get showAlbumArtistInRow => _showAlbumArtistInRow;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _accentColor = _prefs!.getInt(_keyAccentColor) ?? 0xFFF9CC1B;
    _streamQuality = _prefs!.getString(_keyStreamQuality) ?? 'high';
    _skipSilence = _prefs!.getBool(_keySkipSilence) ?? false;
    _crossfadeDuration = _prefs!.getInt(_keyCrossfadeDuration) ?? 0;
    _downloadOnWifiOnly = _prefs!.getBool(_keyDownloadOnWifiOnly) ?? true;
    _albumGridColumns = _prefs!.getInt(_keyAlbumGridColumns) ?? 2;
    _showAlbumArtistInRow = _prefs!.getBool(_keyShowAlbumArtistInRow) ?? true;
    notifyListeners();
  }

  // Setters — persist to SharedPreferences and notify listeners

  set accentColor(int v) {
    _accentColor = v;
    _prefs?.setInt(_keyAccentColor, v);
    notifyListeners();
  }

  set streamQuality(String v) {
    _streamQuality = v;
    _prefs?.setString(_keyStreamQuality, v);
    notifyListeners();
  }

  set skipSilence(bool v) {
    _skipSilence = v;
    _prefs?.setBool(_keySkipSilence, v);
    notifyListeners();
  }

  set crossfadeDuration(int v) {
    _crossfadeDuration = v;
    _prefs?.setInt(_keyCrossfadeDuration, v);
    notifyListeners();
  }

  set downloadOnWifiOnly(bool v) {
    _downloadOnWifiOnly = v;
    _prefs?.setBool(_keyDownloadOnWifiOnly, v);
    notifyListeners();
  }

  set albumGridColumns(int v) {
    _albumGridColumns = v;
    _prefs?.setInt(_keyAlbumGridColumns, v);
    notifyListeners();
  }

  set showAlbumArtistInRow(bool v) {
    _showAlbumArtistInRow = v;
    _prefs?.setBool(_keyShowAlbumArtistInRow, v);
    notifyListeners();
  }
}
