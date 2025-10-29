import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/config/api_config.dart';

/// Configuration class for the Parent Dashboard
class ChildSummaryConfig {
  static const String screenTitle = 'Parent Dashboard';
  static const String headerTitle = 'Your Children';
}

/// Purple Theme (Matches Dashboard)
class AppTheme {
  static const Color primary = Color(0xFF6A1B9A); // Deep Purple
  static const Color lightPurple = Color(0xFFCE93D8); // Light Purple Accent
  static const Color background = Color(0xFFF8F5FF); // Light Purple BG
  static const Color cardBg = Colors.white; // White Cards
  static const Color textPrimary = Color(0xFF4A148C); // Dark Purple Text
  static const Color textSecondary = Color(0xFF7E57C2);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color pendingColor = Color(0xFFFFA726);
  static const Color absentColor = Color(0xFFFF5252);

  static const double cardBorderRadius = 20.0;
  static const double blur = 12.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double iconSize = 28.0;
}

/// Reusable child card widget
class ChildCard extends StatelessWidget {
  final ChildData child;

  const ChildCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing * 0.75),
      padding: const EdgeInsets.symmetric(
        vertical: 20.0,
        horizontal: AppTheme.cardPadding,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.blur,
            sigmaY: AppTheme.blur,
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            color: AppTheme.cardBg.withValues(alpha: 0.9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grade: ${child.className}',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_bus,
                      color: AppTheme.lightPurple,
                      size: AppTheme.iconSize,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      child.busNumber,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

      final today = DateTime.now().toIso8601String().split('T')[0];
      final List<ChildData> children = [];

      for (var student in students) {
        final attendanceResponse = await client
            .post(
              Uri.parse('${ApiConfig.baseUrl}/students/attendance/date'),
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

        final routeResponse = await client
            .get(
              Uri.parse(
                '${ApiConfig.baseUrl}/students/route-by-env/${student['envNumber']}',
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

        final busStatusResponse = await client
            .get(
              Uri.parse(
                '${ApiConfig.baseUrl}/students/bus-status/${student['envNumber']}',
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

      if (!mounted) return;

      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          ChildSummaryConfig.screenTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchChildData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.cardPadding * 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(
                        AppTheme.cardBorderRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: AppTheme.primary,
                    ),
                  ),
                )
                : _errorMessage != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing * 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacing * 1.5),
                        ElevatedButton.icon(
                          onPressed: _fetchChildData,
                          icon: const Icon(Icons.cached, size: 20),
                          label: const Text('Retry Fetching Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.cardBorderRadius,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(AppTheme.cardPadding),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: AppTheme.spacing,
                            bottom: AppTheme.spacing * 1.5,
                          ),
                          child: Text(
                            ChildSummaryConfig.headerTitle,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      _children.isEmpty
                          ? const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'No Children Registered',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )
                          : SliverList(
                            delegate: SliverChildListDelegate(
                              _children
                                  .map((child) => ChildCard(child: child))
                                  .toList(),
                            ),
                          ),
                    ],
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
