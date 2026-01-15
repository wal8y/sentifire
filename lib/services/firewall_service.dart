import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FirewallService extends ChangeNotifier {
  static const platform = MethodChannel('com.example.sentifire/firewall');
  
  final Set<String> _blockedIps = {};
  bool _isVpnActive = false;

  bool get isVpnActive => _isVpnActive;
  Set<String> get blockedIps => Set.unmodifiable(_blockedIps);

  bool isDeviceBlocked(String ip) {
    return _blockedIps.contains(ip);
  }

  Future<void> startVpn() async {
    try {
      await platform.invokeMethod('startVpn');
      _isVpnActive = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting VPN: $e');
    }
  }

  Future<void> stopVpn() async {
    try {
      await platform.invokeMethod('stopVpn');
      _isVpnActive = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping VPN: $e');
    }
  }

  Future<void> blockDevice(String ip) async {
    try {
      await platform.invokeMethod('blockIp', {'ip': ip});
      _blockedIps.add(ip);
      notifyListeners();
    } catch (e) {
      debugPrint('Error blocking device: $e');
    }
  }

  Future<void> unblockDevice(String ip) async {
    try {
      await platform.invokeMethod('unblockIp', {'ip': ip});
      _blockedIps.remove(ip);
      notifyListeners();
    } catch (e) {
      debugPrint('Error unblocking device: $e');
    }
  }
}
