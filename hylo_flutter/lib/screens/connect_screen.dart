// ConnectScreen — ported from Hylo/ConnectView.swift
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/navidrome_service.dart';
import '../widgets/capsule_pill.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _isTesting = false;
  _ConnectionResult? _result;

  static const _yellow = Color(0xFFF9CC1B);

  @override
  Widget build(BuildContext context) {
    final navidrome = context.watch<NavidromeService>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branding header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hylo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your music server, built for the drive.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect to Navidrome for albums, playlists, search, favorites, offline listening, and full queue control.',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    // Feature pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: const [
                          CapsulePill(title: 'Albums'),
                          SizedBox(width: 8),
                          CapsulePill(title: 'Playlists'),
                          SizedBox(width: 8),
                          CapsulePill(title: 'Favorites'),
                          SizedBox(width: 8),
                          CapsulePill(title: 'Offline'),
                          SizedBox(width: 8),
                          CapsulePill(title: 'Queue'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Connect form card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Server URL
                      _formField(
                        label: 'SERVER URL',
                        hint:
                            'Use a full URL or hostname. Defaults to HTTPS when no scheme is provided.',
                        child: _textField(
                          value: navidrome.serverURL,
                          hint: 'music.example.com or http://192.168.1.x:4533',
                          onChanged: (v) => navidrome.serverURL = v,
                          keyboardType: TextInputType.url,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Allow Insecure HTTP toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Allow Insecure HTTP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Only enable for a trusted local, LAN, or Tailscale server.',
                                    style: TextStyle(
                                        color: Color(0xFF888888), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: navidrome.allowInsecure,
                              activeThumbColor: _yellow,
                              activeTrackColor: _yellow.withValues(alpha: 0.5),
                              onChanged: (v) => navidrome.allowInsecure = v,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Username
                      _formField(
                        label: 'USERNAME',
                        child: _textField(
                          value: navidrome.username,
                          hint: 'Username',
                          onChanged: (v) => navidrome.username = v,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password
                      _formField(
                        label: 'PASSWORD',
                        child: _textField(
                          value: navidrome.password,
                          hint: 'Password',
                          onChanged: (v) => navidrome.password = v,
                          obscure: true,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Connection result banner
                      if (_result != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _result!.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(_result!.icon,
                                  color: _result!.color, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _result!.message,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Connect button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isTesting ||
                                  navidrome.serverURL.isEmpty ||
                                  navidrome.username.isEmpty
                              ? null
                              : _testConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _yellow,
                            disabledBackgroundColor:
                                _yellow.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isTesting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2),
                                )
                              : const Text(
                                  'Connect to Server',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _result = null;
    });
    final (success, message) = await NavidromeService().testConnection();
    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _result = success
          ? _ConnectionResult.success
          : _ConnectionResult.failure(message ?? 'Connection failed.');
    });
  }

  Widget _formField({
    required String label,
    String? hint,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
        ],
      ],
    );
  }

  Widget _textField({
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextFormField(
      initialValue: value,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: !obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: onChanged,
    );
  }
}

// MARK: - Connection result

sealed class _ConnectionResult {
  const _ConnectionResult();

  static const success = _Success();
  static _Failure failure(String msg) => _Failure(msg);

  IconData get icon;
  Color get color;
  String get message;
}

final class _Success extends _ConnectionResult {
  const _Success();
  @override
  IconData get icon => Icons.check_circle;
  @override
  Color get color => Colors.green;
  @override
  String get message => 'Connected successfully!';
}

final class _Failure extends _ConnectionResult {
  final String _message;
  const _Failure(this._message);
  @override
  IconData get icon => Icons.cancel;
  @override
  Color get color => Colors.red;
  @override
  String get message => _message;
}
