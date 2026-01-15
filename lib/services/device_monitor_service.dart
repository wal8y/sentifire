import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/network_device.dart';
import 'network_service.dart';
import 'storage_service.dart';
import 'network_analyzer_service.dart';

class DeviceMonitorService extends ChangeNotifier {
  static final DeviceMonitorService _instance = DeviceMonitorService._internal();
  factory DeviceMonitorService() => _instance;

  final NetworkService _networkService = NetworkService();
  final NetworkAnalyzerService _analyzer = NetworkAnalyzerService();
  late StorageService _storageService;
  
  List<NetworkDevice> _devices = [];
  NetworkInfo? _networkInfo;
  bool _isMonitoring = false;
  bool _isScanning = false;
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _backgroundMonitoring = false;
  Timer? _backgroundTimer;

  bool get backgroundMonitoring => _backgroundMonitoring;
  List<NetworkDevice> get devices => _devices;
  NetworkInfo? get networkInfo => _networkInfo;
  bool get isMonitoring => _isMonitoring;
  bool get isScanning => _isScanning;
  bool get isVpnActive => false; // Real implementation removed as requested

  DeviceMonitorService._internal() {
    _initNotifications();
    _initStorage();
  }

  Future<bool> toggleVpn() async {
    return false;
  }

  Future<void> _initStorage() async {
    _storageService = await StorageService.init();
    _devices = _storageService.getKnownDevices();
    _backgroundMonitoring = _storageService.getBackgroundMonitoring();
    if (_backgroundMonitoring) {
        toggleBackgroundMonitoring(true);
    }
    notifyListeners();
  }

  void _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  Future<void> toggleBackgroundMonitoring(bool enable) async {
    if (_backgroundMonitoring == enable) return;
    _backgroundMonitoring = enable;
    await _storageService.setBackgroundMonitoring(enable);
    
    if (enable) {
      _backgroundTimer = Timer.periodic(const Duration(minutes: 15), (_) => refresh(isBackground: true));
      _showNotification('Monitoring Active', 'Background network scanning is enabled');
    } else {
      _backgroundTimer?.cancel();
      _backgroundTimer = null;
    }
    notifyListeners();
  }

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    refresh();
  }

  Future<void> refresh({bool isBackground = false}) async {
    if (_isScanning) return;
    _isScanning = true;
    notifyListeners();

    try {
      if (!await Permission.location.isGranted) {
        await Permission.location.request();
      }

      final info = await _networkService.getNetworkInfo();
      if (info != null) _networkInfo = info;

      final scannedDevices = await _networkService.getDiscoveredDevices();
      
      final knownDevices = _storageService.getKnownDevices();
      final Map<String, NetworkDevice> knownMap = { for (var d in knownDevices) d.ip : d };
      List<NetworkDevice> currentList = [];
      
      for (var scanned in scannedDevices) {
        if (knownMap.containsKey(scanned.ip)) {
           var existing = knownMap[scanned.ip]!;
           currentList.add(existing.copyWith(
             lastSeen: DateTime.now(),
             hostname: scanned.hostname,
             ports: scanned.ports,
           ));
           knownMap.remove(scanned.ip);
        } else {
           if (isBackground) {
             _showNotification('New Device Detected', '${scanned.hostname} (${scanned.ip}) joined the network');
           }
           currentList.add(scanned.copyWith(
             firstSeen: DateTime.now(),
             lastSeen: DateTime.now(),
             isTrusted: false,
             isBlocked: false,
           ));
        }
      }

      for (var offline in knownMap.values) {
        currentList.add(offline); 
      }

      final enrichedList = _analyzer.enrichDevices(currentList);
      
      for (var device in enrichedList) {
        if (device.isSuspicious) {
           final wasSuspicious = _devices.any((d) => d.ip == device.ip && d.isSuspicious);
           if (!wasSuspicious) {
             _showNotification('Security Alert', 'Suspicious activity on ${device.ip}: ${device.suspicionReason}');
           }
        }
      }
      
      enrichedList.sort((a, b) {
           final aOnline = DateTime.now().difference(a.lastSeen).inMinutes < 5;
           final bOnline = DateTime.now().difference(b.lastSeen).inMinutes < 5;
           if (aOnline && !bOnline) return -1;
           if (!aOnline && bOnline) return 1;
           return a.ip.compareTo(b.ip);
      });

      _devices = enrichedList;
      await _storageService.saveDevices(_devices);
      await _storageService.setLastScanTime(DateTime.now());

    } catch (e) {
      debugPrint('DeviceMonitorService: Error refreshing: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> toggleTrust(String ip) async {
    final index = _devices.indexWhere((d) => d.ip == ip);
    if (index != -1) {
      final device = _devices[index];
      final newTrust = !device.isTrusted;
      _devices[index] = device.copyWith(isTrusted: newTrust);
      notifyListeners();
      await _storageService.setDeviceTrust(ip, newTrust);
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'sentinel_channel', 
      'Sentinel Alerts',
      channelDescription: 'Network security alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(DateTime.now().millisecond, title, body, details);
  }
}
