import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_bus_management/login.dart';
import 'live_bus_location_screen.dart';
import 'child_summary_screen.dart';
import 'recent_notifications_screen.dart';
import 'attendance_summary_screen.dart';
// Still imported but not used in config
import 'contact_support_screen.dart';
// Still imported but not used in config
import 'dart:ui';

/// Mock authentication service for logout functionality
class AuthService {
  /// Clears authentication data (e.g., token)
  static Future<void> logout() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove('auth_token'); // Example: Clear auth token
  }
}

/// Theme-related constants for a dark, modern look
class AppTheme {
  static const Color primaryColor = Color(0xFF1E88E5); // Bright Blue
  static const Color backgroundColor = Color(0xFF0C1337); // Very Dark Blue
  static const Color accentColor = Color(0xFF80D8FF); // Light Cyan/Blue Accent
  static const Color cardBackground = Color(
    0xFF16204C,
  ); // Darker Blue for cards

  // Unique Icon Colors for each card
  static const Color iconColor1 = Color(
    0xFF69F0AE,
  ); // Live Location - Green Accent
  static const Color iconColor2 = Color(0xFFFFC107); // Child Summary - Amber
  static const Color iconColor3 = Color(
    0xFFFF5252,
  ); // Notifications - Red Accent
  static const Color iconColor4 = Color(0xFF9C27B0); // Attendance - Purple
  static const Color iconColor5 = Color(0xFF4FC3F7); // Support - Light Blue

  static const double cardBorderRadius = 15.0;
  static const double blurSigma = 8.0;
  static const double cardPadding = 18.0;
  static const double spacing = 20.0;
  static const double elevation = 12.0;
  static const double iconSize = 32.0;
}

/// Configuration class for dashboard-related constants
class DashboardConfig {
  static const String title = 'Parent Dashboard';

  static List<Map<String, dynamic>> navigationItems(
    BuildContext context,
    String parentContact,
    String parentEmail,
  ) {
    // Items 'Pickup & Drop Timings' and 'Quick Actions' have been removed.
    // Unique icon colors are added to each item.
    return [
      {
        'icon': Icons.directions_bus_filled_rounded,
        'title': 'Live Bus Location',
        'subtitle': 'Track your child\'s bus in real-time',
        'screen': LiveBusLocationScreen(),
        'iconColor': AppTheme.iconColor1,
      },
      {
        'icon': Icons.person_pin_circle_rounded,
        'title': 'Child Summary',
        'subtitle': 'View your child\'s details and status',
        'screen': ChildSummaryScreen(
          parentContact: parentContact,
          parentEmail: parentEmail,
        ),
        'iconColor': AppTheme.iconColor2,
      },
      {
        'icon': Icons.notifications_active_rounded,
        'title': 'Recent Notifications',
        'subtitle': 'Check latest alerts and updates',
        'screen': RecentNotificationsScreen(),
        'iconColor': AppTheme.iconColor3,
      },
      {
        'icon': Icons.access_time_filled_rounded,
        'title': 'Attendance Summary',
        'subtitle': 'View weekly attendance and alerts',
        'screen': AttendanceSummaryScreen(
          parentContact: parentContact,
          parentEmail: parentEmail,
        ),
        'iconColor': AppTheme.iconColor4,
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'Contact & Support',
        'subtitle': 'Reach out to transport admin or driver',
        'screen': ContactSupportScreen(),
        'iconColor': AppTheme.iconColor5,
      },
    ];
  }
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
                fontSize: 20,
              ),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.8), // Corrected usage
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
              backgroundColor: AppTheme.iconColor1, // Use success color
              duration: const Duration(seconds: 2),
            ),
          );
          // Navigate to LoginScreen and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
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
              backgroundColor: AppTheme.iconColor3, // Use error color
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
      // Ensure the background is the primary dark theme
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          DashboardConfig.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        // Glassmorphism effect for AppBar
        backgroundColor: AppTheme.backgroundColor.withOpacity(0.3),
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
              Icons.logout_rounded,
              color: AppTheme.iconColor3, // Red color for logout
              size: AppTheme.iconSize * 0.9,
            ),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false, // AppBar handles the top padding
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: kToolbarHeight + 2, // Space below the glassmorphic app bar
            left: AppTheme.cardPadding,
            right: AppTheme.cardPadding,
            bottom: AppTheme.cardPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppTheme.spacing * 0),

              // Navigation Cards Section (Using Grid for better layout on wider screens if possible, but keeping list structure for simplicity and standard mobile layout)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      1, // Sticking to one column for full-width cards
                  childAspectRatio: 3.5,
                  mainAxisSpacing: AppTheme.spacing,
                ),
                itemCount:
                    DashboardConfig.navigationItems(
                      context,
                      parentContact,
                      parentEmail,
                    ).length,
                itemBuilder: (context, index) {
                  final item =
                      DashboardConfig.navigationItems(
                        context,
                        parentContact,
                        parentEmail,
                      )[index];
                  return _buildNavigationCard(
                    context,
                    icon: item['icon'] as IconData,
                    title: item['title'] as String,
                    subtitle: item['subtitle'] as String,
                    iconColor: item['iconColor'] as Color, // Pass unique color
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => item['screen'] as Widget,
                          ),
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a navigation card with consistent styling and unique icon color
  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero, // Margin is handled by GridView spacing
      elevation: AppTheme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
      ),
      color: AppTheme.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            // Subtle inner glow/border effect
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // Icon Container with colored background for emphasis
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: AppTheme.iconSize,
                  color: iconColor, // Use the unique iconColor
                ),
              ),
              const SizedBox(width: AppTheme.spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.6),
                size: AppTheme.iconSize / 1.8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
