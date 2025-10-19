import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Configuration class for notifications
class NotificationsConfig {
  static const String screenTitle = 'Recent Notifications';
  static const String headerTitle = 'Notifications';
}

/// Theme-related constants
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(0xFF0D47A1); // Deep blue
  static const Color accentColor = Colors.lightBlueAccent;
  static const Color successColor = Colors.green;
  static const Color pendingColor = Colors.orange;
  static const Color absentColor = Colors.redAccent;
  static const Color cardBackground = Color(
    0xFF1E2A44,
  ); // Darker blue for cards
  static const double cardBorderRadius = 20.0;
  static const double blurSigma = 10.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double elevation = 8.0;
  static const double iconSize = 28.0;
}

/// Reusable notification card widget
class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onMarkRead,
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

  @override
  Widget build(BuildContext context) {
    final isRead = notification['read'] as bool? ?? false;
    return Dismissible(
      key: Key(notification['_id'].toString()),
      background: Container(
        color: AppTheme.absentColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.cardPadding),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => onDismiss(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing / 2),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(4, 4),
              blurRadius: AppTheme.blurSigma,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
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
                color: Colors.white.withAlpha(26),
                border: Border.all(
                  color: Colors.white.withAlpha(76),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getNotificationIcon(notification['type'] as String),
                    color: AppTheme.accentColor,
                    size: AppTheme.iconSize,
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
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(
                            DateTime.tryParse(notification['date'] ?? '') ??
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
                  const SizedBox(width: AppTheme.spacing),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color:
                          isRead
                              ? AppTheme.successColor
                              : AppTheme.pendingColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isRead ? Icons.check : Icons.mark_email_read,
                      color: Colors.white,
                      size: AppTheme.iconSize,
                    ),
                    onPressed: onMarkRead,
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
            _notifications = List<Map<String, dynamic>>.from(
              data.map(
                (item) => {
                  ...item,
                  'read': false, // Assuming notifications are initially unread
                },
              ),
            );
            _isLoading = false;
          });
        } else {
          throw Exception("Invalid response format");
        }
      } else {
        throw Exception("Failed to load notifications: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading notifications: $e")),
      );
    }
  }

  void _markAllRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }

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
      appBar: AppBar(
        title: const Text(NotificationsConfig.screenTitle),
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
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              tooltip: 'Mark All Read',
              onPressed: _markAllRead,
            ),
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
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : _notifications.isEmpty
                    ? Center(
                      child: Text(
                        'No notifications available',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withAlpha(204),
                          fontSize: 18,
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return NotificationCard(
                          notification: notification,
                          onMarkRead: () {
                            setState(() {
                              notification['read'] = true;
                            });
                          },
                          onDismiss: () {
                            setState(() {
                              _notifications.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${notification['message']} deleted',
                                ),
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
