class NetworkThreat {
  final String id;
  final ThreatType type;
  final ThreatSeverity severity;
  final String description;
  final String sourceDevice;
  final String? targetDevice;
  final DateTime detectedAt;
  final DateTime? resolvedAt;
  final Map<String, dynamic> metadata;
  final int verificationCount;
  final double confidence;

  NetworkThreat({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.sourceDevice,
    this.targetDevice,
    required this.detectedAt,
    this.resolvedAt,
    this.metadata = const {},
    this.verificationCount = 0,
    this.confidence = 0.0,
  });

  bool get isActive => resolvedAt == null;
  bool get isVerified => verificationCount >= 3;
}

enum ThreatType {
  arpSpoofing,
  dnsHijacking,
  rogueAccessPoint,
  manInTheMiddle,
  portScanning,
  suspiciousTraffic,
  unknownDevice,
  unauthorizedAccess,
}

enum ThreatSeverity {
  low,
  medium,
  high,
  critical,
}

