import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../services/device_monitor_service.dart';
import '../services/network_analyzer_service.dart';
import '../models/network_analysis.dart';
import 'device_list_screen.dart';
import 'network_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _zoneController;
  late AnimationController _packetController;
  
  final DeviceMonitorService _deviceMonitor = DeviceMonitorService();
  final NetworkAnalyzerService _analyzer = NetworkAnalyzerService();
  
  NetworkAnalysis? _analysis;
  bool _showVisuals = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _zoneController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _packetController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    
    _deviceMonitor.addListener(_onDeviceUpdate);
    _deviceMonitor.startMonitoring();
    _updateAnalysis();
  }

  void _onDeviceUpdate() {
    _updateAnalysis();
  }

  void _updateAnalysis() {
    if (!mounted) return;
    setState(() {
      _analysis = _analyzer.analyze(_deviceMonitor.devices);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _zoneController.dispose();
    _packetController.dispose();
    _deviceMonitor.removeListener(_onDeviceUpdate);
    _deviceMonitor.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis ?? NetworkAnalysis(
      totalDevices: 0,
      onlineDevices: 0,
      trustedDevices: 0,
      averageTrustScore: 100.0,
      activeThreats: 0,
      criticalThreats: 0,
      highThreats: 0,
      networkHealth: 100.0,
      safeZones: 0,
      infectedZones: 0,
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          
          return Stack(
            fit: StackFit.expand,
            children: [
              if (_showVisuals)
                Positioned.fill(
                  child: _buildNetworkMap(analysis),
                )
              else
                Container(color: const Color(0xFF0F1419)),
              
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sentinel Network',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (_deviceMonitor.networkInfo != null)
                                Text(
                                  'SSID: ${_deviceMonitor.networkInfo!.ssid}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.map),
                              color: Colors.white,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NetworkMapScreen(),
                                  ),
                                );
                              },
                            ),
                            if (!isSmallScreen) _buildThreatBadge(analysis.activeThreats),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              if (_deviceMonitor.isScanning) 
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: const LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent),
                ),

              Positioned.fill(
                top: 100,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: isSmallScreen
                      ? Column(
                          children: [
                            _buildThreatBadge(analysis.activeThreats),
                            const SizedBox(height: 20),
                            _buildNetworkStats(analysis),
                            const SizedBox(height: 20),
                            _buildAnalysisDashboard(analysis),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildNetworkStats(analysis)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildAnalysisDashboard(analysis)),
                          ],
                        ),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.95),
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.refresh,
                                label: _deviceMonitor.isScanning ? 'Scanning...' : 'Scan Network',
                                onTap: () async {
                                  if (!_deviceMonitor.isScanning) {
                                    await _deviceMonitor.refresh();
                                  }
                                },
                                color: Colors.deepPurple[600]!,
                                isPrimary: true,
                                isLoading: _deviceMonitor.isScanning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.devices,
                                label: 'View Devices (${analysis.totalDevices})',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DeviceListScreen(devices: _deviceMonitor.devices),
                                    ),
                                  );
                                },
                                color: Colors.grey[800]!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNetworkMap(NetworkAnalysis analysis) {
    return ListenableBuilder(
      listenable: Listenable.merge([_pulseController, _zoneController, _packetController]),
      builder: (context, child) {
        return CustomPaint(
          painter: NetworkMapPainter(
            pulseValue: _pulseController.value,
            zoneValue: _zoneController.value,
            packetValue: _packetController.value,
            safeZones: analysis.safeZones,
            infectedZones: analysis.infectedZones,
            deviceCount: analysis.totalDevices,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildThreatBadge(int threatCount) {
    if (threatCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, color: Colors.red[300], size: 20),
          const SizedBox(width: 8),
          Text(
            '$threatCount Threats',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisDashboard(NetworkAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Network Analysis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildAnalysisCard(
            icon: Icons.favorite,
            label: 'Network Health',
            value: '${analysis.networkHealth.toInt()}%',
            color: analysis.networkHealth > 80 ? Colors.green : 
                   analysis.networkHealth > 60 ? Colors.orange : Colors.red,
            progress: analysis.networkHealth / 100,
          ),
          const SizedBox(height: 16),
          
          _buildAnalysisCard(
            icon: Icons.device_hub,
            label: 'Total Devices',
            value: '${analysis.totalDevices}',
            color: Colors.blue,
            progress: null,
            subtitle: '${analysis.onlineDevices} online',
          ),
          const SizedBox(height: 16),
          
          _buildAnalysisCard(
            icon: Icons.verified,
            label: 'Trust Score',
            value: '${analysis.averageTrustScore.toInt()}%',
            color: Colors.purple,
            progress: analysis.averageTrustScore / 100,
            subtitle: '${analysis.trustedDevices} trusted',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.3);
  }

  Widget _buildNetworkStats(NetworkAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.network_check,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Network Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildStatRow(
            icon: Icons.wifi,
            label: 'Online Devices',
            value: '${analysis.onlineDevices}',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.shield,
            label: 'Trusted Devices',
            value: '${analysis.trustedDevices}',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.warning,
            label: 'Critical Threats',
            value: '${analysis.criticalThreats}',
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.radar,
                      color: _deviceMonitor.backgroundMonitoring ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Background Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _deviceMonitor.backgroundMonitoring,
                  onChanged: (value) {
                    _deviceMonitor.toggleBackgroundMonitoring(value);
                  },
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green.withOpacity(0.3),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3);
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    double? progress,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isPrimary ? color.withOpacity(0.5) : Colors.black26,
                blurRadius: isPrimary ? 20 : 10,
                spreadRadius: isPrimary ? 2 : 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleVpn() async {
    await _deviceMonitor.toggleVpn();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_deviceMonitor.isVpnActive 
              ? 'Firewall enabled - Your device is protected' 
              : 'Firewall disabled'),
          backgroundColor: _deviceMonitor.isVpnActive ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}

class NetworkMapPainter extends CustomPainter {
  final double pulseValue;
  final double zoneValue;
  final double packetValue;
  final int safeZones;
  final int infectedZones;
  final int deviceCount;

  NetworkMapPainter({
    required this.pulseValue,
    required this.zoneValue,
    required this.packetValue,
    required this.safeZones,
    required this.infectedZones,
    required this.deviceCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);
    
    final bgGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.5,
      colors: [
        const Color(0xFF0F1419),
        const Color(0xFF0A0E27),
        const Color(0xFF050710),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    paint.shader = bgGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.shader = null;
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.blue.withOpacity(0.1);
    paint.strokeWidth = 1.2;

    const int gridLines = 24;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * (i / gridLines);
      final path = Path();
      path.moveTo(0, y);
      
      for (double x = 0; x <= size.width; x += size.width / 40) {
        final dist = (x - center.dx).abs() / (size.width / 2);
        final distortion = math.sin(dist * math.pi) * 80 * (y < center.dy ? 1 : -1);
        path.lineTo(x, y + distortion * 0.3);
      }
      canvas.drawPath(path, paint);
      
      final x = size.width * (i / gridLines);
      final vPath = Path();
      vPath.moveTo(x, 0);
      for (double vy = 0; vy <= size.height; vy += size.height / 40) {
        final dist = (vy - center.dy).abs() / (size.height / 2);
        final distortion = math.sin(dist * math.pi) * 80 * (x < center.dx ? 1 : -1);
        vPath.lineTo(x + distortion * 0.3, vy);
      }
      canvas.drawPath(vPath, paint);
    }

    paint.style = PaintingStyle.fill;
    paint.color = Colors.blue.withOpacity(0.15);
    canvas.drawCircle(center, 60 + pulseValue * 15, paint);
    
    paint.color = Colors.blue.withOpacity(0.4);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(center, 60 + pulseValue * 15, paint);

    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawCircle(center, 6, paint);
    paint.color = Colors.blue[300]!;
    canvas.drawCircle(center, 12, paint);

    final random = math.Random(42);
    for (int i = 0; i < deviceCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi + (zoneValue * 0.2);
      final distance = 120 + random.nextDouble() * (math.min(size.width, size.height) / 2 - 140);
      
      final nodeX = center.dx + math.cos(angle) * distance;
      final nodeY = center.dy + math.sin(angle) * distance;
      final nodePos = Offset(nodeX, nodeY);

      paint.color = Colors.blue.withOpacity(0.15);
      paint.strokeWidth = 1;
      canvas.drawLine(center, nodePos, paint);

      final packetOffset = (packetValue + random.nextDouble()) % 1.0;
      final packetX = center.dx + (nodeX - center.dx) * packetOffset;
      final packetY = center.dy + (nodeY - center.dy) * packetOffset;
      
      paint.style = PaintingStyle.fill;
      paint.color = Colors.cyanAccent.withOpacity(0.8);
      canvas.drawCircle(Offset(packetX, packetY), 3, paint);

      final isInfected = i < infectedZones;
      paint.color = isInfected ? Colors.red : Colors.green;
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(nodePos, 5, paint);
      
      paint.style = PaintingStyle.stroke;
      paint.color = (isInfected ? Colors.red : Colors.green).withOpacity(0.5);
      paint.strokeWidth = 1.5;
      canvas.drawCircle(nodePos, 8 + (pulseValue * 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NetworkMapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
           oldDelegate.zoneValue != zoneValue ||
           oldDelegate.packetValue != packetValue ||
           oldDelegate.deviceCount != deviceCount;
  }
}
