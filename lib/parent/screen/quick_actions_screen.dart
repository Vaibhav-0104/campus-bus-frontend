import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_bus_management/login.dart';
import 'package:campus_bus_management/parent/screen/update_profile_screen.dart';
import 'package:campus_bus_management/parent/screen/settings_screen.dart';
import 'package:campus_bus_management/parent/screen/view_detailed_attendance_screen.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'child_summary_screen.dart'; // Import to use ChildSummaryConfig

/// Configuration class for quick actions
class QuickActionsConfig {
  static const String screenTitle = 'Quick Actions';
  static const String headerTitle = 'Quick Actions Overview';
  static const List<Map<String, dynamic>> actions = [
    {
      'icon': Icons.event,
      'title': 'View Detailed Attendance',
      'color': Colors.blue,
      'screen': null, // Handled dynamically in onTap
    },
    {
      'icon': Icons.person,
      'title': 'Update Profile / Child Info',
      'color': Colors.blue,
      'screen': UpdateProfileScreen(),
    },
    {
      'icon': Icons.settings,
      'title': 'Settings',
      'color': Colors.blue,
      'screen': SettingsScreen(),
    },
    {
      'icon': Icons.logout,
      'title': 'Logout',
      'color': Colors.redAccent,
      'screen': null, // Handled by logout logic
    },
  ];
}

/// Theme-related constants
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(0xFF0D47A1); // Deep blue
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
  static const double iconSize = 30.0;
}

/// Mock authentication service for logout
class AuthService {
  static Future<void> logout() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove('auth_token');
  }
}

/// Reusable action button widget
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                  color: Colors.white.withValues(alpha: 0.298),
                  width: 1.5,
                ), // 76/255
              ),
              child: Row(
                children: [
                  Icon(icon, size: AppTheme.iconSize, color: color),
                  const SizedBox(width: AppTheme.spacing),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
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

/// Screen for quick actions with navigation and logout
class QuickActionsScreen extends StatefulWidget {
  final String parentContact;
  final String parentEmail;

  const QuickActionsScreen({
    super.key,
    required this.parentContact,
    required this.parentEmail,
  });

  @override
  State<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends State<QuickActionsScreen> {
  /// Fetches student data for navigation to ViewDetailedAttendanceScreen
  Future<Map<String, String>?> _fetchStudentData() async {
    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(
              '${ChildSummaryConfig.baseUrl}/api/students/parent-login',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'parentEmail': widget.parentEmail,
              'parentContact': widget.parentContact,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final parentData = jsonDecode(response.body) as Map<String, dynamic>;
        final students = parentData['students'] as List<dynamic>? ?? [];
        if (students.isNotEmpty) {
          final student = students.first as Map<String, dynamic>;
          return {
            'studentId': student['_id'] as String,
            'childName': student['name'] as String? ?? 'Unknown',
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Shows logout confirmation dialog
  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            ),
            backgroundColor: AppTheme.cardBackground,
            contentPadding: const EdgeInsets.all(AppTheme.cardPadding),
            title: Text(
              'Confirm Logout',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8), // 204/255
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Cancel',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppTheme.cardBorderRadius / 2,
                    ),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  /// Handles logout with confirmation
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await _showLogoutDialog(context);
    if (confirmed == true && mounted) {
      try {
        await AuthService.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(QuickActionsConfig.screenTitle),
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
                    child: Text(
                      QuickActionsConfig.headerTitle,
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
                  // Action Buttons
                  ...QuickActionsConfig.actions.map(
                    (action) => ActionButton(
                      icon: action['icon'] as IconData,
                      title: action['title'] as String,
                      color: action['color'] as Color,
                      onTap: () async {
                        if (action['title'] == 'Logout') {
                          _handleLogout(context);
                        } else if (action['title'] ==
                            'View Detailed Attendance') {
                          final studentData = await _fetchStudentData();
                          if (studentData != null && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ViewDetailedAttendanceScreen(
                                      studentId: studentData['studentId']!,
                                      childName: studentData['childName']!,
                                    ),
                              ),
                            );
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('No student data found'),
                                  backgroundColor: Colors.redAccent,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } else if (action['screen'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => action['screen'] as Widget,
                            ),
                          );
                        }
                      },
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
