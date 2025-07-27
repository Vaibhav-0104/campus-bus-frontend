import 'package:flutter/material.dart';
import 'dart:ui';

/// Configuration class for attendance details
class AttendanceConfig {
  static const String screenTitle = 'Detailed Attendance';
  static const String childName = 'John Doe'; // Mock child name
  static const List<String> filterOptions = [
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
  ];
  static const List<Map<String, dynamic>> mockAttendanceData = [
    {'date': '2025-07-26', 'status': 'Present', 'time': '7:30 AM'},
    {'date': '2025-07-25', 'status': 'Absent', 'time': '-'},
    {'date': '2025-07-24', 'status': 'Present', 'time': '7:28 AM'},
    {'date': '2025-07-23', 'status': 'Present', 'time': '7:32 AM'},
    {'date': '2025-07-22', 'status': 'Absent', 'time': '-'},
  ];
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
  static const double avatarRadius = 30.0;
}

/// Reusable attendance card widget
class AttendanceCard extends StatelessWidget {
  final String date;
  final String status;
  final String time;

  const AttendanceCard({
    super.key,
    required this.date,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = status == 'Present';
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
              child: Row(
                children: [
                  Icon(
                    isPresent ? Icons.check_circle : Icons.cancel,
                    color:
                        isPresent
                            ? AppTheme.successColor
                            : AppTheme.absentColor,
                    size: AppTheme.iconSize,
                  ),
                  const SizedBox(width: AppTheme.spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing / 2),
                        Text(
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
                        Text(
                          'Time: $time',
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
          ),
        ),
      ),
    );
  }
}

/// Screen to display detailed attendance records
class ViewDetailedAttendanceScreen extends StatefulWidget {
  const ViewDetailedAttendanceScreen({super.key});

  @override
  State<ViewDetailedAttendanceScreen> createState() =>
      _ViewDetailedAttendanceScreenState();
}

class _ViewDetailedAttendanceScreenState
    extends State<ViewDetailedAttendanceScreen> {
  String _selectedFilter = AttendanceConfig.filterOptions[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(AttendanceConfig.screenTitle),
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
                            AttendanceConfig.childName[0],
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
                                'Child: ${AttendanceConfig.childName}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing / 4),
                              DropdownButton<String>(
                                value: _selectedFilter,
                                dropdownColor: AppTheme.cardBackground,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                underline: Container(),
                                items:
                                    AttendanceConfig.filterOptions
                                        .map(
                                          (option) => DropdownMenuItem(
                                            value: option,
                                            child: Text(option),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null && mounted) {
                                    setState(() {
                                      _selectedFilter = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing * 1.5),
                  // Attendance Records
                  ...AttendanceConfig.mockAttendanceData.map(
                    (record) => AttendanceCard(
                      date: record['date'] as String,
                      status: record['status'] as String,
                      time: record['time'] as String,
                    ),
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
