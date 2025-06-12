// 📌 File: frontend/lib/manage_notification.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsScreen extends StatefulWidget {
  final String userRole;

  const NotificationsScreen({super.key, required this.userRole});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  final TextEditingController _messageController = TextEditingController();
  String? _selectedNotificationType;
  final List<String> _notificationTypes = [
    "Emergency",
    "Delay",
    "Route Change",
    "Holiday",
  ];
  final List<String> _recipients = ["Students", "Drivers", "Both"];
  List<String> _selectedRecipients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "https://campus-bus-backend.onrender.com/api/notifications/all",
        ), // 📌 Changed to fetch all notifications
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

  Future<void> _sendNotification() async {
    if (_selectedNotificationType == null ||
        _selectedRecipients.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required!")));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          "https://campus-bus-backend.onrender.com/api/notifications/send",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "type": _selectedNotificationType,
          "message": _messageController.text,
          "recipients": _selectedRecipients,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification sent successfully!")),
        );
        _messageController.clear();
        setState(() {
          _selectedRecipients = [];
          _selectedNotificationType = null;
        });
        await fetchNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to send notification: ${response.statusCode}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error sending notification: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Notifications",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.deepPurple,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "View Notifications"),
              Tab(text: "Send Notification"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
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
                      color: Colors.black,
                      child: ListTile(
                        title: Text(
                          notification['type'] ?? 'Unknown',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          notification['message'] ?? 'No message',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          notification['date'] ?? 'Unknown date',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    );
                  },
                ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Notification Type",
                    ),
                    items:
                        _notificationTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) =>
                            setState(() => _selectedNotificationType = value),
                    value: _selectedNotificationType,
                  ),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: "Message"),
                    style: const TextStyle(color: Colors.black),
                  ),
                  Wrap(
                    spacing: 10,
                    children:
                        _recipients
                            .map(
                              (recipient) => FilterChip(
                                label: Text(
                                  recipient,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                selected: _selectedRecipients.contains(
                                  recipient,
                                ),
                                onSelected:
                                    (isSelected) => setState(() {
                                      if (isSelected) {
                                        _selectedRecipients.add(recipient);
                                      } else {
                                        _selectedRecipients.remove(recipient);
                                      }
                                    }),
                                backgroundColor: Colors.deepPurple,
                                selectedColor: Colors.purple,
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: const Text(
                      "Send Notification",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
