import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/network_device.dart';
import 'device_details_screen.dart';
import 'package:intl/intl.dart';

class DeviceListScreen extends StatelessWidget {
  final List<NetworkDevice> devices;

  const DeviceListScreen({
    super.key,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final alerts = devices.where((d) => 
        !d.isTrusted && 
        now.difference(d.firstSeen).inHours < 24 &&
        now.difference(d.lastSeen).inMinutes < 5
    ).toList();
    
    final trusted = devices.where((d) => d.isTrusted && now.difference(d.lastSeen).inMinutes < 5).toList();
    
    final others = devices.where((d) => 
        !d.isTrusted && 
        !alerts.contains(d) &&
        now.difference(d.lastSeen).inMinutes < 5
    ).toList();
    
    final offline = devices.where((d) => now.difference(d.lastSeen).inMinutes >= 5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Devices'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          if (alerts.isNotEmpty) ...[
            _buildSectionHeader(context, 'New & Alerts', Colors.redAccent),
            _buildDeviceList(context, alerts, isAlert: true),
          ],
          
          if (trusted.isNotEmpty) ...[
            _buildSectionHeader(context, 'Trusted Devices', Colors.greenAccent),
            _buildDeviceList(context, trusted, isTrusted: true),
          ],
          
          if (others.isNotEmpty) ...[
            _buildSectionHeader(context, 'Connected Devices', Colors.amber),
            _buildDeviceList(context, others),
          ],
          
          if (offline.isNotEmpty) ...[
            _buildSectionHeader(context, 'Device History (Offline)', Colors.grey),
            _buildDeviceList(context, offline, isOffline: true),
          ],
          
          if (devices.isEmpty)
             SliverFillRemaining(
               child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radar, size: 64, color: Colors.grey[800]),
                      const SizedBox(height: 16),
                      Text(
                        'No devices tracked yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Row(
          children: [
            Container(width: 4, height: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, List<NetworkDevice> list, {bool isAlert = false, bool isTrusted = false, bool isOffline = false}) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
            final device = list[index];
            return _buildDeviceCard(context, device, isAlert, isTrusted, isOffline);
        },
        childCount: list.length,
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, NetworkDevice device, bool isAlert, bool isTrusted, bool isOffline) {
    Color statusColor = Colors.amber;
    if (isAlert) statusColor = Colors.red;
    else if (isTrusted) statusColor = Colors.green;
    else if (isOffline) statusColor = Colors.grey;

    final dateFormat = DateFormat('MMM d, HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2732),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getDeviceIcon(device.type),
            color: statusColor,
            size: 24,
          ),
        ),
        title: Row(
            children: [
                Expanded(
                    child: Text(
                        device.ip,
                        style: TextStyle(
                            color: isOffline ? Colors.white54 : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                    ),
                ),
                if (isTrusted) 
                    const Icon(Icons.verified, size: 16, color: Colors.green),
            ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              isOffline 
                  ? 'Last seen: ${dateFormat.format(device.lastSeen)}'
                  : 'First seen: ${dateFormat.format(device.firstSeen)}',
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailsScreen(device: device),
            ),
          );
        },
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.mobile: return Icons.smartphone;
      case DeviceType.computer: return Icons.computer;
      case DeviceType.router: return Icons.router;
      case DeviceType.iot: return Icons.smart_toy;
      default: return Icons.devices_other;
    }
  }
}
