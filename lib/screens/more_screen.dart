import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            onTap: () {
              // Navigator.push to AboutScreen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms & Conditions'),
            onTap: () {
              // Navigator.push to TermsAndConditionsScreen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Refund Policy'),
            onTap: () {
              // Navigator.push to RefundPolicyScreen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shopping_cart_checkout),
            title: const Text('How to Buy Tickets'),
            onTap: () {
              // Navigator.push to HowToBuyScreen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('FAQ'),
            onTap: () {
              // Navigator.push to FaqScreen
            },
          ),
        ],
      ),
    );
  }
}
