import 'package:flutter/material.dart';
import '../../services/auth_api.dart';

class CheckMobileScreen extends StatefulWidget {
  const CheckMobileScreen({super.key});

  @override
  State<CheckMobileScreen> createState() => _CheckMobileScreenState();
}

class _CheckMobileScreenState extends State<CheckMobileScreen> {
  final c = TextEditingController();
  bool busy = false;

  String normalize(String v) {
    v = v.replaceAll(RegExp(r'\D'), '');
    return v;
  }

  Future<void> _next() async {
    setState(() => busy = true);
    try {
      final mobile = normalize(c.text);
      final data = await AuthApi.checkStep(mobile);
      if (!mounted) return;
      if(data['status']) {
        if (data['step'] == 'login') {
          Navigator.pushNamed(context, '/auth/login', arguments: mobile);
        } else {
          Navigator.pushNamed(context, '/auth/register', arguments: mobile);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$data['message']")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min, // shrink vertically to content
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 32,
                  child: Text(
                    'Enter your mobile number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18, // adjust as needed
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextField(
                  controller: c,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: busy ? null : _next,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(busy ? 'Checking…' : 'Check'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
