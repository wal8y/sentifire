class NetworkScan {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final ScanStatus status;
  final int totalDevicesFound;
  final int threatsDetected;
  final List<String> deviceIds;
  final List<String> threatIds;
  final Map<String, dynamic> scanResults;

  NetworkScan({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.status,
    this.totalDevicesFound = 0,
    this.threatsDetected = 0,
    this.deviceIds = const [],
    this.threatIds = const [],
    this.scanResults = const {},
  });

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  bool get isComplete => status == ScanStatus.completed;
}

enum ScanStatus {
  pending,
  scanning,
  completed,
  failed,
  cancelled,
}

