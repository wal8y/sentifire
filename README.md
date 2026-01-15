# Sentinel Firewall

Sentinel Firewall is a Flutter-based network security application that monitors network traffic, detects threats, and manages device connections using a local VPN service on Android.

## Architecture

The project has been restructured to remove the Rust backend and use native Android APIs directly via Flutter Platform Channels.

### Components

1.  **Android Backend (`android/app/src/main/kotlin/com/example/sentifire/`)**:
    *   `NetworkScanner.kt`: Scans the local network for devices (ARP/Ping).
    *   `PacketAnalyzer.kt`: Analyzes network packets for threats and traffic stats.
    *   `FirewallVpnService.kt`: Implementation of Android `VpnService` to intercept and filter traffic.
    *   `MainActivity.kt`: Handles MethodChannel communication between Flutter and Android.

2.  **Flutter Frontend (`lib/`)**:
    *   `services/NetworkService`: Communicates with Android native code.
    *   `services/DeviceMonitorService`: Manages device state and polling.
    *   `services/NetworkAnalyzerService`: Analyzes device data for threats.
    *   `models/`: Data models for Devices, Threats, and Analysis.
    *   `screens/`: UI components (Home, Scan, Alerts, Firewall).

## Features

*   **Network Scanning**: Discovers devices on your Wi-Fi network.
*   **Threat Detection**: Identifies suspicious activities like ARP Spoofing or Rogue APs.
*   **Firewall**: Blocks internet access for specific devices (simulated via local VPN sinkhole).
*   **Traffic Monitoring**: Real-time stats on data usage.

## Setup

1.  Open the project in Android Studio or VS Code.
2.  Run `flutter pub get`.
3.  Run on an Android device (Physical device recommended for VPN features).
    *   `flutter run`

## Permissions

The app requires `VPN` permission to function as a firewall. You will be prompted to grant this permission on first launch.

