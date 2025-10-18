import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:intl/intl.dart'; // For date formatting for trailing date
import 'package:campus_bus_management/config/api_config.dart'; // ✅ Import centralized URL

class ViewNotificationsScreen extends StatefulWidget {
  final String userRole; // Role: "Students" or "Drivers"

  const ViewNotificationsScreen({super.key, required this.userRole});

  @override
  _ViewNotificationsScreenState createState() =>
      _ViewNotificationsScreenState();
}

class _ViewNotificationsScreenState extends State<ViewNotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
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
          .timeout(const Duration(seconds: 15)); // Added timeout

      if (response.statusCode == 200) {
        final List<dynamic> fetchedNotifications = jsonDecode(response.body);
        setState(() {
          // Sort notifications by date in descending order (most recent first)
          // Safely parse date strings. If parsing fails, treat as a very old date (epoch).
          notifications =
              fetchedNotifications.toList()..sort((a, b) {
                DateTime dateA =
                    DateTime.tryParse(a['date']?.toString() ?? '') ??
                    DateTime(0);
                DateTime dateB =
                    DateTime.tryParse(b['date']?.toString() ?? '') ??
                    DateTime(0);
                return dateB.compareTo(dateA); // Descending order
              });
          isLoading = false;
        });
      } else {
        print(
          'API Error: Status=${response.statusCode}, Body=${response.body}',
        );
        setState(() {
          errorMessage = 'Failed to load notifications: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        errorMessage =
            'Failed to load notifications. Please check your network or try again later.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Extend body behind app bar for full gradient
      appBar: AppBar(
        title: const Text(
          "Notifications", // Simplified title
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(
          0.3,
        ), // Transparent app bar with blur
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0, // Remove shadow for flat look
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Increased blur
            child: Container(
              color: Colors.transparent, // Transparent to allow blur to show
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade500,
            ], // Richer gradient background
            stops: const [
              0.0,
              0.5,
              1.0,
            ], // Adjusted stops for smoother transition
          ),
        ),
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ), // White loading indicator
                )
                : errorMessage.isNotEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.redAccent.shade100,
                      ),
                    ),
                  ),
                )
                : notifications.isEmpty
                ? Center(
                  child: Text(
                    "No notifications available.",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                )
                : ListView.builder(
                  padding: EdgeInsets.only(
                    top:
                        AppBar().preferredSize.height +
                        MediaQuery.of(context).padding.top +
                        16,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    // Parse date for consistent formatting and better display
                    // Use a safe parse with fallback for display as well
                    final DateTime notificationDate =
                        DateTime.tryParse(
                          notification['date']?.toString() ?? '',
                        ) ??
                        DateTime.now();
                    final String formattedDate = DateFormat(
                      'MMM dd, yyyy',
                    ).format(notificationDate);

                    return _buildNotificationCard(
                      type: notification['type'] ?? 'General Update',
                      message: notification['message'] ?? 'No message content.',
                      date: formattedDate,
                      // Dynamic colors for variety, similar to dashboard cards
                      gradientColors: [
                        Colors.teal.shade300,
                        Colors.cyan.shade600,
                      ],
                      iconColor: Colors.lightGreenAccent.shade100,
                    );
                  },
                ),
      ),
    );
  }

  // Reusable widget for a liquid glass notification card
  Widget _buildNotificationCard({
    required String type,
    required String message,
    required String date,
    required List<Color> gradientColors,
    required Color iconColor,
  }) {
    IconData notificationIcon;
    // Determine icon based on notification type or a default
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
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Increased rounded corners
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Stronger blur
          child: Container(
            padding: const EdgeInsets.all(20), // Increased padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    gradientColors
                        .map((color) => color.withOpacity(0.15))
                        .toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 25,
                  spreadRadius: 3,
                  offset: const Offset(8, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(-5, -5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  notificationIcon,
                  size: 36, // Slightly larger icon
                  color: iconColor,
                  shadows: [
                    Shadow(
                      blurRadius: 8.0,
                      color: Colors.black.withOpacity(0.6),
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 20, // Larger title
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 5.0,
                              color: Colors.black45,
                              offset: Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16, // Readable message font size
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white54, // Subtler date color
                            fontStyle: FontStyle.italic,
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
