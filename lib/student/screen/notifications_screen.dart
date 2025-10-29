import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:campus_bus_management/config/api_config.dart';

class ViewNotificationsScreen extends StatefulWidget {
  final String userRole;

  const ViewNotificationsScreen({super.key, required this.userRole});

  @override
  _ViewNotificationsScreenState createState() =>
      _ViewNotificationsScreenState();
}

class _ViewNotificationsScreenState extends State<ViewNotificationsScreen>
    with TickerProviderStateMixin {
  List<dynamic> notifications = [];
  bool isLoading = true;
  String errorMessage = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response = await http
          .get(
            Uri.parse(
              "${ApiConfig.baseUrl}/notifications/view/${widget.userRole}",
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> fetchedNotifications = jsonDecode(response.body);
        setState(() {
          notifications =
              fetchedNotifications.toList()..sort((a, b) {
                DateTime dateA =
                    DateTime.tryParse(a['date']?.toString() ?? '') ??
                    DateTime(0);
                DateTime dateB =
                    DateTime.tryParse(b['date']?.toString() ?? '') ??
                    DateTime(0);
                return dateB.compareTo(dateA);
              });
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load notifications: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'Failed to load notifications. Please check your network or try again later.';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF87CEEB), Color(0xFF4682B4), Color(0xFF1E90FF)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.cyan),
                )
                : errorMessage.isNotEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                )
                : notifications.isEmpty
                ? const Center(
                  child: Text(
                    "No notifications available.",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                )
                : ListView.builder(
                  padding: EdgeInsets.only(
                    top:
                        kToolbarHeight +
                        MediaQuery.of(context).padding.top +
                        16,
                    left: 16,
                    right: 16,
                    bottom: 20,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final DateTime notificationDate =
                        DateTime.tryParse(
                          notification['date']?.toString() ?? '',
                        ) ??
                        DateTime.now();
                    final String formattedDate = DateFormat(
                      'MMM dd, yyyy',
                    ).format(notificationDate);

                    return AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.01,
                          child: _buildNotificationCard(
                            type: notification['type'] ?? 'General Update',
                            message:
                                notification['message'] ??
                                'No message content.',
                            date: formattedDate,
                            gradientColors: _getGradientForType(
                              notification['type'],
                            ),
                            iconColor: _getIconColorForType(
                              notification['type'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }

  List<Color> _getGradientForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'urgent':
        return [Colors.red.shade400, Colors.orange.shade600];
      case 'update':
        return [Colors.cyan.shade400, Colors.blue.shade600];
      case 'fees':
        return [Colors.green.shade400, Colors.teal.shade600];
      case 'attendance':
        return [Colors.purple.shade400, Colors.pink.shade600];
      default:
        return [Colors.blueGrey.shade400, Colors.grey.shade600];
    }
  }

  Color _getIconColorForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'urgent':
        return Colors.redAccent;
      case 'update':
        return Colors.cyanAccent;
      case 'fees':
        return Colors.greenAccent;
      case 'attendance':
        return Colors.purpleAccent;
      default:
        return Colors.blueAccent;
    }
  }

  Widget _buildNotificationCard({
    required String type,
    required String message,
    required String date,
    required List<Color> gradientColors,
    required Color iconColor,
  }) {
    IconData notificationIcon;
    switch (type.toLowerCase()) {
      case 'urgent':
        notificationIcon = Icons.warning_amber_rounded;
        break;
      case 'update':
        notificationIcon = Icons.info_outline;
        break;
      case 'fees':
        notificationIcon = Icons.payments_outlined;
        break;
      case 'attendance':
        notificationIcon = Icons.fingerprint;
        break;
      default:
        notificationIcon = Icons.notifications_none;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.8,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColors[0].withOpacity(0.25),
                  gradientColors[1].withOpacity(0.15),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with glow
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withOpacity(0.2),
                    border: Border.all(
                      color: iconColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(notificationIcon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.cyan, blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white60,
                            fontStyle: FontStyle.italic,
                            shadows: [
                              Shadow(color: Colors.black38, blurRadius: 6),
                            ],
                          ),
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
    );
  }
}
