import '../models/network_device.dart';
import '../models/network_threat.dart';
import '../models/network_analysis.dart';

class NetworkAnalyzerService {
  NetworkAnalysis analyze(List<NetworkDevice> devices) {
    final threats = _detectThreats(devices);
    
    final now = DateTime.now();
    final onlineDevices = devices.where((d) => now.difference(d.lastSeen).inMinutes < 5).length;
    final trustedDevices = devices.where((d) => d.isTrusted).length;
    
    final avgTrustScore = devices.isEmpty 
        ? 100.0 
        : devices.fold(0.0, (sum, d) => sum + _calculateDeviceScore(d)) / devices.length;
    
    final criticalThreats = threats.where((t) => t.severity == ThreatSeverity.critical).length;
    final highThreats = threats.where((t) => t.severity == ThreatSeverity.high).length;
    
    final networkHealth = _calculateNetworkHealth(
      devices.length,
      threats.length,
      avgTrustScore,
      trustedDevices,
    );
    
    return NetworkAnalysis(
      totalDevices: devices.length,
      onlineDevices: onlineDevices,
      trustedDevices: trustedDevices,
      averageTrustScore: avgTrustScore,
      activeThreats: threats.length,
      criticalThreats: criticalThreats,
      highThreats: highThreats,
      networkHealth: networkHealth,
      safeZones: _calculateSafeZones(devices),
      infectedZones: _calculateInfectedZones(threats),
    );
  }

  double _calculateDeviceScore(NetworkDevice device) {
    double score = 100.0;
    if (device.isBlocked) score -= 50;
    if (!device.isTrusted) score -= 20;
    if (device.ports.contains(23)) score -= 30;
    return score.clamp(0.0, 100.0);
  }

  List<NetworkThreat> _detectThreats(List<NetworkDevice> devices) {
    final threats = <NetworkThreat>[];
    
    final insecurePorts = {21, 23, 445, 3389, 5900};
    final suspiciousKeywords = {'kali', 'backtrack', 'pentest', 'scanner', 'exploit'};

    for (var device in devices) {
      // 1. Insecure Ports
      final foundInsecure = device.ports.where((p) => insecurePorts.contains(p)).toList();
      if (foundInsecure.isNotEmpty) {
        threats.add(NetworkThreat(
          id: 'threat_${device.ip}_ports',
          type: ThreatType.unknownDevice,
          severity: ThreatSeverity.high,
          description: 'Insecure ports (${foundInsecure.join(", ")}) open on ${device.ip}',
          sourceDevice: device.ip,
          detectedAt: DateTime.now(),
          verificationCount: 1,
          confidence: 1.0,
        ));
      }
      
      // 2. Suspicious Hostnames
      if (suspiciousKeywords.any((k) => device.hostname.toLowerCase().contains(k))) {
        threats.add(NetworkThreat(
          id: 'threat_${device.ip}_name',
          type: ThreatType.suspiciousTraffic,
          severity: ThreatSeverity.critical,
          description: 'Host identified as potential audit tool: ${device.hostname}',
          sourceDevice: device.ip,
          detectedAt: DateTime.now(),
          verificationCount: 1,
          confidence: 0.9,
        ));
      }

      // 3. New Unknown Device (within last 30 mins)
      if (!device.isTrusted && !device.isBlocked && 
          DateTime.now().difference(device.firstSeen).inMinutes < 30) {
          // This is a "New Device" alert
      }
    }
    return threats;
  }
  
  // Method to enrich local device list with suspicion flags
  List<NetworkDevice> enrichDevices(List<NetworkDevice> devices) {
    final threats = _detectThreats(devices);
    return devices.map((d) {
      final deviceThreats = threats.where((t) => t.sourceDevice == d.ip).toList();
      if (deviceThreats.isNotEmpty) {
        return d.copyWith(
          isSuspicious: true,
          suspicionReason: deviceThreats.first.description,
        );
      }
      return d;
    }).toList();
  }

  double _calculateNetworkHealth(
    int deviceCount,
    int threatCount,
    double avgTrustScore,
    int trustedCount,
  ) {
    if (deviceCount == 0) return 100.0;
    
    double baseHealth = 100.0;
    
    final threatPenalty = (threatCount * 10.0).clamp(0.0, 40.0);
    baseHealth -= threatPenalty;
    
    final trustRatio = trustedCount / deviceCount;
    final trustBonus = trustRatio * 20.0;
    baseHealth = (baseHealth * 0.8) + trustBonus;
    
    final scoreContribution = avgTrustScore * 0.2;
    baseHealth = (baseHealth * 0.8) + scoreContribution;
    
    return baseHealth.clamp(0.0, 100.0);
  }

  int _calculateSafeZones(List<NetworkDevice> devices) {
    return devices.where((d) => d.isTrusted && !d.isBlocked).length;
  }

  int _calculateInfectedZones(List<NetworkThreat> threats) {
    return threats.length;
  }
}
