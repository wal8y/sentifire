import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../services/device_monitor_service.dart';
import '../models/network_analysis.dart';

class NetworkMapScreen extends StatefulWidget {
  const NetworkMapScreen({super.key});

  @override
  State<NetworkMapScreen> createState() => _NetworkMapScreenState();
}

class _NetworkMapScreenState extends State<NetworkMapScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _zoneController;
  late AnimationController _packetController;
  
  // Assuming global or provided service in real app
  final DeviceMonitorService _deviceMonitor = DeviceMonitorService();
  
  // For interactivity (simple zoom/pan placeholder)
  double _scale = 1.0;
  Offset _offset = Offset.zero;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _zoneController.dispose();
    _packetController.dispose();
    // Don't dispose _deviceMonitor here if shared, but we created a local reference for this screen.
    // In a real app with Provider, we wouldn't dispose it here.
    // We'll assume it's shared/singleton logic or safe to ignore for now.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = _deviceMonitor.devices;
    final deviceCount = devices.length;
    // Simple logic for safe/infected based on blocked status for visualization
    final safeZones = devices.where((d) => !d.isBlocked).length;
    final infectedZones = devices.where((d) => d.isBlocked).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text('Network Map Visualization'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onScaleUpdate: (details) {
          setState(() {
            _scale = (_scale * details.scale).clamp(0.5, 3.0);
            _offset += details.focalPointDelta;
          });
        },
        child: ListenableBuilder(
          listenable: Listenable.merge([_pulseController, _zoneController, _packetController]),
          builder: (context, child) {
            return CustomPaint(
              painter: NetworkMapPainter(
                pulseValue: _pulseController.value,
                zoneValue: _zoneController.value,
                packetValue: _packetController.value,
                safeZones: safeZones,
                infectedZones: infectedZones,
                deviceCount: deviceCount > 0 ? deviceCount : 5, // Show at least 5 nodes for demo if empty
                offset: _offset,
                scale: _scale,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _scale = 1.0;
            _offset = Offset.zero;
          });
        },
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}

class NetworkMapPainter extends CustomPainter {
  final double pulseValue;
  final double zoneValue;
  final double packetValue;
  final int safeZones;
  final int infectedZones;
  final int deviceCount;
  final Offset offset;
  final double scale;

  NetworkMapPainter({
    required this.pulseValue,
    required this.zoneValue,
    required this.packetValue,
    required this.safeZones,
    required this.infectedZones,
    required this.deviceCount,
    this.offset = Offset.zero,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2) + offset;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    // 1. Background Gradient
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
    // We draw rect over entire possible canvas area accounting for offset/scale? 
    // Simpler to just draw background fixed and transform content.
    // But gradient needs to be screen relative usually.
    // Let's just fill the screen with solid color in build and draw grid here.
    
    // 2. Fisheye Grid Effect
    paint.shader = null;
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.blue.withOpacity(0.15); 
    paint.strokeWidth = 1.0 / scale; // Keep lines thin

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

    // 3. Central Hub
    paint.style = PaintingStyle.fill;
    paint.color = Colors.blue.withOpacity(0.2);
    canvas.drawCircle(center, 60 + pulseValue * 15, paint);
    
    paint.color = Colors.blue.withOpacity(0.5);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2 / scale;
    canvas.drawCircle(center, 60 + pulseValue * 15, paint);

    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawCircle(center, 6, paint);

    // 4. Nodes
    final random = math.Random(42);
    for (int i = 0; i < deviceCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi + (zoneValue * 0.2);
      final distance = 150 + random.nextDouble() * 150; // Spread out more
      
      final nodeX = center.dx + math.cos(angle) * distance;
      final nodeY = center.dy + math.sin(angle) * distance;
      final nodePos = Offset(nodeX, nodeY);

      // Connection Line
      paint.color = Colors.blue.withOpacity(0.2);
      paint.strokeWidth = 1 / scale;
      canvas.drawLine(center, nodePos, paint);

      // Packet
      final packetOffset = (packetValue + random.nextDouble()) % 1.0;
      final packetX = center.dx + (nodeX - center.dx) * packetOffset;
      final packetY = center.dy + (nodeY - center.dy) * packetOffset;
      
      paint.style = PaintingStyle.fill;
      paint.color = Colors.cyanAccent;
      canvas.drawCircle(Offset(packetX, packetY), 4 / scale, paint);

      // Node
      final isInfected = i < infectedZones;
      paint.color = isInfected ? Colors.red : Colors.green;
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(nodePos, 8 / scale, paint);
      
      // Label (Host/IP) - Simplified for map
      // In full impl, we'd pass device names
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant NetworkMapPainter oldDelegate) {
    return true; // Always repaint for animation
  }
}

