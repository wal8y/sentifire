class NetworkAnalysis {
  final int totalDevices;
  final int onlineDevices;
  final int trustedDevices;
  final double averageTrustScore;
  final int activeThreats;
  final int criticalThreats;
  final int highThreats;
  final double networkHealth;
  final int safeZones;
  final int infectedZones;

  NetworkAnalysis({
    required this.totalDevices,
    required this.onlineDevices,
    required this.trustedDevices,
    required this.averageTrustScore,
    required this.activeThreats,
    required this.criticalThreats,
    required this.highThreats,
    required this.networkHealth,
    required this.safeZones,
    required this.infectedZones,
  });
}

