import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:intl/intl.dart'; // For date formatting

class ViewNotificationsScreen extends StatefulWidget {
  final String userRole; // Accept userRole as a parameter

  const ViewNotificationsScreen({super.key, required this.userRole});

  @override
  _ViewNotificationsScreenState createState() =>
      _ViewNotificationsScreenState();
}

class _ViewNotificationsScreenState extends State<ViewNotificationsScreen> {
  List<dynamic> notifications = [];
  bool _isLoading = false;
  String _errorMessage = ''; // To store network/API error messages

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Clear previous error messages
    });

    try {
      final response = await http.get(
        Uri.parse(
          "http://192.168.31.104:5000/api/notifications/view/${widget.userRole}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            notifications = data;
            _isLoading = false;
          });
          if (notifications.isEmpty) {
            _errorMessage = "No notifications available for your role.";
          }
        } else {
          throw Exception("Invalid response format from server.");
        }
      } else {
        setState(() {
          _errorMessage =
              "Failed to load notifications: ${response.statusCode} - ${response.body}";
          _isLoading = false;
        });
        print('API Error: $_errorMessage'); // Print to debug console
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            "Error loading notifications: $e. Please check network connection.";
      });
      print('Network/Other Error: $_errorMessage'); // Print to debug console
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Extends body behind app bar for full gradient
      appBar: AppBar(
        title: const Text(
          "View Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(
          0.4,
        ), // Liquid glass app bar
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // White back button
        elevation: 0, // Remove default shadow
        centerTitle: true,
        flexibleSpace: ClipRect(
          // Clip to make the blur effect contained within the AppBar area
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ), // Blur effect for app bar
            child: Container(
              color:
                  Colors
                      .transparent, // Transparent to show blurred content behind
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade500,
            ], // Deep Purple themed gradient background
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ), // White loading indicator
                )
                : _errorMessage.isNotEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildLiquidGlassCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.redAccent.shade100,
                          fontSize: 18,
                        ), // Red error text
                      ),
                    ),
                  ),
                )
                : notifications.isEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildLiquidGlassCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      child: const Text(
                        "No notifications available for your role.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ), // White/grey text for no data
                      ),
                    ),
                  ),
                )
                : ListView.builder(
                  padding: EdgeInsets.only(
                    top:
                        AppBar().preferredSize.height +
                        MediaQuery.of(context).padding.top +
                        16,
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 15.0,
                      ), // Spacing between cards
                      child: _buildNotificationCard(notification),
                    );
                  },
                ),
      ),
    );
  }

  // Helper method to build a liquid glass card for consistent styling
  Widget _buildLiquidGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        25,
      ), // Rounded corners for liquid glass card
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20.0,
          sigmaY: 20.0,
        ), // Stronger blur for the card
        child: Container(
          padding:
              padding ??
              const EdgeInsets.all(
                25,
              ), // Increased padding inside the card, made optional
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(
                  0.1,
                ), // More transparent white for lighter glass
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ), // Thinner border
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.15), // Inner light glow
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(-8, -8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // New Widget: _buildNotificationCard to apply liquid glass style to each notification
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return _buildLiquidGlassCard(
      padding: const EdgeInsets.all(
        20,
      ), // Padding for individual notification cards
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign,
                color: Colors.amberAccent,
                size: 28,
              ), // Icon for notification type
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  notification['type'] ?? 'General Announcement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.message,
                color: Colors.white70,
                size: 24,
              ), // Icon for message
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  notification['message'] ?? 'No message provided.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.access_time,
                color: Colors.white54,
                size: 18,
              ), // Icon for date/time
              SizedBox(width: 5),
              Text(
                _formatDate(notification['date']), // Format date
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to format date string
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }
}
