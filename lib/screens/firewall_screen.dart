import 'package:flutter/material.dart';

class FirewallScreen extends StatelessWidget {
  const FirewallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firewall'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Firewall feature coming soon',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
