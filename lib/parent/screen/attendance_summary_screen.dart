import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:campus_bus_management/config/api_config.dart';

/// Configuration class for attendance summary
class AttendanceSummaryConfig {
  static const String screenTitle = 'Attendance Summary';
  static const String headerTitle = 'Weekly Attendance';
  static const List<int> dateRangeOptions = [7, 14, 30];
}

/// Purple Theme (Matches Dashboard)
class AppTheme {
  static const Color primary = Color(0xFF6A1B9A); // Deep Purple
  static const Color lightPurple = Color(0xFFCE93D8); // Light Purple Accent
  static const Color background = Color(0xFFF8F5FF); // Light Purple BG
  static const Color cardBg = Colors.white; // White cards
  static const Color textPrimary = Color(0xFF4A148C); // Dark Purple Text
  static const Color textSecondary = Color(0xFF7E57C2);
  static const Color successColor = Color(0xFF66BB6A); // Green
  static const Color absentColor = Color(0xFFFF5252); // Red

  static const double borderRadius = 20.0;
  static const double blur = 12.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double iconSize = 28.0;

  static const List<Color> studentColors = [
    Color(0xFF6A1B9A),
    Color(0xFFCE93D8),
    Color(0xFFFF5252),
    Color(0xFF66BB6A),
  ];
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.blur,
            sigmaY: AppTheme.blur,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: BoxDecoration(
              color: AppTheme.cardBg.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(
                Icons.warning,
                color: AppTheme.absentColor,
                size: AppTheme.iconSize,
              ),
              title: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
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

/// Attendance Summary Screen
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
  int _selectedDateRange = 7;
  Map<String, List<AttendanceData>> _attendanceData = {};
  Map<String, List<Map<String, String>>> _alerts = {};
  bool _showAllStudents = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _attendanceData = {};
      _alerts = {};
      _selectedStudentId = null;
    });

    final client = http.Client();
    try {
      final parentResponse = await client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/students/parent-login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'parentEmail': widget.parentEmail,
              'parentContact': widget.parentContact,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (parentResponse.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data';
        });
        client.close();
        return;
      }

      final parentData = jsonDecode(parentResponse.body);
      final students =
          (parentData['students'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();

      if (students.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No children found';
        });
        client.close();
        return;
      }

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
                Uri.parse('${ApiConfig.baseUrl}/students/attendance/date'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'date': dateStr,
                  'studentIds': [studentId],
                }),
              )
              .timeout(const Duration(seconds: 10));

          int present = 0;
          if (attendanceResponse.statusCode == 200) {
            final records =
                jsonDecode(attendanceResponse.body) as List<dynamic>;
            if (records.isNotEmpty && records[0]['status'] == 'Present') {
              present = 1;
            }
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

        // Consecutive absences
        for (int i = 0; i <= studentAttendance.length - 3; i++) {
          if (studentAttendance[i].present == 0 &&
              studentAttendance[i + 1].present == 0 &&
              studentAttendance[i + 2].present == 0) {
            studentAlerts.add({
              'title': 'Consecutive Absences',
              'subtitle': '$studentName missed 3+ days',
            });
            break;
          }
        }

        attendanceData[studentId] = studentAttendance;
        alerts[studentId] = studentAlerts;
      }

      setState(() {
        _students = students;
        _selectedStudentId = students.first['_id'];
        _attendanceData = attendanceData;
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error';
      });
    } finally {
      client.close();
    }
  }

  List<LineChartBarData> _createChartData() {
    final List<LineChartBarData> lineBars = [];
    final studentsToShow =
        _showAllStudents
            ? _students
            : _students.where((s) => s['_id'] == _selectedStudentId).toList();

    for (var i = 0; i < studentsToShow.length; i++) {
      final student = studentsToShow[i];
      final studentId = student['_id'] as String;
      final attendance = _attendanceData[studentId] ?? [];
      final color = AppTheme.studentColors[i % AppTheme.studentColors.length];

      final spots =
          attendance.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value.present.toDouble());
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
                (spot, _, __, ___) => FlDotCirclePainter(
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
                color.withValues(alpha: 0.05),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          AttendanceSummaryConfig.screenTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAttendanceData,
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
                : _errorMessage != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAttendanceData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
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
                        // Show All Students Toggle
                        if (_students.length > 1)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Show All Students',
                                  style: TextStyle(color: AppTheme.textPrimary),
                                ),
                                Switch(
                                  value: _showAllStudents,
                                  onChanged:
                                      (v) =>
                                          setState(() => _showAllStudents = v),
                                  activeColor: AppTheme.lightPurple,
                                ),
                              ],
                            ),
                          ),
                        if (_students.length > 1 && !_showAllStudents)
                          const SizedBox(height: 12),

                        // Student Dropdown
                        if (_students.length > 1 && !_showAllStudents)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedStudentId,
                              isExpanded: true,
                              items:
                                  _students.map((s) {
                                    return DropdownMenuItem<String>(
                                      value: s['_id'] as String,
                                      child: Text(
                                        s['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  (v) => setState(() => _selectedStudentId = v),
                              dropdownColor: AppTheme.cardBg,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppTheme.primary,
                              ),
                              underline: const SizedBox(),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Date Range Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: DropdownButton<int>(
                            value: _selectedDateRange,
                            isExpanded: true,
                            items:
                                AttendanceSummaryConfig.dateRangeOptions.map((
                                  d,
                                ) {
                                  return DropdownMenuItem<int>(
                                    value: d,
                                    child: Text(
                                      'Last $d Days',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedDateRange = v);
                                _fetchAttendanceData();
                              }
                            },
                            dropdownColor: AppTheme.cardBg,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: AppTheme.primary,
                            ),
                            underline: const SizedBox(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Line Chart
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          height: 400,
                          child: LineChart(
                            LineChartData(
                              lineBarsData: _createChartData(),
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget:
                                        (v, _) => Text(
                                          v == 1
                                              ? 'Present'
                                              : v == 0
                                              ? 'Absent'
                                              : '',
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (v, _) {
                                      final data =
                                          _attendanceData[_students
                                              .firstOrNull?['_id']];
                                      if (data == null ||
                                          v.toInt() >= data.length)
                                        return const Text('');
                                      return Text(
                                        data[v.toInt()].day,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              minY: -0.1,
                              maxY: 1.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Alerts
                        const Text(
                          'Alerts',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _alerts.isEmpty
                            ? const Text(
                              'No Alerts',
                              style: TextStyle(color: AppTheme.textSecondary),
                            )
                            : Column(
                              children:
                                  _showAllStudents
                                      ? _students
                                          .expand(
                                            (s) => _alerts[s['_id']] ?? [],
                                          )
                                          .map(
                                            (a) => AlertCard(
                                              title: a['title']!,
                                              subtitle: a['subtitle']!,
                                            ),
                                          )
                                          .toList()
                                      : (_alerts[_selectedStudentId] ?? [])
                                          .map(
                                            (a) => AlertCard(
                                              title: a['title']!,
                                              subtitle: a['subtitle']!,
                                            ),
                                          )
                                          .toList(),
                            ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}

class AttendanceData {
  final String day;
  final int present;
  final String date;

  AttendanceData(this.day, this.present, this.date);
}
