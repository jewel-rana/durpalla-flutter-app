import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/auth_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState(); // <-- required
}

class _LoginScreenState extends State<LoginScreen> {
  late final String mobile;
  final pass = TextEditingController();
  bool busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    mobile = (ModalRoute.of(context)!.settings.arguments as String);
  }

  Future<void> _login() async {
    setState(() => busy = true);
    try {
      final r = await AuthApi.login(mobile: mobile, password: pass.text);
      if (r['success'] == true) {
        await _persistAndGoHome(r);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r['message']?.toString() ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _persistAndGoHome(Map<String, dynamic> r) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'token', value: r['token'] as String? ?? '');
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // (minor: creating a controller in build is okay for read-only, but you can also use initialValue)
    final mobileController = TextEditingController(text: mobile);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            enabled: false,
            controller: mobileController,
            decoration: const InputDecoration(
              labelText: 'Mobile',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pass,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : _login,
              child: Text(busy ? 'Logging in…' : 'Login'),
            ),
          ),
        ]),
      ),
    );
  }
}
