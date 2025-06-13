// 📌 File: frontend/lib/view_notification_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> fetchNotifications() async {
    setState(() {
      _isLoading = true;
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

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "View Notifications",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? const Center(
                child: Text(
                  "No notifications available",
                  style: TextStyle(color: Colors.black),
                ),
              )
              : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        notification['type'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(notification['message'] ?? 'No message'),
                      trailing: Text(
                        notification['date'] ?? 'Unknown date',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
