import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_bus_management/login.dart';
import 'live_bus_location_screen.dart';
import 'child_summary_screen.dart';
import 'recent_notifications_screen.dart';
import 'attendance_summary_screen.dart';
import 'pickup_drop_timings_screen.dart';
import 'contact_support_screen.dart';
import 'quick_actions_screen.dart';
import 'dart:ui';

/// Mock authentication service for logout functionality
class AuthService {
  /// Clears authentication data (e.g., token)
  static Future<void> logout() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove('auth_token'); // Example: Clear auth token
  }
}

/// Configuration class for dashboard-related constants
class DashboardConfig {
  static const String title = 'Parent Dashboard';
  static List<Map<String, dynamic>> navigationItems(
    BuildContext context,
    String parentContact,
    String parentEmail,
  ) {
    return [
      const {
        'icon': Icons.directions_bus,
        'title': 'Live Bus Location',
        'subtitle': 'Track your child\'s bus in real-time',
        'screen': LiveBusLocationScreen(),
      },
      {
        'icon': Icons.person,
        'title': 'Child Summary',
        'subtitle': 'View your child\'s details and status',
        'screen': ChildSummaryScreen(
          parentContact: parentContact,
          parentEmail: parentEmail,
        ),
      },
      const {
        'icon': Icons.notifications,
        'title': 'Recent Notifications',
        'subtitle': 'Check latest alerts and updates',
        'screen': RecentNotificationsScreen(),
      },
      {
        'icon': Icons.event,
        'title': 'Attendance Summary',
        'subtitle': 'View weekly attendance and alerts',
        'screen': AttendanceSummaryScreen(
          parentContact: parentContact,
          parentEmail: parentEmail,
        ),
      },
      const {
        'icon': Icons.access_time,
        'title': 'Pickup & Drop Timings',
        'subtitle': 'Today\'s schedule and status',
        'screen': PickupDropTimingsScreen(),
      },
      const {
        'icon': Icons.support_agent,
        'title': 'Contact & Support',
        'subtitle': 'Reach out to transport admin or driver',
        'screen': ContactSupportScreen(),
      },
      {
        'icon': Icons.menu,
        'title': 'Quick Actions',
        'subtitle': 'Manage settings and more',
        'screen': QuickActionsScreen(
          parentContact: parentContact,
          parentEmail: parentEmail,
        ),
      },
    ];
  }
}

/// Theme-related constants
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(0xFF0D47A1); // Colors.blue[900]
  static const Color accentColor = Colors.lightBlueAccent;
  static const Color successColor = Colors.green;
  static const Color pendingColor = Colors.orange;
  static const Color absentColor = Colors.redAccent;
  static const Color cardBackground = Color(
    0xFF1E2A44,
  ); // Darker blue for cards
  static const double cardBorderRadius = 20.0;
  static const double blurSigma = 5.0; // Reduced for performance
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double elevation = 8.0;
  static const double iconSize = 28.0;
}

class ParentDashboardScreen extends StatelessWidget {
  final String parentContact;
  final String parentEmail;

  const ParentDashboardScreen({
    super.key,
    required this.parentContact,
    required this.parentEmail,
  });

  /// Shows a confirmation dialog for logout
  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            ),
            backgroundColor: AppTheme.cardBackground,
            title: Text(
              'Logout',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.8), // 204/255
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.accentColor,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Logout',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.absentColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  /// Handles logout action with confirmation and redirect to LoginScreen
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await _showLogoutDialog(context);
    if (confirmed == true && context.mounted) {
      try {
        await AuthService.logout();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Logged out successfully',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 2),
            ),
          );
          // Navigate to LoginScreen and remove all previous routes
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error logging out: $e',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              backgroundColor: AppTheme.absentColor,
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
        title: Text(
          DashboardConfig.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor.withValues(
          alpha: 0.3,
        ), // 76/255
        centerTitle: true,
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
              Icons.logout,
              color: Colors.white,
              size: AppTheme.iconSize,
            ),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.backgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation Cards Section
                Text(
                  'Quick Links',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing),
                ...DashboardConfig.navigationItems(
                  context,
                  parentContact,
                  parentEmail,
                ).asMap().entries.map(
                  (entry) => Column(
                    children: [
                      _buildNavigationCard(
                        context,
                        icon: entry.value['icon'] as IconData,
                        title: entry.value['title'] as String,
                        subtitle: entry.value['subtitle'] as String,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        entry.value['screen'] as Widget,
                              ),
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacing),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a navigation card with consistent styling
  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing / 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), // 0.1 * 255 = 25.5
            offset: const Offset(2, 2),
            blurRadius: AppTheme.blurSigma,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.078), // 20/255
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.196),
              width: 1.0,
            ), // 50/255
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: AppTheme.iconSize,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: AppTheme.spacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(
                                alpha: 0.8,
                              ), // 204/255
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: AppTheme.iconSize / 1.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
