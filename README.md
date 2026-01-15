# 🛡️ Sentifire (Sentinel Network)

**Sentifire** is a premium, high-performance network security application built with Flutter. It provides real-time threat intelligence, device monitoring, and network visualization with a sleek, modern aesthetic.

![Sentifire Banner](https://raw.githubusercontent.com/wal8y/sentifire/main/web/favicon.png)

## ✨ Core Features

### 📡 Real-Time Network Analysis
- **Live Dashboard**: Monitor your network health at a glance with high-fidelity visuals.
- **Sentinel Map**: A dynamic, animated fisheye grid visualizing your network topology, including **Safe Zones** and **Infected Zones**.
- **Trust Scoring**: Every device on your network is assigned a dynamic "Trust Score" based on its behavior and configuration.

### 🛡️ Threat Intelligence
- **Intelligent Detection**: Automatically flags devices with insecure ports (e.g., 21, 23, 445, 3389) or suspicious hostnames associated with audit tools (e.g., Kali, Backtrack).
- **Severity Levels**: Threats are categorized from **Critical** to **Low**, helping you prioritize security responses.
- **Device Enrichment**: Adds context to unknown devices, identifying potential risks before they become issues.

### 🔌 Advanced Device Monitoring
- **Discovery Engine**: Rapidly scans your local network to discover all connected devices.
- **Status Tracking**: Keep track of online/offline status, IP addresses, and first/last seen timestamps.
- **Management**: Mark devices as "Trusted" or block them from your network view.

### ⚙️ Security Infrastructure
- **Firewall Integration**: Toggle a VPN-based on-device firewall to protect your traffic.
- **Background Protection**: Uses **Workmanager** to perform periodic background scans, ensuring you're protected even when the app is closed.
- **Smart Notifications**: Integrated with **Flutter Local Notifications** for real-time security alerts.

## 🎨 Design Philosophy
Sentifire is designed with a "Cyber-Security Premium" aesthetic:
- **Glassmorphism**: Elegant transparent cards and overlays.
- **Rich Animations**: Powered by `flutter_animate` for a responsive, alive interface.
- **Dark Mode Native**: Optimized for high-contrast, low-light environments.
- **Custom Visuals**: Bespoke `CustomPainter` implementations for the network grid and pulse effects.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: Listenable/ChangeNotifier pattern for real-time updates.
- **Visuals**: `flutter_animate`, `custom_painter`
- **Mapping**: `flutter_map` & `latlong2`
- **Native Bridges**: `workmanager`, `permission_handler`, `flutter_local_notifications`, `webview_flutter`.
- **Storage**: `shared_preferences`

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Android Studio / Xcode

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/wal8y/sentifire.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## 🔒 Security & Permissions
Sentifire requires the following permissions to function effectively:
- **Network State**: To scan your local network.
- **Location**: Required by Android for SSID discovery.
- **Notifications**: To alert you of security threats.
- **VPN**: To enable the firewall functionality.

---
*Built with ❤️ for a safer digital world.*
