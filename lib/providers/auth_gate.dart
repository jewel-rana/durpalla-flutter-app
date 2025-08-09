import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';
import '../screens/auth/check_mobile_screen.dart';

// Decides first screen: Home if token exists, else Check Mobile
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _hasToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasToken(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final loggedIn = snap.data == true;
        return loggedIn
            ? MainScaffold(onThemeToggle: (v) {}, isDark: false)
            : const CheckMobileScreen(); // you'll add these auth screens
      },
    );
  }
}
