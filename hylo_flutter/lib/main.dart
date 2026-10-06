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

  // Init singletons that need async setup before the UI starts
  final navidrome = NavidromeService();
  final offline = OfflineManager();
  await navidrome.init();
  await offline.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NavidromeService>.value(value: navidrome),
        ChangeNotifierProvider<OfflineManager>.value(value: offline),
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
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF9CC1B),
          surface: Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A0A0A),
          selectedItemColor: Color(0xFFF9CC1B),
          unselectedItemColor: Color(0xFF555555),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFFF9CC1B),
          thumbColor: Color(0xFFF9CC1B),
          inactiveTrackColor: Color(0xFF333333),
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

  static const _navItems = <_NavItem>[
    _NavItem(
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music,
      label: 'Library',
    ),
    _NavItem(
      icon: Icons.download_outlined,
      activeIcon: Icons.download_done,
      label: 'Offline',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<NetworkMonitor>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Tab content — IndexedStack keeps state across tab switches
          IndexedStack(index: _currentIndex, children: _pages),

          // No-connection banner
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
            items: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = i == _currentIndex;
              return BottomNavigationBarItem(
                label: item.label,
                icon: _NavIconWithDot(
                  icon: item.icon,
                  selected: false,
                  dotSelected: selected,
                ),
                activeIcon: _NavIconWithDot(
                  icon: item.activeIcon,
                  selected: true,
                  dotSelected: selected,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavIconWithDot extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final bool dotSelected;

  const _NavIconWithDot({
    required this.icon,
    required this.selected,
    required this.dotSelected,
  });

  static const _yellow = Color(0xFFF9CC1B);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 3),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: dotSelected ? _yellow : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
