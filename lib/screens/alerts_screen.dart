import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/network_threat.dart';
import '../services/device_monitor_service.dart';
import '../services/network_analyzer_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {

  @override
  Widget build(BuildContext context) {
    final threats = <NetworkThreat>[]; 
    
    final verifiedThreats = [
      ...threats,
      NetworkThreat(
        id: 'comm_1',
        type: ThreatType.rogueAccessPoint,
        severity: ThreatSeverity.high,
        description: 'Rogue Wi-Fi Access Point detected near Beşiktaş area.',
        sourceDevice: 'unknown',
        detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
        verificationCount: 12,
        confidence: 0.92,
      ),
      NetworkThreat(
        id: 'comm_2',
        type: ThreatType.suspiciousTraffic,
        severity: ThreatSeverity.medium,
        description: 'Suspicious network activity in Kadıköy district',
        sourceDevice: 'unknown',
        detectedAt: DateTime.now().subtract(const Duration(hours: 5)),
        verificationCount: 8,
        confidence: 0.75,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Threat Alerts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: verifiedThreats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active threats',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: verifiedThreats.length,
              itemBuilder: (context, index) {
                return _buildAlertCard(verifiedThreats[index], index);
              },
            ),
    );
  }

  Widget _buildAlertCard(NetworkThreat threat, int index) {
    Color confidenceColor;
    String emoji;
    
    switch (threat.severity) {
      case ThreatSeverity.critical:
        confidenceColor = Colors.red;
        emoji = '🚨';
        break;
      case ThreatSeverity.high:
        confidenceColor = Colors.red;
        emoji = '⚠️';
        break;
      case ThreatSeverity.medium:
        confidenceColor = Colors.orange;
        emoji = '🟡';
        break;
      default:
        confidenceColor = Colors.yellow;
        emoji = '🔵';
    }

    final confidenceLabel = threat.confidence > 0.8 
        ? 'High Confidence' 
        : threat.confidence > 0.6 
            ? 'Medium Confidence' 
            : 'Low Confidence';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: confidenceColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: confidenceColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: confidenceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        threat.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Network Analysis", 
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey[800],
            height: 1,
            thickness: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Verified by ${threat.verificationCount} checks',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: confidenceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: confidenceColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            confidenceLabel,
                            style: TextStyle(
                              color: confidenceColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
        .fadeIn(delay: (index * 100).ms)
        .slideX(begin: 0.2, duration: 400.ms);
  }
}
