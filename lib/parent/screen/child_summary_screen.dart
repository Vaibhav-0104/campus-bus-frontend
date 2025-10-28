import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Assuming the environment provides this config file
import 'package:campus_bus_management/config/api_config.dart';

/// Configuration class for the Parent Dashboard
class ChildSummaryConfig {
  static const String screenTitle = 'Parent Dashboard';
  static const String headerTitle = 'Your Children';
}

/// Theme-related constants (Updated to new deep blue theme)
class AppTheme {
  static const Color primaryColor = Color(0xFF1E88E5); // Bright Blue
  static const Color backgroundColor = Color(0xFF0C1337); // Very Dark Blue
  static const Color accentColor = Color(0xFF80D8FF); // Light Cyan/Blue Accent
  static const Color successColor = Colors.greenAccent;
  static const Color pendingColor = Colors.orangeAccent;
  static const Color absentColor = Colors.redAccent;
  static const Color cardBackground = Color(0xFF16204C); // Card Background
  static const double cardBorderRadius = 16.0;
  static const double blurSigma = 5.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double elevation = 8.0;
  static const double iconSize = 24.0;
}

/// Reusable child card widget (Dashboard Summary Style)
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
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: AppTheme.blurSigma,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Name and Class (Primary Focus)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Child Name
                Text(
                  child.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700, // Extra bold for prominence
                    fontSize: 19,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Class Name
                Text(
                  'Grade: ${child.className}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Right side: Assigned Bus (Action/Info)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_bus,
                color: AppTheme.accentColor,
                size: AppTheme.iconSize,
              ),
              const SizedBox(width: 8),
              // Bus Number (Highlighted)
              Text(
                child.busNumber,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ],
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

  // API fetching logic remains unchanged
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
            Uri.parse('${ApiConfig.baseUrl}/students/parent-login'),
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

        // Fetch bus route
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

        // Fetch bus status (Keeping this call even though status is not displayed, as requested)
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
        // Use a semi-transparent version of the dark background color for the app bar
        backgroundColor: AppTheme.backgroundColor.withAlpha(128),
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
              color: AppTheme.accentColor,
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
        color: AppTheme.backgroundColor, // Applied new background color
        child: SafeArea(
          child:
              _isLoading
                  ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.cardPadding * 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardBorderRadius,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
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
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing * 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.accentColor.withOpacity(0.8),
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
                              foregroundColor: AppTheme.backgroundColor,
                              backgroundColor: AppTheme.accentColor,
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
                        // Header Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: AppTheme.spacing,
                              bottom: AppTheme.spacing * 1.5,
                            ),
                            child: Text(
                              ChildSummaryConfig.headerTitle,
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 30,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        // Children List
                        _children.isEmpty
                            ? SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'No Children Registered',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color: Colors.white54,
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
