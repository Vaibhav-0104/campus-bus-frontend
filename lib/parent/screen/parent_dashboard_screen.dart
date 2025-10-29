import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/login.dart';
import 'live_bus_location_screen.dart';
import 'child_summary_screen.dart';
import 'recent_notifications_screen.dart';
import 'attendance_summary_screen.dart';
import 'contact_support_screen.dart';
import 'dart:ui';
import 'package:campus_bus_management/config/api_config.dart';

/// Mock Auth Service
class AuthService {
  static Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}

/// Purple Theme
class AppTheme {
  static const Color primary = Color(0xFF6A1B9A);
  static const Color lightPurple = Color(0xFFCE93D8);
  static const Color background = Color(0xFFF8F5FF);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF4A148C);
  static const Color textSecondary = Color(0xFF7E57C2);

  static const double borderRadius = 20.0;
  static const double cardPadding = 20.0;
  static const double spacing = 16.0;
  static const double blur = 12.0;
}

class DashboardConfig {
  static const String title = 'Parents Dashboard';

  static List<Map<String, dynamic>> navigationItems(
    BuildContext context,
    String parentContact,
    String parentEmail,
  ) {
    return [
      {
        'icon': Icons.directions_bus_filled_rounded,
        'title': 'Live Bus Location',
        'subtitle': 'Track your child\'s bus in real-time',
        'screen': const LiveBusLocationScreen(),
        'iconColor': AppTheme.primary,
      },
      {
        'icon': Icons.person_pin_circle_rounded,
        'title': 'Child Summary',
        'subtitle': 'View child details & fees status',
        'screen': ChildSummaryScreen(
          parentContact: parentContact,
          parentEmail: parentEmail,
        ),
        'iconColor': AppTheme.primary,
      },
      {
        'icon': Icons.notifications_active_rounded,
        'title': 'Recent Notifications',
        'subtitle': 'Latest alerts & updates',
        'screen': const RecentNotificationsScreen(),
        'iconColor': Colors.redAccent,
      },
      {
        'icon': Icons.access_time_filled_rounded,
        'title': 'Attendance Summary',
        'subtitle': 'Weekly attendance & reports',
        'screen': AttendanceSummaryScreen(
          parentContact: parentContact,
          parentEmail: parentEmail,
        ),
        'iconColor': AppTheme.lightPurple,
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'Contact & Support',
        'subtitle': 'Call driver or admin',
        'screen': const ContactSupportScreen(),
        'iconColor': Colors.blueAccent,
      },
    ];
  }
}

class ParentDashboardScreen extends StatefulWidget {
  final String parentContact;
  final String parentEmail;

  const ParentDashboardScreen({
    super.key,
    required this.parentContact,
    required this.parentEmail,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  bool _isLoading = true;
  ChildData? _child;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchChildForDashboard();
  }

  Future<void> _fetchChildForDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final client = http.Client();
    try {
      final response = await client
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

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load child data';
        });
        return;
      }

      final data = jsonDecode(response.body);
      final students = data['students'] as List<dynamic>? ?? [];

      if (students.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No child registered';
        });
        return;
      }

      final student = students[0];

      // Fetch Bus Route
      String busNumber = 'Not Assigned';
      try {
        final routeRes = await client.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/students/route-by-env/${student['envNumber']}',
          ),
        );
        if (routeRes.statusCode == 200) {
          final routeData = jsonDecode(routeRes.body);
          busNumber = routeData['route'] ?? 'Not Assigned';
        }
      } catch (e) {
        busNumber = 'N/A';
      }

      final child = ChildData(
        name: student['name'] ?? 'Unknown',
        className: student['department'] ?? 'N/A',
        busNumber: busNumber,
      );

      setState(() {
        _child = child;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Network error';
        });
      }
    } finally {
      client.close();
    }
  }

  // Logout Dialog
  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: const Text(
              'Logout',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await _showLogoutDialog(context);
    if (confirmed == true && context.mounted) {
      await AuthService.logout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: AppTheme.primary,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = DashboardConfig.navigationItems(
      context,
      widget.parentContact,
      widget.parentEmail,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          DashboardConfig.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            children: [
              // Child Info Card - Only Name + Class + Bus
              _isLoading
                  ? GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              '?',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 140,
                                  height: 20,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 100,
                                  height: 16,
                                  color: Colors.grey.shade300,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : _error != null
                  ? GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  )
                  : _child != null
                  ? GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.cardPadding),
                      child: Row(
                        children: [
                          // ONLY FIRST LETTER – NO IMAGE
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              _child!.name.isNotEmpty
                                  ? _child!.name
                                      .trim()
                                      .split(' ')
                                      .first[0]
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Child Name
                                Text(
                                  _child!.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Class + Bus
                                Text(
                                  '${_child!.className} • Bus: ${_child!.busNumber}',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : const SizedBox(),

              const SizedBox(height: AppTheme.spacing),

              // Navigation Cards
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacing),
                      child: NavigationGlassCard(
                        icon: item['icon'],
                        title: item['title'],
                        subtitle: item['subtitle'],
                        iconColor: item['iconColor'],
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => item['screen']),
                            ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Navigation Card
class NavigationGlassCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const NavigationGlassCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

/// Glassmorphism Card
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const GlassCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppTheme.blur, sigmaY: AppTheme.blur),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              onTap: onTap,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ChildData Model (Minimal – No profileImage)
class ChildData {
  final String name;
  final String className;
  final String busNumber;

  ChildData({
    required this.name,
    required this.className,
    required this.busNumber,
  });
}
