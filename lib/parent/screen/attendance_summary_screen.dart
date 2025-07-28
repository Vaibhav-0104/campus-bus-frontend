import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'dart:developer' as developer;
import 'view_detailed_attendance_screen.dart';

/// Configuration class for attendance summary
class AttendanceSummaryConfig {
  static const String screenTitle = 'Attendance Summary';
  static const String headerTitle = 'Weekly Attendance';
  static const String baseUrl =
      'http://192.168.31.104:5000'; // For physical device
  // static const String baseUrl = 'http://10.0.2.2:5000'; // For Android emulator
  static const List<int> dateRangeOptions = [7, 14, 30]; // Days for dropdown
}

/// Theme-related constants
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(0xFF0D47A1); // Deep blue
  static const Color accentColor = Colors.lightBlueAccent;
  static const Color successColor = Colors.green;
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
  static const List<Color> studentColors = [
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.cyanAccent,
  ]; // Colors for multiple students
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
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(4, 4),
            blurRadius: AppTheme.blurSigma,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
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
              color: Colors.white.withValues(alpha: 0.102), // 26/255
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.298),
                width: 1.5,
              ), // 76/255
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
                  color: Colors.white.withValues(alpha: 0.8), // 204/255
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
  final String parentContact;
  final String parentEmail;

  const AttendanceSummaryScreen({
    super.key,
    required this.parentContact,
    required this.parentEmail,
  });

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _students = [];
  String? _selectedStudentId;
  int _selectedDateRange = 7; // Default to 7 days
  Map<String, List<AttendanceData>> _attendanceData = {};
  Map<String, List<Map<String, String>>> _alerts = {};
  bool _showAllStudents = true; // Toggle to show all students or one

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  // Fetch attendance data from backend
  Future<void> _fetchAttendanceData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _attendanceData = {};
      _alerts = {};
      _selectedStudentId = null; // Reset selected student
    });

    final client = http.Client();
    try {
      // Step 1: Fetch students by parent contact and email
      final parentResponse = await client
          .post(
            Uri.parse(
              '${AttendanceSummaryConfig.baseUrl}/api/students/parent-login',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'parentEmail': widget.parentEmail,
              'parentContact': widget.parentContact,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) {
        setState(() => _isLoading = false);
        client.close();
        return;
      }

      if (parentResponse.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              parentResponse.statusCode == 404
                  ? 'No children found for this parent. Please verify your email and contact number or contact support.'
                  : 'Failed to load data (Status: ${parentResponse.statusCode}): ${parentResponse.body}';
        });
        client.close();
        return;
      }

      final parentData =
          jsonDecode(parentResponse.body) as Map<String, dynamic>;
      final students =
          (parentData['students'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();

      if (students.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No children found for this parent';
        });
        client.close();
        return;
      }

      // Step 2: Fetch attendance for the selected date range for all students
      final Map<String, List<AttendanceData>> attendanceData = {};
      final Map<String, List<Map<String, String>>> alerts = {};
      final today = DateTime.now();
      final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

      for (var student in students) {
        final studentId = student['_id'] as String;
        final studentName = student['name'] as String? ?? 'Unknown';
        final List<AttendanceData> studentAttendance = [];
        final List<Map<String, String>> studentAlerts = [];

        for (int i = _selectedDateRange - 1; i >= 0; i--) {
          final date = today.subtract(Duration(days: i));
          final dateStr = date.toIso8601String().split('T')[0];

          final attendanceResponse = await client
              .post(
                Uri.parse(
                  '${AttendanceSummaryConfig.baseUrl}/api/students/attendance/date',
                ),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'date': dateStr,
                  'studentIds': [studentId],
                }),
              )
              .timeout(const Duration(seconds: 10));

          int present = 0;
          if (attendanceResponse.statusCode == 200) {
            final attendanceRecords =
                jsonDecode(attendanceResponse.body) as List<dynamic>;
            if (attendanceRecords.isNotEmpty) {
              present = attendanceRecords[0]['status'] == 'Present' ? 1 : 0;
            }
          } else {
            developer.log(
              'Attendance API failed for $dateStr (Status: ${attendanceResponse.statusCode}): ${attendanceResponse.body}',
              name: 'AttendanceSummaryScreen',
            );
          }

          final dayName = days[date.weekday % 7];
          studentAttendance.add(AttendanceData(dayName, present, dateStr));

          if (present == 0) {
            studentAlerts.add({
              'title': 'Missed Trip: $dayName',
              'subtitle': '$studentName was absent on $dayName, $dateStr',
            });
          }
        }

        // Generate alerts for consecutive absences
        for (int i = 0; i <= studentAttendance.length - 3; i++) {
          if (studentAttendance[i].present == 0 &&
              studentAttendance[i + 1].present == 0 &&
              studentAttendance[i + 2].present == 0) {
            studentAlerts.add({
              'title': 'Consecutive Absences',
              'subtitle':
                  '$studentName missed 3+ days starting ${studentAttendance[i].day}, ${studentAttendance[i].date}',
            });
            break;
          }
        }

        attendanceData[studentId] = studentAttendance;
        alerts[studentId] = studentAlerts;
      }

      if (!mounted) {
        setState(() => _isLoading = false);
        client.close();
        return;
      }

      setState(() {
        _students = students;
        _selectedStudentId = students.first['_id'] as String; // Initialize here
        _attendanceData = attendanceData;
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        client.close();
        return;
      }
      developer.log(
        'Exception in _fetchAttendanceData: $e',
        name: 'AttendanceSummaryScreen',
      );
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load attendance data: $e';
      });
    } finally {
      client.close();
    }
  }

  // Create line chart data for all or selected students
  List<LineChartBarData> _createChartData() {
    final List<LineChartBarData> lineBars = [];
    final studentsToShow =
        _showAllStudents
            ? _students
            : _students.where((s) => s['_id'] == _selectedStudentId).toList();

    for (var i = 0; i < studentsToShow.length; i++) {
      final student = studentsToShow[i];
      final studentId = student['_id'] as String;
      final studentAttendance = _attendanceData[studentId] ?? [];
      final color = AppTheme.studentColors[i % AppTheme.studentColors.length];

      final spots =
          studentAttendance.asMap().entries.map((entry) {
            final index = entry.key;
            final attendance = entry.value;
            return FlSpot(index.toDouble(), attendance.present.toDouble());
          }).toList();

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: color,
          barWidth: 4,
          dotData: FlDotData(
            show: true,
            getDotPainter:
                (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 6,
                  color:
                      spot.y == 1.0
                          ? AppTheme.successColor
                          : AppTheme.absentColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    return lineBars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(AttendanceSummaryConfig.screenTitle),
        backgroundColor: AppTheme.backgroundColor.withValues(
          alpha: 0.3,
        ), // 76/255
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
        color: AppTheme.backgroundColor,
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
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(4, 4),
                            blurRadius: AppTheme.blurSigma,
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  )
                  : _errorMessage != null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(
                              alpha: 0.8,
                            ), // 204/255
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing),
                        ElevatedButton(
                          onPressed: _fetchAttendanceData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.cardBorderRadius,
                              ),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                  : Padding(
                    padding: const EdgeInsets.all(AppTheme.cardPadding),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toggle for showing all students or one
                          if (_students.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.cardPadding,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.cardBorderRadius,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Show All Students',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Switch(
                                    value: _showAllStudents,
                                    onChanged: (value) {
                                      setState(() {
                                        _showAllStudents = value;
                                        if (!value && _students.isNotEmpty) {
                                          _selectedStudentId =
                                              _students.first['_id'] as String;
                                        }
                                      });
                                    },
                                    activeColor: AppTheme.accentColor,
                                  ),
                                ],
                              ),
                            ),
                          if (_students.length > 1 && !_showAllStudents)
                            const SizedBox(height: AppTheme.spacing),
                          // Student Selection Dropdown (shown only if not showing all students)
                          if (_students.length > 1 && !_showAllStudents)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.cardPadding,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.cardBorderRadius,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedStudentId,
                                isExpanded: true,
                                dropdownColor: AppTheme.cardBackground,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                                underline: const SizedBox(),
                                items:
                                    _students.map((student) {
                                      return DropdownMenuItem<String>(
                                        value: student['_id'] as String,
                                        child: Text(
                                          student['name'] as String? ??
                                              'Unknown',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.copyWith(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStudentId = value;
                                  });
                                },
                              ),
                            ),
                          const SizedBox(height: AppTheme.spacing),
                          // Date Range Selector
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.cardPadding,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(
                                AppTheme.cardBorderRadius,
                              ),
                            ),
                            child: DropdownButton<int>(
                              value: _selectedDateRange,
                              isExpanded: true,
                              dropdownColor: AppTheme.cardBackground,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              underline: const SizedBox(),
                              items:
                                  AttendanceSummaryConfig.dateRangeOptions.map((
                                    days,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: days,
                                      child: Text(
                                        'Last $days Days',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedDateRange = value;
                                  });
                                  _fetchAttendanceData();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing * 1.5),
                          // Header with View Details Button
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
                                  color: Colors.black.withValues(alpha: 0.2),
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
                          // Line Chart
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
                                  color: Colors.black.withValues(alpha: 0.2),
                                  offset: const Offset(4, 4),
                                  blurRadius: AppTheme.blurSigma,
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  offset: const Offset(-4, -4),
                                  blurRadius: AppTheme.blurSigma,
                                ),
                              ],
                            ),
                            height: 350, // Increased height for legend
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
                                    color: Colors.white.withValues(
                                      alpha: 0.102,
                                    ), // 26/255
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.298,
                                      ),
                                      width: 1.5,
                                    ), // 76/255
                                  ),
                                  child: Column(
                                    children: [
                                      // Legend
                                      if (_showAllStudents &&
                                          _students.length > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppTheme.spacing,
                                          ),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children:
                                                _students.asMap().entries.map((
                                                  entry,
                                                ) {
                                                  final index = entry.key;
                                                  final student = entry.value;
                                                  return Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 12,
                                                        height: 12,
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color:
                                                              AppTheme
                                                                  .studentColors[index %
                                                                  AppTheme
                                                                      .studentColors
                                                                      .length],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        student['name']
                                                                as String? ??
                                                            'Unknown',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12,
                                                            ),
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                          ),
                                        ),
                                      Expanded(
                                        child: LineChart(
                                          LineChartData(
                                            lineBarsData: _createChartData(),
                                            gridData: FlGridData(
                                              show: true,
                                              drawVerticalLine: true,
                                              horizontalInterval: 0.5,
                                              verticalInterval: 1,
                                              getDrawingHorizontalLine: (
                                                value,
                                              ) {
                                                return FlLine(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.2),
                                                  strokeWidth: 1,
                                                );
                                              },
                                              getDrawingVerticalLine: (value) {
                                                return FlLine(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.2),
                                                  strokeWidth: 1,
                                                );
                                              },
                                            ),
                                            titlesData: FlTitlesData(
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 40,
                                                  getTitlesWidget: (
                                                    value,
                                                    meta,
                                                  ) {
                                                    return Text(
                                                      value == 1.0
                                                          ? 'Present'
                                                          : 'Absent',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.8,
                                                                ), // 204/255
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
                                                  reservedSize: 40,
                                                  interval:
                                                      _selectedDateRange > 14
                                                          ? 2
                                                          : 1, // Reduce label density for longer ranges
                                                  getTitlesWidget: (
                                                    value,
                                                    meta,
                                                  ) {
                                                    final data =
                                                        _attendanceData[_students
                                                                .isNotEmpty
                                                            ? _students
                                                                .first['_id']
                                                            : ''];
                                                    if (data == null ||
                                                        value.toInt() >=
                                                            data.length) {
                                                      return const Text('');
                                                    }
                                                    final day =
                                                        data[value.toInt()];
                                                    final label =
                                                        _selectedDateRange > 7
                                                            ? day.date
                                                                .split('-')
                                                                .sublist(1)
                                                                .join('/')
                                                            : day.day;
                                                    return Transform.rotate(
                                                      angle:
                                                          -45 *
                                                          3.14159 /
                                                          180, // Rotate 45 degrees
                                                      child: Text(
                                                        label,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.copyWith(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  ), // 204/255
                                                              fontSize: 12,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            borderData: FlBorderData(
                                              show: false,
                                            ),
                                            minY: 0,
                                            maxY: 1,
                                            lineTouchData: LineTouchData(
                                              enabled: true,
                                              touchTooltipData: LineTouchTooltipData(
                                                getTooltipColor:
                                                    (_) =>
                                                        AppTheme.cardBackground,
                                                tooltipPadding:
                                                    const EdgeInsets.all(8),
                                                getTooltipItems: (
                                                  touchedSpots,
                                                ) {
                                                  return touchedSpots.map((
                                                    spot,
                                                  ) {
                                                    final studentIndex =
                                                        spot.barIndex;
                                                    final student =
                                                        _students[studentIndex %
                                                            _students.length];
                                                    final data =
                                                        _attendanceData[student['_id']] ??
                                                        [];
                                                    if (spot.x.toInt() >=
                                                        data.length) {
                                                      return null;
                                                    }
                                                    final attendance =
                                                        data[spot.x.toInt()];
                                                    return LineTooltipItem(
                                                      '${student['name']}\n${attendance.date}\n${attendance.present == 1 ? 'Present' : 'Absent'}',
                                                      Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.copyWith(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ) ??
                                                          const TextStyle(),
                                                    );
                                                  }).toList();
                                                },
                                              ),
                                            ),
                                            extraLinesData: ExtraLinesData(
                                              horizontalLines: [
                                                HorizontalLine(
                                                  y: 1.0,
                                                  color: AppTheme.successColor
                                                      .withValues(alpha: 0.5),
                                                  strokeWidth: 1,
                                                  dashArray: [5, 5],
                                                ),
                                                HorizontalLine(
                                                  y: 0.0,
                                                  color: AppTheme.absentColor
                                                      .withValues(alpha: 0.5),
                                                  strokeWidth: 1,
                                                  dashArray: [5, 5],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                    color: Colors.white.withValues(
                                      alpha: 0.8,
                                    ), // 204/255
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : Column(
                                children:
                                    _showAllStudents
                                        ? _students
                                            .asMap()
                                            .entries
                                            .expand(
                                              (entry) => (_alerts[entry
                                                          .value['_id']] ??
                                                      [])
                                                  .map(
                                                    (alert) => AlertCard(
                                                      title: alert['title']!,
                                                      subtitle:
                                                          alert['subtitle']!,
                                                    ),
                                                  ),
                                            )
                                            .toList()
                                        : (_alerts[_selectedStudentId] ?? [])
                                            .asMap()
                                            .entries
                                            .map(
                                              (entry) => AlertCard(
                                                title: entry.value['title']!,
                                                subtitle:
                                                    entry.value['subtitle']!,
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
  final String date; // ISO date string (e.g., "2025-07-28")

  AttendanceData(this.day, this.present, this.date);
}
