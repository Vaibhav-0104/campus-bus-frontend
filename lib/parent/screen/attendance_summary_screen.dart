import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'view_detailed_attendance_screen.dart';
import 'dart:ui';

/// Configuration class for attendance summary
class AttendanceSummaryConfig {
  static const String screenTitle = 'Attendance Summary';
  static const String headerTitle = 'Weekly Attendance';
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
}

/// Reusable alert card widget
class AlertCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const AlertCard({super.key, required this.title, required this.subtitle});

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
                color: Colors.white.withAlpha(76),
                width: 1.5,
              ), // 0.3 * 255 = 76
            ),
            child: ListTile(
              leading: Icon(
                Icons.warning,
                color: AppTheme.absentColor,
                size: AppTheme.iconSize,
              ),
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen to display attendance summary with chart and alerts
class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  bool _isLoading = false;
  List<AttendanceData> _attendanceData = [];
  List<Map<String, String>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  // Mock API call to fetch attendance data
  void _fetchAttendanceData() {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _attendanceData = [
            AttendanceData('Mon', 1),
            AttendanceData('Tue', 1),
            AttendanceData('Wed', 0),
            AttendanceData('Thu', 0),
            AttendanceData('Fri', 0),
            AttendanceData('Sat', 1),
            AttendanceData('Sun', 1),
          ];
          _alerts = _generateAlerts(_attendanceData);
          _isLoading = false;
        });
      }
    });
  }

  // Generate alerts based on attendance data
  List<Map<String, String>> _generateAlerts(List<AttendanceData> data) {
    List<Map<String, String>> alerts = [];
    for (var entry in data) {
      if (entry.present == 0) {
        alerts.add({
          'title': 'Missed Trip: ${entry.day}',
          'subtitle': 'Child was absent on ${entry.day}',
        });
      }
    }
    for (int i = 0; i <= data.length - 3; i++) {
      if (data[i].present == 0 &&
          data[i + 1].present == 0 &&
          data[i + 2].present == 0) {
        alerts.add({
          'title': 'Consecutive Absences',
          'subtitle': 'Child missed 3+ days starting ${data[i].day}',
        });
        break;
      }
    }
    return alerts;
  }

  // Create bar chart data
  List<BarChartGroupData> _createChartData() {
    return _attendanceData.asMap().entries.map((entry) {
      final index = entry.key;
      final attendance = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: attendance.present.toDouble(),
            color:
                attendance.present == 1
                    ? AppTheme.successColor
                    : AppTheme.absentColor,
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(AttendanceSummaryConfig.screenTitle),
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
            onPressed: _fetchAttendanceData,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AttendanceSummaryConfig.headerTitle,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const ViewDetailedAttendanceScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.cardBorderRadius / 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    'View Details',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing * 1.5),
                          // Chart Section
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
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
                            height: 300,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.cardBorderRadius,
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: AppTheme.blurSigma,
                                  sigmaY: AppTheme.blurSigma,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(
                                      26,
                                    ), // 0.1 * 255 = 26
                                    border: Border.all(
                                      color: Colors.white.withAlpha(76),
                                      width: 1.5,
                                    ), // 0.3 * 255 = 76
                                  ),
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: 1.0,
                                      minY: 0.0,
                                      gridData: const FlGridData(show: false),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                value == 1.0
                                                    ? 'Present'
                                                    : 'Absent',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.copyWith(
                                                  color: Colors.white.withAlpha(
                                                    204,
                                                  ), // 0.8 * 255 = 204
                                                  fontSize: 12,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                _attendanceData[value.toInt()]
                                                    .day,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.copyWith(
                                                  color: Colors.white.withAlpha(
                                                    204,
                                                  ), // 0.8 * 255 = 204
                                                  fontSize: 12,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: _createChartData(),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipColor:
                                              (_) => AppTheme.cardBackground,
                                          tooltipPadding: const EdgeInsets.all(
                                            8,
                                          ),
                                          getTooltipItem: (
                                            group,
                                            groupIdx,
                                            rod,
                                            rodIdx,
                                          ) {
                                            return BarTooltipItem(
                                              _attendanceData[group.x]
                                                          .present ==
                                                      1
                                                  ? 'Present'
                                                  : 'Absent',
                                              Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ) ??
                                                  const TextStyle(),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing * 1.5),
                          // Alerts Section
                          Text(
                            'Alerts',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing),
                          _alerts.isEmpty
                              ? Center(
                                child: Text(
                                  'No Alerts',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withAlpha(
                                      204,
                                    ), // 0.8 * 255 = 204
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : Column(
                                children:
                                    _alerts
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => AlertCard(
                                            title: entry.value['title']!,
                                            subtitle: entry.value['subtitle']!,
                                          ),
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

class AttendanceData {
  final String day;
  final int present; // 1 for present, 0 for absent

  AttendanceData(this.day, this.present);
}
