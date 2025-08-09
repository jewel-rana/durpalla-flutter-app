import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<bool> checkAuthAndRedirect(BuildContext context) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');
  final ok = token != null && token.isNotEmpty;
  if (!ok && context.mounted) {
    Navigator.pushReplacementNamed(context, '/auth/check');
  }
  return ok;
}

Future<void> logout(BuildContext context) async {
  const storage = FlutterSecureStorage();
  await storage.delete(key: 'token');
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(context, '/auth/check', (_) => false);
}

/// Wrap any protected screen with this.
class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});
  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  @override
  void initState() {
    super.initState();
    // run after first frame to have a valid context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthAndRedirect(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
