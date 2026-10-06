// main.dart — Hylo Flutter entry point
// Ported from Hylo/ContentView.swift + AppDelegate.swift
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/player_provider.dart';
import 'screens/connect_screen.dart';
import 'screens/library_screen.dart';
import 'screens/offline_screen.dart';
import 'services/navidrome_service.dart';
import 'services/network_monitor.dart';
import 'services/offline_manager.dart';
import 'widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise singletons that need async setup before the UI starts
  await NavidromeService().init();
  await OfflineManager().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NavidromeService>.value(
            value: NavidromeService()),
        ChangeNotifierProvider<OfflineManager>.value(value: OfflineManager()),
        ChangeNotifierProvider<NetworkMonitor>.value(value: NetworkMonitor()),
        ChangeNotifierProvider<PlayerProvider>(create: (_) => PlayerProvider()),
      ],
      child: const HyloApp(),
    ),
  );
}

class HyloApp extends StatelessWidget {
  const HyloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hylo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF141414),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF9CC1B),
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141414),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFFF9CC1B),
          unselectedItemColor: Color(0xFF888888),
        ),
      ),
      home: const _RootShell(),
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    LibraryScreen(),
    OfflineScreen(),
    ConnectScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<NetworkMonitor>();

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Stack(
        children: [
          // Tab content via IndexedStack (keeps state across tab switches)
          IndexedStack(index: _currentIndex, children: _pages),

          // No-connection banner at top
          if (!monitor.isConnected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: const Color(0xFFF9CC1B),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: const [
                        Icon(Icons.wifi_off, size: 14, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'No connection — Offline mode active',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player floats above the tab bar
          const MiniPlayer(),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.download_outlined),
                activeIcon: Icon(Icons.download_done),
                label: 'Offline',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
