import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:campus_bus_management/config/api_config.dart'; // ✅ Import centralized URL

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
    "General Info",
  ];
  final List<String> _recipients = ["Students", "Drivers"];
  List<String> _selectedRecipients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/notifications/all"), // ✅ Updated URL
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
        Uri.parse("${ApiConfig.baseUrl}/notifications/send"), // ✅ Updated URL
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "type": _selectedNotificationType,
          "message": _messageController.text,
          "recipients": _selectedRecipients,
          "date": DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
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
              "Failed to send notification: ${response.statusCode}. ${jsonDecode(response.body)['message'] ?? ''}",
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
    final double appBarHeight = AppBar().preferredSize.height;
    final double tabBarHeight = kTextTabBarHeight;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double totalAppBarAndTabBarHeight =
        appBarHeight + tabBarHeight + statusBarHeight;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            "Notifications",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.blue.shade800.withOpacity(0.3),
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.lightBlueAccent,
            indicatorWeight: 4,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "View Notifications", icon: Icon(Icons.list_alt)),
              Tab(text: "Send Notification", icon: Icon(Icons.send)),
            ],
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
                Colors.blue.shade900,
                Colors.blue.shade700,
                Colors.blue.shade500,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: TabBarView(
            children: [
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : notifications.isEmpty
                  ? Center(
                    child: Text(
                      "No notifications available.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: EdgeInsets.only(
                      top: 200,
                      left: 16.0,
                      right: 16.0,
                      bottom: 16.0,
                    ),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      DateTime? notificationDate;
                      if (notification['date'] is String) {
                        try {
                          notificationDate = DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).parse(notification['date']);
                        } catch (e1) {
                          try {
                            notificationDate = DateFormat(
                              'MMM dd, yyyy',
                            ).parse(notification['date']);
                          } catch (e2) {
                            debugPrint(
                              'Error parsing date with all formats: ${notification['date']} - $e2',
                            );
                            notificationDate =
                                DateTime.tryParse(notification['date']) ??
                                DateTime.now();
                          }
                        }
                      } else {
                        notificationDate = DateTime.now();
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blueGrey.shade300.withOpacity(0.15),
                                    Colors.blueGrey.shade700.withOpacity(0.15),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
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
                                    offset: const Offset(-5, -5),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(
                                  notification['type'] ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['message'] ?? 'No message',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (notification['recipients'] != null &&
                                        notification['recipients'].isNotEmpty)
                                      Text(
                                        'To: ${notification['recipients'].join(', ')}',
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  DateFormat(
                                    'MMM dd, hh:mm a',
                                  ).format(notificationDate),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: 200,
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueGrey.shade300.withOpacity(0.15),
                            Colors.blueGrey.shade700.withOpacity(0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(10, 10),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(-8, -8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Create New Notification",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 5, color: Colors.black54),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildDropdownFormField(
                            value: _selectedNotificationType,
                            hint: "Select Notification Type",
                            items: _notificationTypes,
                            onChanged:
                                (value) => setState(
                                  () => _selectedNotificationType = value,
                                ),
                            icon: Icons.category,
                          ),
                          const SizedBox(height: 20),
                          _buildMessageTextField(),
                          const SizedBox(height: 20),
                          Text(
                            "Select Recipients:",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children:
                                _recipients
                                    .map(
                                      (recipient) => FilterChip(
                                        label: Text(
                                          recipient,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        selected: _selectedRecipients.contains(
                                          recipient,
                                        ),
                                        onSelected:
                                            (isSelected) => setState(() {
                                              if (isSelected) {
                                                _selectedRecipients.add(
                                                  recipient,
                                                );
                                              } else {
                                                _selectedRecipients.remove(
                                                  recipient,
                                                );
                                              }
                                            }),
                                        backgroundColor: Colors.blue.shade700
                                            .withOpacity(0.6),
                                        selectedColor: Colors.lightBlueAccent
                                            .withOpacity(0.8),
                                        checkmarkColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          side: BorderSide(
                                            color:
                                                _selectedRecipients.contains(
                                                      recipient,
                                                    )
                                                    ? Colors.white.withOpacity(
                                                      0.6,
                                                    )
                                                    : Colors.white.withOpacity(
                                                      0.2,
                                                    ),
                                            width: 1.5,
                                          ),
                                        ),
                                        elevation: 5,
                                        shadowColor: Colors.black.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 30),
                          _buildSendButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFormField({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          hint,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.lightBlueAccent, size: 24),
          labelText: hint,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        dropdownColor: Colors.blue.shade800.withOpacity(0.7),
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMessageTextField() {
    return TextFormField(
      controller: _messageController,
      maxLines: 4,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: "Message",
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 16,
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.lightBlueAccent,
            width: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade800.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: ElevatedButton(
            onPressed: _sendNotification,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Send Notification",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
