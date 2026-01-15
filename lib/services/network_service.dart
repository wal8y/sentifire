import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/network_device.dart';

class NetworkInfo {
  final String ssid;
  final String gatewayIp;
  final String ownIp;
  final String subnetMask;
  final List<String> dnsServers;
  final String connectionType;
  final bool isConnected;

  NetworkInfo({
    required this.ssid,
    required this.gatewayIp,
    required this.ownIp,
    required this.subnetMask,
    required this.dnsServers,
    required this.connectionType,
    required this.isConnected,
  });

  factory NetworkInfo.fromJson(Map<String, dynamic> json) {
    final dnsList = json['dnsServers'] as List?;
    return NetworkInfo(
      ssid: json['ssid'] ?? 'Unknown',
      gatewayIp: json['gatewayIp'] ?? '0.0.0.0',
      ownIp: json['ownIp'] ?? '0.0.0.0',
      subnetMask: json['subnetMask'] ?? '0.0.0.0',
      dnsServers: dnsList?.map((e) => e.toString()).toList() ?? [],
      connectionType: json['connectionType'] ?? 'Unknown',
      isConnected: json['isConnected'] ?? false,
    );
  }
}

class NetworkService {
  static const _platform = MethodChannel('com.example.sentifire/network');
  static const _vpnPlatform = MethodChannel('com.example.sentifire/vpn');

  Future<NetworkInfo?> getNetworkInfo() async {
    try {
      final String result = await _platform.invokeMethod('getNetworkInfo');
      final json = jsonDecode(result) as Map<String, dynamic>;
      return NetworkInfo.fromJson(json);
    } catch (e) {
      print('NetworkService: Error getting network info: $e');
      return null;
    }
  }

  Future<List<NetworkDevice>> getDiscoveredDevices() async {
    try {
      final String result = await _platform.invokeMethod('getDiscoveredDevices');
      final List<dynamic> jsonList = jsonDecode(result);
      
      return jsonList.map((json) {
         final ports = (json['open_ports'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [];
         return NetworkDevice(
           ip: json['ip'] ?? 'Unknown',
           hostname: json['hostname'] ?? 'Unknown',
           ports: ports,
           firstSeen: DateTime.now(),
           lastSeen: DateTime.now(),
           isBlocked: false,
         );
      }).toList();
    } catch (e) {
      print('NetworkService: Error getting devices: $e');
      return [];
    }
  }
  
  Future<List<int>> scanPorts(String ip) async {
    try {
      final List<dynamic> ports = await _platform.invokeMethod('scanPorts', {'ip': ip});
      return ports.cast<int>();
    } catch (e) {
      print('NetworkService: Error scanning ports: $e');
      return [];
    }
  }

  Future<bool> isConnected() async {
    try {
      return await _platform.invokeMethod('isConnected');
    } catch (e) {
      print('NetworkService: Error checking connection: $e');
      return false;
    }
  }

  // VPN/Firewall Control
  Future<bool> requestVpnPermission() async {
    try {
      return await _vpnPlatform.invokeMethod('requestPermission');
    } catch (e) {
      print('NetworkService: Error requesting VPN permission: $e');
      return false;
    }
  }

  Future<bool> startVpn() async {
    try {
      return await _vpnPlatform.invokeMethod('start');
    } catch (e) {
      print('NetworkService: Error starting VPN: $e');
      return false;
    }
  }

  Future<bool> stopVpn() async {
    try {
      return await _vpnPlatform.invokeMethod('stop');
    } catch (e) {
      print('NetworkService: Error stopping VPN: $e');
      return false;
    }
  }

  Future<bool> blockIp(String ip) async {
    try {
      return await _vpnPlatform.invokeMethod('blockIp', {'ip': ip});
    } catch (e) {
      print('NetworkService: Error blocking IP: $e');
      return false;
    }
  }

  Future<bool> unblockIp(String ip) async {
    try {
      return await _vpnPlatform.invokeMethod('unblockIp', {'ip': ip});
    } catch (e) {
      print('NetworkService: Error unblocking IP: $e');
      return false;
    }
  }
}
