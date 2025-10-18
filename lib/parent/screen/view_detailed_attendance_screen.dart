import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'child_summary_screen.dart'; // Import to use ChildSummaryConfig
import 'package:campus_bus_management/config/api_config.dart';

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
  static const double iconSize = 28.0;
  static const double avatarRadius = 24.0; // Added for CircleAvatar
}

/// Configuration class for attendance details
class AttendanceConfig {
  static const String screenTitle = 'Detailed Attendance';
  static const List<String> filterOptions = [
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
  ];
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
                  color: Colors.white.withValues(alpha: 0.298), // 76/255
                  width: 1.5,
                ),
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
                            color: Colors.white.withValues(
                              alpha: 0.8,
                            ), // 204/255
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Time: $time',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
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
  final String studentId;
  final String childName;

  const ViewDetailedAttendanceScreen({
    super.key,
    required this.studentId,
    required this.childName,
  });

  @override
  State<ViewDetailedAttendanceScreen> createState() =>
      _ViewDetailedAttendanceScreenState();
}

class _ViewDetailedAttendanceScreenState
    extends State<ViewDetailedAttendanceScreen> {
  String _selectedFilter = AttendanceConfig.filterOptions[0];
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _attendanceData = [];

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
      _attendanceData = [];
    });

    final client = http.Client();
    try {
      // Determine date range based on filter
      DateTime endDate = DateTime.now();
      DateTime startDate;
      switch (_selectedFilter) {
        case 'Last 7 Days':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'Last 30 Days':
          startDate = endDate.subtract(const Duration(days: 30));
          break;
        case 'This Month':
          startDate = DateTime(endDate.year, endDate.month, 1);
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      // Fetch attendance data for each date in the range
      final List<Map<String, dynamic>> attendanceData = [];
      final days = endDate.difference(startDate).inDays + 1;

      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dateStr = date.toIso8601String().split('T')[0];

        try {
          final response = await client
              .post(
                Uri.parse('${ApiConfig.baseUrl}/students/attendance/date'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'date': dateStr,
                  'studentIds': [widget.studentId],
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (!mounted) {
            setState(() => _isLoading = false);
            client.close();
            return;
          }

          // Log raw response for debugging
          print('API Response for $dateStr: ${response.body}');

          if (response.statusCode == 200) {
            var rawData;
            try {
              rawData = jsonDecode(response.body);
            } catch (e) {
              print('JSON Decode Error for $dateStr: $e');
              attendanceData.add({
                'date': dateStr,
                'status': 'Absent',
                'time': '-',
              });
              continue;
            }

            if (rawData is List<dynamic>) {
              // Find record for the specific studentId
              final record = rawData.firstWhere(
                (r) => r['studentId']?['_id'] == widget.studentId,
                orElse: () => null,
              );

              if (record != null) {
                attendanceData.add({
                  'date':
                      dateStr, // Use requested date since response doesn't include it
                  'status': record['status']?.toString() ?? 'Absent',
                  'time': '-', // Time not provided by backend
                });
              } else {
                attendanceData.add({
                  'date': dateStr,
                  'status': 'Absent',
                  'time': '-',
                });
              }
            } else {
              print('Invalid response format for $dateStr: $rawData');
              attendanceData.add({
                'date': dateStr,
                'status': 'Absent',
                'time': '-',
              });
            }
          } else {
            print('API Error for $dateStr: Status ${response.statusCode}');
            attendanceData.add({
              'date': dateStr,
              'status': 'Absent',
              'time': '-',
            });
          }
        } catch (e) {
          print('Request Error for $dateStr: $e');
          attendanceData.add({
            'date': dateStr,
            'status': 'Absent',
            'time': '-',
          });
        }
      }

      if (!mounted) {
        client.close();
        return;
      }

      setState(() {
        _attendanceData = attendanceData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        client.close();
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
      });
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(AttendanceConfig.screenTitle),
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
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.backgroundColor,
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
                          color: Colors.black.withValues(alpha: 0.2),
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
                            widget.childName.isNotEmpty
                                ? widget.childName[0]
                                : 'N/A',
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
                                'Child: ${widget.childName}',
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
                                    _fetchAttendanceData();
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
                  // Loading or Error State
                  if (_isLoading)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.cardPadding),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(
                            AppTheme.cardBorderRadius,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(2, 2),
                              blurRadius: AppTheme.blurSigma,
                            ),
                          ],
                        ),
                        child: CircularProgressIndicator(
                          color: AppTheme.accentColor,
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
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
                  else
                    // Attendance Records
                    ..._attendanceData.map(
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
