enum DeviceType {
  mobile,
  computer,
  router,
  iot,
  unknown,
}

class NetworkDevice {
  final String ip;
  final String hostname;
  final DeviceType type;
  final List<int> ports;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final bool isBlocked;
  final bool isTrusted;
  final bool isSuspicious;
  final String? suspicionReason;

  NetworkDevice({
    required this.ip,
    this.hostname = '',
    this.type = DeviceType.unknown,
    this.ports = const [],
    DateTime? firstSeen,
    DateTime? lastSeen,
    this.isBlocked = false,
    this.isTrusted = false,
    this.isSuspicious = false,
    this.suspicionReason,
  })  : firstSeen = firstSeen ?? DateTime.now(),
        lastSeen = lastSeen ?? DateTime.now();

  String get ipAddress => ip;

  DeviceType inferType() {
    if (hostname.toLowerCase().contains('android') ||
        hostname.toLowerCase().contains('iphone') ||
        hostname.toLowerCase().contains('samsung') ||
        hostname.toLowerCase().contains('xiaomi')) {
      return DeviceType.mobile;
    }
    if (hostname.toLowerCase().contains('router') ||
        hostname.toLowerCase().contains('gateway')) {
      return DeviceType.router;
    }
    if (hostname.toLowerCase().contains('pc') ||
        hostname.toLowerCase().contains('laptop') ||
        hostname.toLowerCase().contains('desktop')) {
      return DeviceType.computer;
    }
    if (ports.any((p) => [80, 443, 8080].contains(p))) {
      return DeviceType.iot;
    }
    return DeviceType.unknown;
  }

  NetworkDevice copyWith({
    String? ip,
    String? hostname,
    DeviceType? type,
    List<int>? ports,
    DateTime? firstSeen,
    DateTime? lastSeen,
    bool? isBlocked,
    bool? isTrusted,
    bool? isSuspicious,
    String? suspicionReason,
  }) {
    return NetworkDevice(
      ip: ip ?? this.ip,
      hostname: hostname ?? this.hostname,
      type: type ?? this.type,
      ports: ports ?? this.ports,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      isBlocked: isBlocked ?? this.isBlocked,
      isTrusted: isTrusted ?? this.isTrusted,
      isSuspicious: isSuspicious ?? this.isSuspicious,
      suspicionReason: suspicionReason ?? this.suspicionReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'hostname': hostname,
      'type': type.toString().split('.').last,
      'ports': ports,
      'firstSeen': firstSeen.millisecondsSinceEpoch,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'isBlocked': isBlocked,
      'isTrusted': isTrusted,
      'isSuspicious': isSuspicious,
      'suspicionReason': suspicionReason,
    };
  }

  factory NetworkDevice.fromJson(Map<String, dynamic> json) {
    return NetworkDevice(
      ip: json['ip'] as String,
      hostname: json['hostname'] as String? ?? '',
      type: DeviceType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DeviceType.unknown,
      ),
      ports: (json['ports'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      firstSeen: json['firstSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['firstSeen'] as int)
          : DateTime.now(),
      lastSeen: json['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int)
          : DateTime.now(),
      isBlocked: json['isBlocked'] as bool? ?? false,
      isTrusted: json['isTrusted'] as bool? ?? false,
      isSuspicious: json['isSuspicious'] as bool? ?? false,
      suspicionReason: json['suspicionReason'] as String?,
    );
  }
}
