import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewNotificationsScreen extends StatefulWidget {
  final String userRole; // Role: "Students" or "Drivers"

  const ViewNotificationsScreen({super.key, required this.userRole});

  @override
  _ViewNotificationsScreenState createState() =>
      _ViewNotificationsScreenState();
}

class _ViewNotificationsScreenState extends State<ViewNotificationsScreen> {
  List<dynamic> notifications = [];

  Future<void> fetchNotifications() async {
    final response = await http.get(
      Uri.parse(
        "http://192.168.31.104:5000/api/notifications/view/${widget.userRole}",
      ),
    );
    if (response.statusCode == 200) {
      setState(() {
        notifications = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load notifications")));
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
          "View Notification",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple, // ✅ Header color Purple
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          notifications.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    child: ListTile(
                      title: Text(notification['type']),
                      subtitle: Text(notification['message']),
                      trailing: Text(
                        notification['date'].toString().split("T")[0],
                      ), // Display date
                    ),
                  );
                },
              ),
    );
  }
}
