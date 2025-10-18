import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_bus_management/config/api_config.dart'; // ✅ Import centralized URL

/// Configuration class for child summary
class ChildSummaryConfig {
  static const String screenTitle = 'Child Summary';
  static const String headerTitle = 'Child Profiles';
}

/// Theme-related constants
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(0xFF0D47A1);
  static const Color accentColor = Colors.lightBlueAccent;
  static const Color successColor = Colors.green;
  static const Color pendingColor = Colors.orange;
  static const Color absentColor = Colors.redAccent;
  static const Color cardBackground = Color(0xFF1E2A44);
  static const double cardBorderRadius = 20.0;
  static const double blurSigma = 5.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double elevation = 8.0;
  static const double iconSize = 28.0;

  static var avatarRadius;
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
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(2, 2),
            blurRadius: AppTheme.blurSigma,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          border: Border.all(color: Colors.white.withAlpha(50), width: 1.0),
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  child.profileImage.isNotEmpty
                      ? NetworkImage(
                        '${ApiConfig.baseUrl}/students/${child.profileImage}', // ✅ Use centralized URL
                      )
                      : null,
              onBackgroundImageError:
                  (_, __) => const Icon(
                    Icons.error,
                    color: AppTheme.absentColor,
                    size: AppTheme.iconSize,
                  ),
              child:
                  child.profileImage.isEmpty
                      ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: AppTheme.iconSize * 2,
                      )
                      : null,
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
                color: Colors.white.withAlpha(204),
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
    );
  }

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
              color: Colors.white.withAlpha(204),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

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
  final String parentContact;
  final String parentEmail;

  const ChildSummaryScreen({
    super.key,
    required this.parentContact,
    required this.parentEmail,
  });

  @override
  State<ChildSummaryScreen> createState() => _ChildSummaryScreenState();
}

class _ChildSummaryScreenState extends State<ChildSummaryScreen> {
  bool _isLoading = false;
  List<ChildData> _children = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print(
      'Parent Email: ${widget.parentEmail}, Parent Contact: ${widget.parentContact}',
    );
    _fetchChildData();
  }

  Future<void> _fetchChildData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _children = [];
    });

    final client = http.Client();
    try {
      // Step 1: Fetch students by parent contact and email
      final parentResponse = await client
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/students/parent-login', // ✅ Use centralized URL
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

      print(
        'Parent Login API Response (Status: ${parentResponse.statusCode}): ${parentResponse.body}',
      );

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
      final students = parentData['students'] as List<dynamic>? ?? [];

      if (students.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No children found for this parent';
        });
        client.close();
        return;
      }

      // Step 2: Fetch attendance and bus route for each student
      final today = DateTime.now().toIso8601String().split('T')[0];
      final List<ChildData> children = [];

      for (var student in students) {
        // Fetch attendance
        final attendanceResponse = await client
            .post(
              Uri.parse(
                '${ApiConfig.baseUrl}/students/attendance/date', // ✅ Use centralized URL
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'date': today,
                'studentIds': [student['_id']],
              }),
            )
            .timeout(const Duration(seconds: 10));

        String attendanceStatus = 'Absent';
        if (attendanceResponse.statusCode == 200) {
          final attendanceData =
              jsonDecode(attendanceResponse.body) as List<dynamic>;
          if (attendanceData.isNotEmpty) {
            attendanceStatus =
                attendanceData[0]['status'] as String? ?? 'Absent';
          }
        } else {
          print(
            'Attendance API failed (Status: ${attendanceResponse.statusCode}): ${attendanceResponse.body}',
          );
        }

        // Fetch bus route
        final routeResponse = await client
            .get(
              Uri.parse(
                '${ApiConfig.baseUrl}/students/route-by-env/${student['envNumber']}', // ✅ Use centralized URL
              ),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 10));

        String busNumber = 'Not Assigned';
        if (routeResponse.statusCode == 200) {
          final routeData =
              jsonDecode(routeResponse.body) as Map<String, dynamic>;
          busNumber = routeData['route'] as String? ?? 'Not Assigned';
        } else {
          print(
            'Route API failed (Status: ${routeResponse.statusCode}): ${routeResponse.body}',
          );
        }

        // Fetch bus status
        final busStatusResponse = await client
            .get(
              Uri.parse(
                '${ApiConfig.baseUrl}/students/bus-status/${student['envNumber']}', // ✅ Use centralized URL
              ),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 10));

        String busStatus = 'Not Yet Boarded';
        if (busStatusResponse.statusCode == 200) {
          final busStatusData =
              jsonDecode(busStatusResponse.body) as Map<String, dynamic>;
          busStatus = busStatusData['status'] as String? ?? 'Not Yet Boarded';
        } else {
          print(
            'Bus Status API failed (Status: ${busStatusResponse.statusCode}): ${busStatusResponse.body}',
          );
        }

        children.add(
          ChildData(
            name: student['name'] as String? ?? 'Unknown',
            className: student['department'] as String? ?? 'N/A',
            busNumber: busNumber,
            attendanceStatus: attendanceStatus,
            busStatus: busStatus,
            profileImage: student['imagePath'] as String? ?? '',
          ),
        );
      }

      if (!mounted) {
        setState(() => _isLoading = false);
        client.close();
        return;
      }

      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        client.close();
        return;
      }
      print('Exception in _fetchChildData: $e');
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
        title: const Text(
          ChildSummaryConfig.screenTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundColor.withAlpha(76),
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
                            color: Colors.black.withOpacity(0.1),
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
                            color: Colors.white.withAlpha(204),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing),
                        ElevatedButton(
                          onPressed: _fetchChildData,
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
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(2, 2),
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
  final String attendanceStatus;
  final String busStatus;
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
