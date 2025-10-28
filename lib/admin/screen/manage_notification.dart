import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:campus_bus_management/config/api_config.dart';

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
  final List<String> _recipients = ["Students", "Drivers", "Parents"];
  List<String> _selectedRecipients = [];
  bool _isLoading = false;

  // ────── COLORS (Same as other screens) ──────
  final Color bgStart = const Color(0xFF0A0E1A);
  final Color bgMid = const Color(0xFF0F172A);
  final Color bgEnd = const Color(0xFF1E293B);
  final Color glassBg = Colors.white.withAlpha(0x14);
  final Color glassBorder = Colors.white.withAlpha(0x26);
  final Color textSecondary = Colors.white70;
  final Color busYellow = const Color(0xFFFBBF24);

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
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/notifications/all"),
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
      setState(() => _isLoading = false);
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
        Uri.parse("${ApiConfig.baseUrl}/notifications/send"),
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
              "Failed to send: ${jsonDecode(response.body)['message'] ?? ''}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ────── GLASS CARD ──────
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: glassBorder, width: 1.2),
          ),
          child: child,
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
        color: glassBg,
        border: Border.all(color: glassBorder, width: 1.2),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: TextStyle(color: textSecondary)),
        style: const TextStyle(color: Colors.white),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        dropdownColor: bgMid,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: busYellow),
          labelText: hint,
          labelStyle: TextStyle(color: textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
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
        labelStyle: TextStyle(color: textSecondary),
        filled: true,
        fillColor: glassBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: glassBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: glassBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: busYellow, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return ElevatedButton.icon(
      onPressed: _sendNotification,
      icon: const Icon(Icons.send),
      label: const Text(
        "Send Notification",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: busYellow,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white, size: 28),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications, color: busYellow, size: 28),
              const SizedBox(width: 8),
              const Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.white.withAlpha(0x0D)),
            ),
          ),
          bottom: TabBar(
            labelColor: busYellow,
            unselectedLabelColor: Colors.white70,
            indicatorColor: busYellow,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "View", icon: Icon(Icons.list_alt)),
              Tab(text: "Send", icon: Icon(Icons.send)),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgStart, bgMid, bgEnd],
            ),
          ),
          child: SafeArea(
            child: TabBarView(
              children: [
                // ────── VIEW NOTIFICATIONS ──────
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: busYellow))
                    : notifications.isEmpty
                    ? Center(
                      child: Text(
                        "No notifications available.",
                        style: TextStyle(color: textSecondary, fontSize: 18),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        DateTime? notificationDate;
                        try {
                          notificationDate = DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).parse(notification['date']);
                        } catch (_) {
                          try {
                            notificationDate = DateFormat(
                              'MMM dd, yyyy',
                            ).parse(notification['date']);
                          } catch (_) {
                            notificationDate =
                                DateTime.tryParse(notification['date']) ??
                                DateTime.now();
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _glassCard(
                            child: ListTile(
                              title: Text(
                                notification['type'] ?? 'Unknown',
                                style: TextStyle(
                                  color: busYellow,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification['message'] ?? 'No message',
                                    style: TextStyle(color: textSecondary),
                                  ),
                                  if (notification['recipients'] != null &&
                                      notification['recipients'].isNotEmpty)
                                    Text(
                                      'To: ${notification['recipients'].join(', ')}',
                                      style: TextStyle(
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
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                // ────── SEND NOTIFICATION ──────
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Create New Notification",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDropdownFormField(
                          value: _selectedNotificationType,
                          hint: "Select Notification Type",
                          items: _notificationTypes,
                          onChanged:
                              (v) =>
                                  setState(() => _selectedNotificationType = v),
                          icon: Icons.category,
                        ),
                        const SizedBox(height: 16),
                        _buildMessageTextField(),
                        const SizedBox(height: 16),
                        Text(
                          "Select Recipients:",
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              _recipients.map((r) {
                                final selected = _selectedRecipients.contains(
                                  r,
                                );
                                return FilterChip(
                                  label: Text(
                                    r,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  selected: selected,
                                  onSelected: (bool s) {
                                    setState(() {
                                      s
                                          ? _selectedRecipients.add(r)
                                          : _selectedRecipients.remove(r);
                                    });
                                  },
                                  backgroundColor: Colors.grey.shade800
                                      .withOpacity(0.6),
                                  selectedColor: busYellow.withOpacity(0.8),
                                  checkmarkColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: selected ? busYellow : glassBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 24),
                        _buildSendButton(),
                      ],
                    ),
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
