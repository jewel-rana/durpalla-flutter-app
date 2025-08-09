import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/auth_api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState(); // <-- required
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final String mobile;
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final otp  = TextEditingController();
  final nid  = TextEditingController(); // optional if you collect it
  bool busy = false;

  @override void didChangeDependencies() {
    super.didChangeDependencies();
    mobile = (ModalRoute.of(context)!.settings.arguments as String);
  }

  Future<void> _register() async {
    setState(() => busy = true);
    try {
      final r = await AuthApi.register(
        name: name.text.trim(),
        email: email.text.trim(),
        mobile: mobile,
        password: pass.text,
        otpCode: otp.text,
        nid: nid.text.isEmpty ? null : nid.text,
      );
      if (r['success'] == true) {
        await _persistAndGoHome(r);
      } else {
        // handle error
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _persistAndGoHome(Map<String, dynamic> r) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'token', value: r['token'] as String? ?? '');
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }


  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create account')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(enabled: false, controller: TextEditingController(text: mobile),
            decoration: const InputDecoration(labelText: 'Mobile', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: pass, obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: otp, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'OTP code', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: nid,
            decoration: const InputDecoration(labelText: 'NID (optional)', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: busy ? null : _register, child: Text(busy ? 'Creating…' : 'Register'),
        )),
      ],
    ),
  );
}
