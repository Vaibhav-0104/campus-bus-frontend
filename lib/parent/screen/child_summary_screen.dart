import 'package:flutter/material.dart';
import 'dart:ui';

/// Configuration class for child summary
class ChildSummaryConfig {
  static const String screenTitle = 'Child Summary';
  static const String headerTitle = 'Child Profiles';
}

/// Theme-related constants
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(0xFF0D47A1); // Colors.blue[900]
  static const Color accentColor = Colors.lightBlueAccent;
  static const Color successColor = Colors.green;
  static const Color pendingColor = Colors.orange;
  static const Color absentColor = Colors.redAccent;
  static const Color cardBackground = Color(
    0xFF1E2A44,
  ); // Darker blue for cards
  static const double cardBorderRadius = 20.0;
  static const double blurSigma = 10.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double elevation = 8.0;
  static const double iconSize = 28.0;
}

/// Reusable child card widget
class ChildCard extends StatelessWidget {
  final ChildData child;

  const ChildCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
                color: Colors.white.withAlpha(76), // 0.3 * 255 = 76
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(child.profileImage),
                  onBackgroundImageError:
                      (_, __) => const Icon(
                        Icons.error,
                        color: AppTheme.absentColor,
                        size: AppTheme.iconSize,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing),
                Text(
                  child.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                Text(
                  'Class: ${child.className}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Assigned Bus: ${child.busNumber}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(204),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing),
                _buildStatusRow(
                  context,
                  label: 'Attendance',
                  status: child.attendanceStatus,
                  icon:
                      child.attendanceStatus == 'Present'
                          ? Icons.check_circle
                          : Icons.cancel,
                  color:
                      child.attendanceStatus == 'Present'
                          ? AppTheme.successColor
                          : AppTheme.absentColor,
                ),
                _buildStatusRow(
                  context,
                  label: 'Status',
                  status: child.busStatus,
                  icon: _getBusStatusIcon(child.busStatus),
                  color: _getBusStatusColor(child.busStatus),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build a status row with icon and text
  Widget _buildStatusRow(
    BuildContext context, {
    required String label,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: AppTheme.iconSize),
          const SizedBox(width: 8),
          Text(
            '$label: $status',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Get icon for bus status
  IconData _getBusStatusIcon(String status) {
    switch (status) {
      case 'Boarded':
        return Icons.directions_bus;
      case 'Dropped':
        return Icons.home;
      case 'Not Yet Boarded':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  // Get color for bus status
  Color _getBusStatusColor(String status) {
    switch (status) {
      case 'Boarded':
      case 'Dropped':
        return AppTheme.successColor;
      case 'Not Yet Boarded':
        return AppTheme.pendingColor;
      default:
        return Colors.grey;
    }
  }
}

class ChildSummaryScreen extends StatefulWidget {
  const ChildSummaryScreen({super.key});

  @override
  State<ChildSummaryScreen> createState() => _ChildSummaryScreenState();
}

class _ChildSummaryScreenState extends State<ChildSummaryScreen> {
  bool _isLoading = false;
  List<ChildData> _children = [];

  @override
  void initState() {
    super.initState();
    _fetchChildData();
  }

  // Mock API call to fetch child data
  void _fetchChildData() {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _children = [
            ChildData(
              name: 'John Doe',
              className: '5A',
              busNumber: 'GJ-123',
              attendanceStatus: 'Present',
              busStatus: 'Boarded',
              profileImage: 'https://via.placeholder.com/150',
            ),
            // Uncomment for testing multiple children
            // ChildData(
            //   name: 'Jane Doe',
            //   className: '3B',
            //   busNumber: 'GJ-456',
            //   attendanceStatus: 'Absent',
            //   busStatus: 'Not Yet Boarded',
            //   profileImage: 'https://via.placeholder.com/150',
            // ),
          ];
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          ChildSummaryConfig.screenTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: AppTheme.iconSize,
            ),
            onPressed: _fetchChildData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.backgroundColor, // Solid deep blue background
        child: SafeArea(
          child:
              _isLoading
                  ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.cardPadding),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardBorderRadius,
                        ),
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
                      child: CircularProgressIndicator(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  )
                  : Padding(
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
                                colors: [
                                  AppTheme.backgroundColor,
                                  Colors.blue[600]!,
                                ],
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
                            child: Text(
                              ChildSummaryConfig.headerTitle,
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing * 1.5),
                          // Child Profiles Section
                          Text(
                            'Profiles',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing),
                          _children.isEmpty
                              ? Center(
                                child: Text(
                                  'No Child Data Available',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withAlpha(204),
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : Column(
                                children:
                                    _children
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) =>
                                              ChildCard(child: entry.value),
                                        )
                                        .toList(),
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

class ChildData {
  final String name;
  final String className;
  final String busNumber;
  final String attendanceStatus; // Present, Absent
  final String busStatus; // Boarded, Not Yet Boarded, Dropped
  final String profileImage;

  ChildData({
    required this.name,
    required this.className,
    required this.busNumber,
    required this.attendanceStatus,
    required this.busStatus,
    required this.profileImage,
  });
}
