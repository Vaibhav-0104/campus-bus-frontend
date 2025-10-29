import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/config/api_config.dart';
import 'package:intl/intl.dart';

/// Configuration class for notifications
class NotificationsConfig {
  static const String screenTitle = 'Recent Notifications';
  static const String headerTitle = 'Notifications';
}

/// Purple Theme (Matches Dashboard)
class AppTheme {
  static const Color primary = Color(0xFF6A1B9A); // Deep Purple
  static const Color lightPurple = Color(0xFFCE93D8); // Light Purple Accent
  static const Color background = Color(0xFFF8F5FF); // Light Purple BG
  static const Color cardBg = Colors.white; // White Cards
  static const Color textPrimary = Color(0xFF4A148C); // Dark Purple Text
  static const Color textSecondary = Color(0xFF7E57C2);

  static const Color infoColor = Color(0xFF66BB6A); // Green
  static const Color warningColor = Color(0xFFFFC107); // Amber
  static const Color emergencyColor = Color(0xFFFF5252); // Red

  static const Color dismissColor = emergencyColor;

  static const double cardBorderRadius = 20.0;
  static const double blur = 10.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double iconSize = 28.0;
}

/// Reusable notification card widget
class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

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

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
      case 'delay':
        return AppTheme.emergencyColor;
      case 'pickup':
      case 'drop':
      case 'route change':
        return AppTheme.warningColor;
      case 'holiday':
      case 'general info':
      default:
        return AppTheme.infoColor;
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
        color: AppTheme.dismissColor.withValues(alpha: 0.8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.cardPadding * 1.5),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      onDismissed: (direction) => onDismiss(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing / 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppTheme.blur / 2,
              sigmaY: AppTheme.blur / 2,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: AppTheme.cardBg.withValues(alpha: 0.9),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
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
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
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
                            color: AppTheme.textSecondary,
                            fontSize: 12,
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

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);

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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading notifications: $e")),
      );
    }
  }

  void _clearAllNotifications() {
    setState(() => _notifications.clear());
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          NotificationsConfig.screenTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child:
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.lightPurple,
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
                          color: AppTheme.lightPurple.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: AppTheme.spacing),
                        const Text(
                          'No new notifications!',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
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
                        onDismiss: () {
                          setState(() => _notifications.removeAt(index));
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
    );
  }
}
