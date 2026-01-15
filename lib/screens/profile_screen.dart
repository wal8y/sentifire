import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const trustScore = 87;
    const reportsSent = 42;
    const confirmedMatches = 38;
    final accuracy = (confirmedMatches / reportsSent * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar and Sentinel Level
            _buildProfileHeader(trustScore)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.2),

            const SizedBox(height: 32),

            // Trust Score Bar
            _buildTrustScoreBar(trustScore)
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: 32),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.send,
                    label: 'Reports Sent',
                    value: '$reportsSent',
                    color: Colors.blue,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideX(begin: -0.2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.verified,
                    label: 'Confirmed',
                    value: '$confirmedMatches',
                    color: Colors.green,
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideX(begin: 0.2),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Accuracy Card
            _buildAccuracyCard(accuracy)
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: 32),

            // Additional Info
            _buildInfoSection()
                .animate()
                .fadeIn(delay: 600.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(int trustScore) {
    String sentinelLevel;
    Color levelColor;
    
    if (trustScore >= 90) {
      sentinelLevel = 'Elite Sentinel';
      levelColor = Colors.purple;
    } else if (trustScore >= 75) {
      sentinelLevel = 'Advanced Sentinel';
      levelColor = Colors.blue;
    } else if (trustScore >= 60) {
      sentinelLevel = 'Guardian Sentinel';
      levelColor = Colors.green;
    } else {
      sentinelLevel = 'Novice Sentinel';
      levelColor = Colors.orange;
    }

    return Column(
      children: [
        // Avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                levelColor,
                levelColor.withOpacity(0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: levelColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        
        // Sentinel Level
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: levelColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: levelColor.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield, color: levelColor, size: 24),
              const SizedBox(width: 12),
              Text(
                sentinelLevel,
                style: TextStyle(
                  color: levelColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrustScoreBar(int score) {
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trust Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 12,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your device trustworthiness based on community verification',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyCard(int accuracy) {
    Color accuracyColor;
    if (accuracy >= 90) {
      accuracyColor = Colors.green;
    } else if (accuracy >= 75) {
      accuracyColor = Colors.blue;
    } else {
      accuracyColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accuracyColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accuracyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.gps_fixed,
              color: accuracyColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accuracy',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$accuracy%',
                  style: TextStyle(
                    color: accuracyColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Report accuracy rate',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.device_hub, 'Device ID', 'SN-2024-XXXX'),
          const Divider(color: Colors.grey),
          _buildInfoRow(Icons.calendar_today, 'Joined', 'January 2024'),
          const Divider(color: Colors.grey),
          _buildInfoRow(Icons.location_on, 'Region', 'Istanbul, Turkey'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

