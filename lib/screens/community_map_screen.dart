import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  String? _selectedRegion;
  late MapController _mapController;
  
  final LatLng _center = const LatLng(41.0082, 28.9784);
  
  Map<String, RegionData> _regions = {
    'Beşiktaş': RegionData(
      threatCount: 3,
      deviceCount: 12,
      threatLevel: 'High',
      color: Colors.red,
      position: LatLng(41.0422, 29.0084),
    ),
    'Kadıköy': RegionData(
      threatCount: 2,
      deviceCount: 8,
      threatLevel: 'Medium',
      color: Colors.orange,
      position: LatLng(40.9833, 29.0167),
    ),
    'Taksim': RegionData(
      threatCount: 1,
      deviceCount: 15,
      threatLevel: 'High',
      color: Colors.red,
      position: LatLng(41.0369, 28.9850),
    ),
    'Şişli': RegionData(
      threatCount: 1,
      deviceCount: 5,
      threatLevel: 'Low',
      color: Colors.yellow,
      position: LatLng(41.0602, 28.9874),
    ),
    'Beyoğlu': RegionData(
      threatCount: 0,
      deviceCount: 20,
      threatLevel: 'Safe',
      color: Colors.green,
      position: LatLng(41.0369, 28.9784),
    ),
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Map'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                _handleMapTap(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sentifire.app',
                tileProvider: NetworkTileProvider(),
              ),
              MarkerLayer(
                markers: _regions.entries.map((entry) {
                  final data = entry.value;
                  final isSelected = _selectedRegion == entry.key;
                  
                  return Marker(
                    point: data.position,
                    width: isSelected ? 60 : 50,
                    height: isSelected ? 60 : 50,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRegion = entry.key;
                        });
                        _mapController.move(data.position, 14.0);
                      },
                      child: _buildRegionMarker(data, isSelected),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          if (_selectedRegion != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildRegionDetails(_selectedRegion!),
            )
                .animate()
                .slideY(begin: 1, end: 0, duration: 300.ms)
                .fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildRegionMarker(RegionData data, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: data.color.withOpacity(0.3),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.5),
            blurRadius: isSelected ? 20 : 10,
            spreadRadius: isSelected ? 5 : 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: isSelected ? 40 : 35,
          height: isSelected ? 40 : 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: data.color,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 3 : 2,
            ),
          ),
          child: Center(
            child: Text(
              '${data.threatCount}',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSelected ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleMapTap(LatLng point) {
    for (final entry in _regions.entries) {
      final distance = _calculateDistance(point, entry.value.position);
      if (distance < 0.005) {
        setState(() {
          _selectedRegion = entry.key;
        });
        _mapController.move(entry.value.position, 14.0);
        return;
      }
    }
    
    if (_selectedRegion != null) {
      setState(() {
        _selectedRegion = null;
      });
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2) / 1000.0;
  }

  Widget _buildRegionDetails(String regionName) {
    final data = _regions[regionName]!;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: data.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      regionName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    _buildStatCard(
                      icon: Icons.warning,
                      label: 'Threats',
                      value: '${data.threatCount}',
                      color: Colors.red,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.people,
                      label: 'Devices',
                      value: '${data.deviceCount}',
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: data.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield, color: data.color),
                      const SizedBox(width: 12),
                      Text(
                        'Threat Level: ${data.threatLevel}',
                        style: TextStyle(
                          color: data.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${data.deviceCount} devices confirmed this threat',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegionData {
  final int threatCount;
  final int deviceCount;
  final String threatLevel;
  final Color color;
  final LatLng position;

  RegionData({
    required this.threatCount,
    required this.deviceCount,
    required this.threatLevel,
    required this.color,
    required this.position,
  });
}
