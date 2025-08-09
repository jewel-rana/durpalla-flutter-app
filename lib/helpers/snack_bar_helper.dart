import 'package:flutter/material.dart';

enum SnackKind { success, warning, error, info }

void showSnack(
    BuildContext context,
    String message, {
      SnackKind kind = SnackKind.info,
      Duration duration = const Duration(seconds: 3),
    }) {
  Color bg;
  IconData icon;

  if (kind == SnackKind.success) {
    bg = const Color(0xFF2E7D32); // green
    icon = Icons.check_circle_outline;
  } else if (kind == SnackKind.warning) {
    bg = const Color(0xFFFF8F00); // amber
    icon = Icons.warning_amber_outlined;
  } else if (kind == SnackKind.error) {
    bg = const Color(0xFFC62828); // red
    icon = Icons.error_outline;
  } else {
    bg = const Color(0xFF1565C0); // blue
    icon = Icons.info_outline;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: duration, // ✅ duration now works
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    ),
  );
}
