import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/network_device.dart';

class StorageService {
  static const String _keyDevices = 'known_devices';
  static const String _keyBackgroundScan = 'background_scan_enabled';
  static const String _keyLastScanTime = 'last_scan_time';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }


  Future<void> setBackgroundMonitoring(bool enabled) async {
    await _prefs.setBool(_keyBackgroundScan, enabled);
  }

  bool getBackgroundMonitoring() {
    return _prefs.getBool(_keyBackgroundScan) ?? false;
  }

  Future<void> setLastScanTime(DateTime time) async {
    await _prefs.setString(_keyLastScanTime, time.toIso8601String());
  }

  DateTime? getLastScanTime() {
    final str = _prefs.getString(_keyLastScanTime);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  Future<void> saveDevices(List<NetworkDevice> currentDevices) async {
    final Map<String, dynamic> knownDevicesMap = _getKnownDevicesMap();

    for (var device in currentDevices) {
      final existingData = knownDevicesMap[device.ip];
      
      if (existingData != null) {
        final existingDevice = NetworkDevice.fromJson(existingData);
        
        final updatedDevice = device.copyWith(
          isTrusted: existingDevice.isTrusted,
          firstSeen: existingDevice.firstSeen ?? DateTime.now(),
          lastSeen: DateTime.now(),
        );
        
        knownDevicesMap[device.ip] = updatedDevice.toJson();
      } else {
        final newDevice = device.copyWith(
          firstSeen: DateTime.now(),
          lastSeen: DateTime.now(),
          isTrusted: false,
        );
        knownDevicesMap[device.ip] = newDevice.toJson();
      }
    }

    await _prefs.setString(_keyDevices, jsonEncode(knownDevicesMap));
  }
  
  Future<void> setDeviceTrust(String ip, bool isTrusted) async {
    final Map<String, dynamic> knownDevicesMap = _getKnownDevicesMap();
    
    if (knownDevicesMap.containsKey(ip)) {
      final deviceJson = knownDevicesMap[ip];
      final device = NetworkDevice.fromJson(deviceJson);
      
      final updatedDevice = device.copyWith(isTrusted: isTrusted);
      knownDevicesMap[ip] = updatedDevice.toJson();
      
      await _prefs.setString(_keyDevices, jsonEncode(knownDevicesMap));
    }
  }

  List<NetworkDevice> getKnownDevices() {
    final Map<String, dynamic> map = _getKnownDevicesMap();
    return map.values.map((json) => NetworkDevice.fromJson(json)).toList();
  }

  Map<String, dynamic> _getKnownDevicesMap() {
    final String? jsonStr = _prefs.getString(_keyDevices);
    if (jsonStr == null) return {};
    return Map<String, dynamic>.from(jsonDecode(jsonStr));
  }
}
