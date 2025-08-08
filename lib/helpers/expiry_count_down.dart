import 'dart:async';

import 'package:flutter/material.dart';

class ExpiryCountdown extends StatefulWidget {
  final String expiresAtIso; // item['expires_at']
  const ExpiryCountdown({super.key, required this.expiresAtIso});

  @override
  State<ExpiryCountdown> createState() => _ExpiryCountdownState();
}

class _ExpiryCountdownState extends State<ExpiryCountdown> {
  late Timer _t;
  late DateTime _expires;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _expires = DateTime.parse(widget.expiresAtIso).toUtc();
    _tick();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now().toUtc();
    setState(() => _left = _expires.isAfter(now) ? _expires.difference(now) : Duration.zero);
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text('Expires in $m:$s', style: const TextStyle(fontSize: 12, color: Colors.red));
  }
}
