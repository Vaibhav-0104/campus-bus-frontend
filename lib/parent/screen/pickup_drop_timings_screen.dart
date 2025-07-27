import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';

/// Configuration class for pickup and drop timings
class TimingsConfig {
  static const String screenTitle = 'Pickup & Drop Timings';
  static const String pickupTitle = 'Pickup Time';
  static const String dropTitle = 'Drop Time';
  static const String pickupTime = '7:30 AM';
  static const String dropTime = '3:00 PM';
  static const String childName = 'John Doe'; // Mock child name
  static const String busNumber = 'GJ-123'; // Mock bus number
  static const List<String> pickupStatuses = ['On the way', 'Reached'];
  static const List<String> dropStatuses = [
    'Not yet boarded',
    'Boarded',
    'Dropped',
  ];
  static const int statusUpdateIntervalSeconds = 30;
}

/// Theme-related constants
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(
    0xFF0D47A1,
  ); // Deep blue (Colors.blue[900])
  static const Color accentColor = Colors.lightBlueAccent;
  static const Color successColor = Colors.green;
  static const Color pendingColor = Colors.orange;
  static const Color cardBackground = Color(
    0xFF1E2A44,
  ); // Darker blue for cards
  static const double cardBorderRadius = 20.0;
  static const double blurSigma = 10.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double elevation = 8.0;
  static const double iconSize = 28.0;
  static const double avatarRadius = 30.0;
}

/// Reusable status card widget for pickup and drop details
class StatusCard extends StatelessWidget {
  final String title;
  final String time;
  final String status;
  final IconData icon;
  final Color iconColor;
  final bool isActive;

  const StatusCard({
    super.key,
    required this.title,
    required this.time,
    required this.status,
    required this.icon,
    required this.iconColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Placeholder for future interactivity
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing / 2),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(4, 4),
              blurRadius: AppTheme.blurSigma,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              offset: const Offset(-4, -4),
              blurRadius: AppTheme.blurSigma,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppTheme.blurSigma,
              sigmaY: AppTheme.blurSigma,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26), // 0.1 * 255 = 26
                border: Border.all(
                  color: Colors.white.withAlpha(76),
                  width: 1.5,
                ), // 0.3 * 255 = 76
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      if (isActive)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing),
                  Text(
                    'Time: $time',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing / 2),
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: AppTheme.iconSize),
                      const SizedBox(width: AppTheme.spacing / 2),
                      Expanded(
                        child: Text(
                          'Status: $status',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withAlpha(
                              204,
                            ), // 0.8 * 255 = 204
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen to display pickup and drop timings with status updates
class PickupDropTimingsScreen extends StatefulWidget {
  const PickupDropTimingsScreen({super.key});

  @override
  State<PickupDropTimingsScreen> createState() =>
      _PickupDropTimingsScreenState();
}

class _PickupDropTimingsScreenState extends State<PickupDropTimingsScreen> {
  String _pickupStatus = TimingsConfig.pickupStatuses[0];
  String _dropStatus = TimingsConfig.dropStatuses[0];
  Timer? _statusTimer;
  int _pickupStatusIndex = 0;
  int _dropStatusIndex = 0;

  @override
  void initState() {
    super.initState();
    _startStatusTimer();
  }

  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(
      const Duration(seconds: TimingsConfig.statusUpdateIntervalSeconds),
      (timer) {
        if (mounted) {
          setState(() {
            _pickupStatusIndex =
                (_pickupStatusIndex + 1) % TimingsConfig.pickupStatuses.length;
            _dropStatusIndex =
                (_dropStatusIndex + 1) % TimingsConfig.dropStatuses.length;
            _pickupStatus = TimingsConfig.pickupStatuses[_pickupStatusIndex];
            _dropStatus = TimingsConfig.dropStatuses[_dropStatusIndex];
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  /// Manually refreshes status (mock implementation)
  void _refreshStatus() {
    if (mounted) {
      setState(() {
        _pickupStatusIndex =
            (_pickupStatusIndex + 1) % TimingsConfig.pickupStatuses.length;
        _dropStatusIndex =
            (_dropStatusIndex + 1) % TimingsConfig.dropStatuses.length;
        _pickupStatus = TimingsConfig.pickupStatuses[_pickupStatusIndex];
        _dropStatus = TimingsConfig.dropStatuses[_dropStatusIndex];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status refreshed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    _startStatusTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(TimingsConfig.screenTitle),
        backgroundColor: AppTheme.backgroundColor.withAlpha(
          76,
        ), // 0.3 * 255 = 76
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppTheme.blurSigma,
              sigmaY: AppTheme.blurSigma,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshStatus,
        tooltip: 'Refresh Status',
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.backgroundColor, // Solid deep blue background
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(AppTheme.cardPadding),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.backgroundColor, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.cardBorderRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(4, 4),
                          blurRadius: AppTheme.blurSigma,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: AppTheme.avatarRadius,
                          backgroundColor: AppTheme.accentColor,
                          child: Text(
                            TimingsConfig.childName[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Child: ${TimingsConfig.childName}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing / 4),
                              Text(
                                'Bus: ${TimingsConfig.busNumber}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withAlpha(
                                    204,
                                  ), // 0.8 * 255 = 204
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing * 1.5),
                  // Pickup Card
                  StatusCard(
                    title: TimingsConfig.pickupTitle,
                    time: TimingsConfig.pickupTime,
                    status: _pickupStatus,
                    icon:
                        _pickupStatus == TimingsConfig.pickupStatuses[1]
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                    iconColor:
                        _pickupStatus == TimingsConfig.pickupStatuses[1]
                            ? AppTheme.successColor
                            : AppTheme.pendingColor,
                    isActive: _pickupStatus == TimingsConfig.pickupStatuses[1],
                  ),
                  const SizedBox(height: AppTheme.spacing),
                  // Drop Card
                  StatusCard(
                    title: TimingsConfig.dropTitle,
                    time: TimingsConfig.dropTime,
                    status: _dropStatus,
                    icon:
                        _dropStatus == TimingsConfig.dropStatuses[2]
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                    iconColor:
                        _dropStatus == TimingsConfig.dropStatuses[2]
                            ? AppTheme.successColor
                            : AppTheme.pendingColor,
                    isActive: _dropStatus == TimingsConfig.dropStatuses[2],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
