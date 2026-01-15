import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/network_device.dart';
import '../services/network_service.dart';
import '../services/device_monitor_service.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final NetworkDevice device;

  const DeviceDetailsScreen({super.key, required this.device});

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  final NetworkService _networkService = NetworkService();
  final DeviceMonitorService _monitorService = DeviceMonitorService();
  
  bool _isTrusted = false;
  bool _isScanningPorts = false;
  List<int>? _openPorts;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _monitorService.addListener(_checkStatus);
  }
  
  void _checkStatus() {
    if (!mounted) return;
    final latestDevice = _monitorService.devices.firstWhere(
      (d) => d.ip == widget.device.ip, 
      orElse: () => widget.device
    );
    
    setState(() {
      _isTrusted = latestDevice.isTrusted;
    });
  }

  @override
  void dispose() {
    _monitorService.removeListener(_checkStatus);
    super.dispose();
  }

  void _toggleTrust() {
    _monitorService.toggleTrust(widget.device.ip);
  }

  Future<void> _scanPorts() async {
    setState(() {
      _isScanningPorts = true;
      _openPorts = null;
    });

    final ports = await _networkService.scanPorts(widget.device.ip);

    if (mounted) {
      setState(() {
        _isScanningPorts = false;
        _openPorts = ports;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final themeColor = _isTrusted ? Colors.green : Colors.amber;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: Text(device.hostname),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isTrusted 
                          ? [Colors.green.shade900, Colors.green.shade800]
                          : [const Color(0xFFF57C00), const Color(0xFFE65100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: (_isTrusted ? Colors.green : Colors.orange).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.2),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(
                       _getDeviceIcon(device.type),
                       size: 48,
                       color: Colors.white,
                     ),
                   ),
                   const SizedBox(height: 20),
                   Text(
                     device.ipAddress,
                     style: const TextStyle(
                       color: Colors.white,
                       fontSize: 28,
                       fontWeight: FontWeight.bold,
                       letterSpacing: 1,
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     device.hostname,
                     style: TextStyle(
                       color: Colors.white.withOpacity(0.9),
                       fontSize: 16,
                       fontWeight: FontWeight.w500,
                     ),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 24),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.black.withOpacity(0.25),
                       borderRadius: BorderRadius.circular(30),
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(
                           _isTrusted ? Icons.check_circle : Icons.warning_amber_rounded,
                           color: Colors.white,
                           size: 18,
                         ),
                         const SizedBox(width: 8),
                         Text(
                           _isTrusted ? 'TRUSTED DEVICE' : 'DEVICE',
                           style: const TextStyle(
                             color: Colors.white,
                             fontWeight: FontWeight.bold,
                             fontSize: 12,
                             letterSpacing: 1.2,
                           ),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ).animate().fadeIn().scale(),

            if (device.isSuspicious) ...[
                const SizedBox(height: 24),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                        children: [
                            const Icon(Icons.gpp_bad, color: Colors.redAccent, size: 36),
                            const SizedBox(width: 16),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Text(
                                      'SECURITY ALERT', 
                                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13)
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      device.suspicionReason ?? "Suspicious network pattern detected.", 
                                      style: const TextStyle(color: Colors.white, fontSize: 14)
                                    ),
                                ],
                            )),
                        ],
                    ),
                ).animate().shake(hz: 4, curve: Curves.easeInOut),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleTrust,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2732),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                        color: _isTrusted ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                        width: 1,
                    )
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isTrusted ? 'MARK AS UNTRUSTED' : 'MARK AS TRUSTED',
                  style: TextStyle(
                    color: _isTrusted ? Colors.redAccent : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Security Status', 
                    device.isSuspicious ? 'At Risk' : 'Secure', 
                    device.isSuspicious ? Icons.security_update_warning : Icons.verified_user,
                    device.isSuspicious ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Ports Found', 
                    _openPorts?.length.toString() ?? device.ports.length.toString(), 
                    Icons.radar, 
                    Colors.purpleAccent,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2732),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                    _buildDetailRow('IP Address', device.ip, true),
                    const Divider(height: 1, color: Colors.white10),
                    _buildDetailRow('Hostname', device.hostname.isEmpty ? 'Unknown' : device.hostname, false),
                    const Divider(height: 1, color: Colors.white10),
                    _buildDetailRow('First Detected', _formatDate(device.firstSeen), false),
                    const Divider(height: 1, color: Colors.white10),
                    _buildDetailRow('Last Activity', _formatDate(device.lastSeen), false),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
             SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isScanningPorts ? null : _scanPorts,
                icon: _isScanningPorts 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.radar),
                label: Text(_isScanningPorts ? 'SCANNING PORTS...' : 'SCAN DEVICE PORTS'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
            
            if (_openPorts != null && _openPorts!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                    spacing: 8,
                    children: _openPorts!.map((p) => Chip(
                        label: Text(p.toString()), 
                        backgroundColor: Colors.purple.withOpacity(0.2),
                        labelStyle: const TextStyle(color: Colors.purpleAccent),
                    )).toList(),
                )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2732),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isFirst) {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5))),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
        ),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.hour}:${dt.minute.toString().padLeft(2,'0')} ${dt.day}/${dt.month}";
  }
  
  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return Icons.smartphone;
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.router:
        return Icons.router;
      case DeviceType.iot:
        return Icons.smart_toy;
      default:
        return Icons.devices_other;
    }
  }
}
