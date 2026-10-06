// NetworkMonitor — ported from Hylo/NetworkMonitor.swift
// Uses connectivity_plus instead of NWPathMonitor.
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkMonitor extends ChangeNotifier {
  static final NetworkMonitor _instance = NetworkMonitor._internal();
  factory NetworkMonitor() => _instance;
  NetworkMonitor._internal() {
    _init();
  }

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void _init() {
    // Check current state immediately
    Connectivity().checkConnectivity().then((results) {
      _updateFromResults(results);
    });

    // Subscribe to future changes
    _subscription =
        Connectivity().onConnectivityChanged.listen(_updateFromResults);
  }

  void _updateFromResults(List<ConnectivityResult> results) {
    final connected = results.any((r) => r != ConnectivityResult.none);
    if (connected != _isConnected) {
      _isConnected = connected;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
