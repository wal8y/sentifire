import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/community_map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/firewall_screen.dart';
import 'services/network_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentinel Network',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        primaryColor: const Color(0xFF1E1E2E),
      ),
      home: const VpnPermissionGate(),
      routes: {
        '/scan': (context) => const ScanScreen(),
        '/alerts': (context) => const AlertsScreen(),
        '/community': (context) => const CommunityMapScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/firewall': (context) => const FirewallScreen(),
      },
    );
  }
}

class VpnPermissionGate extends StatefulWidget {
  const VpnPermissionGate({super.key});

  @override
  State<VpnPermissionGate> createState() => _VpnPermissionGateState();
}

class _VpnPermissionGateState extends State<VpnPermissionGate> {
  final NetworkService _networkService = NetworkService();
  bool _hasPermission = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await _networkService.requestVpnPermission();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _isChecking = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isChecking = true);
    final granted = await _networkService.requestVpnPermission();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _isChecking = false;
      });
      
      if (granted) {
        await _networkService.startVpn();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasPermission) {
      return const HomeScreen();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E21), Color(0xFF1E1E2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield,
                  size: 120,
                  color: Colors.blue[400],
                ),
                const SizedBox(height: 32),
                const Text(
                  'VPN Permission Required',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sentinel Firewall needs VPN permission to protect your device from network threats.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Grant VPN Permission',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[400]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This permission allows the app to filter network traffic and block threats.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
