import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
// NOTE: Assuming ApiConfig is defined elsewhere in the user's environment.
import 'package:campus_bus_management/config/api_config.dart';
import 'package:intl/intl.dart';

/// Configuration class for notifications
class NotificationsConfig {
  static const String screenTitle = 'Recent Notifications';
  static const String headerTitle = 'Notifications';
}

/// Theme-related constants updated with the user's dark theme palette
class AppTheme {
  static const Color primaryColor = Color(0xFF1E88E5); // Bright Blue
  static const Color backgroundColor = Color(0xFF0C1337); // Very Dark Blue
  static const Color accentColor = Color(0xFF80D8FF); // Light Cyan/Blue Accent
  static const Color cardBackground = Color(
    0xFF16204C,
  ); // Darker Blue for cards

  // New specific icon colors for visual importance
  static const Color iconColor1 = Color(
    0xFF69F0AE,
  ); // Bright Green (General/Info)
  static const Color iconColor2 = Color(0xFFFFC107); // Amber (Warning/Schedule)
  static const Color iconColor3 = Color(
    0xFFFF5252,
  ); // Red Accent (Emergency/Critical)

  // Using the Red Accent color for the dismiss background
  static const Color dismissColor = iconColor3;

  static const double cardBorderRadius = 20.0;
  static const double blurSigma = 10.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double iconSize = 28.0;
}

/// Reusable notification card widget
class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  // onMarkRead removed as per request
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  /// Determines the icon based on notification type
  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pickup':
      case 'emergency':
        return Icons.directions_bus;
      case 'drop':
        return Icons.home;
      case 'delay':
        return Icons.warning;
      case 'route change':
        return Icons.alt_route;
      case 'holiday':
        return Icons.calendar_today;
      case 'general info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  /// Determines the icon color based on notification type for visual distinction
  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
      case 'delay':
        return AppTheme.iconColor3; // Red for critical/urgent
      case 'pickup':
      case 'drop':
      case 'route change':
        return AppTheme.iconColor2; // Amber for schedule/route info
      case 'holiday':
      case 'general info':
      default:
        return AppTheme.iconColor1; // Green for general info
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationType = notification['type'] as String? ?? 'default';
    final iconColor = _getNotificationColor(notificationType);
    final iconData = _getNotificationIcon(notificationType);

    return Dismissible(
      key: Key(
        notification['_id']?.toString() ??
            'notification_${UniqueKey().toString()}',
      ),
      direction: DismissDirection.endToStart,
      background: Container(
        // Use the new red color for the dismiss background
        color: AppTheme.dismissColor.withOpacity(0.8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.cardPadding * 1.5),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      onDismissed: (direction) => onDismiss(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing / 2),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: const Offset(4, 4),
              blurRadius: AppTheme.blurSigma,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          child: BackdropFilter(
            // Reduced blur to keep the card content clear on a dark background
            filter: ImageFilter.blur(
              sigmaX: AppTheme.blurSigma / 2,
              sigmaY: AppTheme.blurSigma / 2,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                // Use a subtle accent-colored border for the glass effect
                color: AppTheme.accentColor.withAlpha(20),
                border: Border.all(
                  color: AppTheme.accentColor.withAlpha(50),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Icon container with colored background
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: AppTheme.iconSize - 4,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['message'] as String,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(
                            DateTime.tryParse(
                                  notification['date']?.toString() ?? '',
                                ) ??
                                DateTime.now(),
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Removed colored status indicator (read/pending dot)
                  // Removed Mark Read IconButton
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen to display recent notifications
class RecentNotificationsScreen extends StatefulWidget {
  const RecentNotificationsScreen({super.key});

  @override
  State<RecentNotificationsScreen> createState() =>
      _RecentNotificationsScreenState();
}

class _RecentNotificationsScreenState extends State<RecentNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // NOTE: This method remains conceptually the same, as requested.
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/notifications/view/Parents"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _notifications =
                data
                    .map((item) {
                      return (item is Map)
                          ? item.map(
                            (key, value) => MapEntry(key.toString(), value),
                          )
                          : {
                            'message': 'Invalid notification data',
                            'type': 'Error',
                            'date': DateTime.now().toIso8601String(),
                          };
                    })
                    .cast<Map<String, dynamic>>()
                    .toList();
            _isLoading = false;
          });
        } else {
          throw Exception(
            "Invalid response format: Expected a List, got ${data.runtimeType}",
          );
        }
      } else {
        throw Exception("Failed to load notifications: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // In a real app, use a less intrusive error reporting mechanism
      // or a custom dialog instead of SnackBar.
      // Keeping SnackBar since it was used in the original logic.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading notifications: $e")),
      );
    }
  }

  // Removed _markAllRead() method as per request

  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          NotificationsConfig.screenTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // Use primaryColor for the AppBar background (subtle difference from main background)
        backgroundColor: const Color(0xFF0C1337).withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            // Apply blur to AppBar for a glass effect
            filter: ImageFilter.blur(
              sigmaX: AppTheme.blurSigma / 2,
              sigmaY: AppTheme.blurSigma / 2,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          // Removed Mark All Read button
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              tooltip: 'Clear All',
              onPressed: _clearAllNotifications,
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.backgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentColor,
                      ),
                    )
                    : _notifications.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: AppTheme.accentColor.withAlpha(150),
                          ),
                          const SizedBox(height: AppTheme.spacing),
                          Text(
                            'No new notifications!',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Colors.white.withAlpha(204),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return NotificationCard(
                          notification: notification,
                          // onMarkRead removed
                          onDismiss: () {
                            setState(() {
                              _notifications.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${notification['message']} deleted',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ),
      ),
    );
  }
}
