import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/navidrome_service.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _isTesting = false;
  _ConnResult? _result;

  static const _yellow = Color(0xFFF9CC1B);
  static const _bg = Color(0xFF0A0A0A);
  static const _card = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2A2A2A);
  static const _gray = Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavidromeService>();
    final settings = context.watch<SettingsProvider>();
    final allFilled = nav.serverURL.trim().isNotEmpty &&
        nav.username.trim().isNotEmpty &&
        nav.password.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── BRANDING HEADER ──
            const Text('Hylo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Your music server, built for the drive.',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
                'Connect to Navidrome for albums, playlists, search, favorites, offline listening, and full queue control.',
                style: TextStyle(color: _gray, fontSize: 13, height: 1.5)),
            const SizedBox(height: 12),
            // Feature pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _pill('Albums'),
                _pill('Playlists'),
                _pill('Favorites'),
                _pill('Offline'),
                _pill('Queue'),
              ]),
            ),
            const SizedBox(height: 16),
            // Server status dot
            Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: nav.isServerReachable ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                nav.isServerReachable
                    ? 'Connected to Navidrome'
                    : nav.serverURL.isEmpty
                        ? 'Not configured'
                        : 'Not connected',
                style: const TextStyle(color: _gray, fontSize: 12),
              ),
            ]),

            const SizedBox(height: 28),

            // ── NAVIDROME SECTION ──
            _sectionLabel('NAVIDROME'),
            _cardWidget(children: [
              // Connected badge
              if (nav.isServerReachable) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(nav.serverURL,
                          style: const TextStyle(
                              color: Colors.green, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              _field(
                  label: 'SERVER URL',
                  hint: 'http://100.68.x.x:4533 or https://music.ts.net:4533',
                  value: nav.serverURL,
                  onChanged: (v) => nav.serverURL = v,
                  keyboardType: TextInputType.url),

              const SizedBox(height: 14),

              // Allow Insecure HTTP toggle — actually wired now
              _toggle(
                title: 'Allow Insecure HTTP',
                subtitle:
                    'Keeps http:// as-is. Enable for LAN / Tailscale IP addresses.',
                value: nav.allowInsecure,
                onChanged: (v) => nav.allowInsecure = v,
              ),

              const SizedBox(height: 14),

              _field(
                  label: 'USERNAME',
                  hint: 'Username',
                  value: nav.username,
                  onChanged: (v) => nav.username = v),

              const SizedBox(height: 14),

              _field(
                  label: 'PASSWORD',
                  hint: 'Password',
                  value: nav.password,
                  onChanged: (v) => nav.password = v,
                  obscure: true),

              const SizedBox(height: 20),

              // Result banner
              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _result!.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                        left: BorderSide(color: _result!.color, width: 3)),
                  ),
                  child: Row(children: [
                    Icon(_result!.icon, color: _result!.color, size: 17),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_result!.message,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Connect button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isTesting || !allFilled ? null : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _yellow,
                    disabledBackgroundColor: _yellow.withValues(alpha: 0.25),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : const Text('Connect to Navidrome',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // ── PLAYBACK ──
            _sectionLabel('PLAYBACK'),
            _cardWidget(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Crossfade',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(
                  settings.crossfadeDuration == 0
                      ? 'Off'
                      : '${settings.crossfadeDuration}s',
                  style: const TextStyle(
                      color: Color(0xFFF9CC1B), fontWeight: FontWeight.bold),
                ),
              ]),
              const SizedBox(height: 4),
              const Text('Blend tracks together when skipping',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFF9CC1B),
                  inactiveTrackColor: const Color(0xFF2A2A2A),
                  thumbColor: const Color(0xFFF9CC1B),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: settings.crossfadeDuration.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (v) => settings.crossfadeDuration = v.round(),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // ── MORE SERVICES (placeholder) ──
            _sectionLabel('MORE SERVICES'),
            _cardWidget(children: [
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child:
                      const Icon(Icons.add, color: Color(0xFF555555), size: 18),
                ),
                const SizedBox(width: 14),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add a service',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('More integrations coming soon',
                          style: TextStyle(
                              color: Color(0xFF555555), fontSize: 12)),
                    ]),
              ]),
            ]),

            const SizedBox(height: 24),

            // ── ABOUT ──
            _sectionLabel('ABOUT'),
            _cardWidget(children: [
              _aboutRow('App', 'Hylo'),
              const Divider(color: _border, height: 1),
              _aboutRow('Version', '1.0.0'),
              const Divider(color: _border, height: 1),
              _aboutRow('Built with', 'Flutter + Dart'),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _connect() async {
    setState(() {
      _isTesting = true;
      _result = null;
    });
    final (success, message) = await NavidromeService().testConnection();
    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _result = success
          ? _ConnResult.success
          : _ConnResult.failure(message ?? 'Connection failed.');
    });
  }

  // ── Helpers ──

  Widget _pill(String title) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: _gray,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8)),
      );

  Widget _cardWidget({required List<Widget> children}) => Container(
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _field({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: _gray,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: value,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: !obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF444444)),
          filled: true,
          fillColor: const Color(0xFF111111),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _yellow, width: 1.5)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _toggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: _gray, fontSize: 11)),
      ])),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: _yellow,
        activeTrackColor: _yellow.withValues(alpha: 0.4),
        inactiveThumbColor: const Color(0xFF555555),
        inactiveTrackColor: const Color(0xFF2A2A2A),
      ),
    ]);
  }

  Widget _aboutRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: _gray, fontSize: 14)),
        ]),
      );
}

// ── Connection result model ──

sealed class _ConnResult {
  const _ConnResult();
  static const success = _Success();
  static _Failure failure(String msg) => _Failure(msg);
  IconData get icon;
  Color get color;
  String get message;
}

final class _Success extends _ConnResult {
  const _Success();
  @override
  IconData get icon => Icons.check_circle;
  @override
  Color get color => Colors.green;
  @override
  String get message => 'Connected successfully!';
}

final class _Failure extends _ConnResult {
  final String _message;
  const _Failure(this._message);
  @override
  IconData get icon => Icons.cancel;
  @override
  Color get color => Colors.red;
  @override
  String get message => _message;
}
