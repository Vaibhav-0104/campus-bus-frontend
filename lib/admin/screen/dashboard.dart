import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/config/api_config.dart';
import 'package:campus_bus_management/login.dart';
import 'package:campus_bus_management/admin/screen/manage_bus_details.dart';
import 'package:campus_bus_management/admin/screen/manage_driver_details.dart';
import 'package:campus_bus_management/admin/screen/allocate_bus_to_student.dart';
import 'package:campus_bus_management/admin/screen/manage_student_details.dart';
import 'package:campus_bus_management/admin/screen/manage_student_fees.dart';
import 'package:campus_bus_management/admin/screen/manage_notification.dart';
import 'package:campus_bus_management/admin/screen/view_student_attendance.dart';
import 'package:campus_bus_management/admin/screen/reports.dart';
import 'package:campus_bus_management/admin/screen/show_drivers_details.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Colors
  final Color bgStart = const Color(0xFF0A0E1A);
  final Color bgMid = const Color(0xFF0F172A);
  final Color bgEnd = const Color(0xFF1E293B);
  final Color glassBg = Colors.white.withOpacity(0.08);
  final Color glassBorder = Colors.white.withOpacity(0.15);
  final Color textSecondary = Colors.white70;
  final Color busYellow = const Color(0xFFFBBF24);

  // API Fetchers
  Future<int> fetchTotalStudents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/students'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body).length;
    } catch (e) {
      debugPrint('Error: $e');
    }
    return 0;
  }

  Future<int> fetchTotalBuses() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/buses'));
      if (response.statusCode == 200) return jsonDecode(response.body).length;
    } catch (e) {
      debugPrint('Error: $e');
    }
    return 0;
  }

  Future<int> fetchTotalDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/drivers'),
      );
      if (response.statusCode == 200) return jsonDecode(response.body).length;
    } catch (e) {
      debugPrint('Error: $e');
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
        title: Row(
          children: [
            Icon(Icons.directions_bus, color: busYellow, size: 28),
            const SizedBox(width: 8),
            const Text(
              "CAMPUS BUS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed:
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
            icon: const Icon(Icons.logout, color: Colors.white, size: 26),
            tooltip: "Logout",
          ),
        ],
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Admin Dashboard",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Animated Cards with Click Feedback
                  _animatedGlassCard(
                    icon: Icons.directions_bus,
                    iconColor: Colors.blue.shade400,
                    title: "Total Buses",
                    future: fetchTotalBuses(),
                    onTap: null,
                  ),
                  const SizedBox(height: 16),

                  _animatedGlassCard(
                    icon: Icons.person_outline,
                    iconColor: Colors.green.shade400,
                    title: "Total Drivers",
                    future: fetchTotalDrivers(),
                    onTap: () {
                      setState(() => _selectedIndex = 1);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShowDriversScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _animatedGlassCard(
                    icon: Icons.school,
                    iconColor: Colors.cyan.shade400,
                    title: "Total Students",
                    future: fetchTotalStudents(),
                    onTap: null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgStart, bgMid, bgEnd],
        ),
      ),
    );
  }

  // Animated Card with Pop + Shadow
  Widget _animatedGlassCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Future<int> future,
    VoidCallback? onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        return GestureDetector(
          onTapDown:
              onTap != null ? (_) => setState(() => isPressed = true) : null,
          onTapUp:
              onTap != null
                  ? (_) {
                    setState(() => isPressed = false);
                    Future.delayed(const Duration(milliseconds: 100), onTap);
                  }
                  : null,
          onTapCancel:
              onTap != null ? () => setState(() => isPressed = false) : null,
          child: AnimatedScale(
            scale: isPressed ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform:
                  Matrix4.identity()..translate(0.0, isPressed ? -4 : 0.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: glassBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: glassBorder, width: 1.2),
                      boxShadow:
                          isPressed
                              ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                              : null,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: iconColor.withOpacity(0.2),
                          child: Icon(icon, size: 34, color: iconColor),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FutureBuilder<int>(
                                future: future,
                                builder: (context, snapshot) {
                                  final value =
                                      snapshot.connectionState ==
                                              ConnectionState.waiting
                                          ? "--"
                                          : snapshot.hasData
                                          ? snapshot.data.toString()
                                          : "0";
                                  return Text(
                                    value,
                                    style: const TextStyle(
                                      fontSize: 38,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
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
          ),
        );
      },
    );
  }

  // Drawer with Click Feedback
  Widget _buildDrawer() {
    return Drawer(
      child: Stack(
        children: [
          _buildBackground(),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  child: Row(
                    children: [
                      Icon(Icons.directions_bus, color: busYellow, size: 36),
                      const SizedBox(width: 12),
                      const Text(
                        "Campus Bus",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    children: [
                      _drawerItem(
                        Icons.directions_bus,
                        "Buses",
                        const ManageBusDetailsScreen(),
                        0,
                      ),
                      _drawerItem(
                        Icons.person,
                        "Drivers",
                        const ManageBusDriverDetailsScreen(),
                        1,
                      ),
                      _drawerItem(
                        Icons.school,
                        "Students",
                        const ManageStudentDetailsScreen(),
                        2,
                      ),
                      _drawerItem(
                        Icons.swap_horiz,
                        "Allocate Bus",
                        const AllocateBusScreen(),
                        3,
                      ),
                      _drawerItem(
                        Icons.payment,
                        "Fees",
                        const ManageStudentFeesScreen(),
                        4,
                      ),
                      _drawerItem(
                        Icons.notifications,
                        "Notifications",
                        const NotificationsScreen(userRole: "Admin"),
                        5,
                      ),
                      _drawerItem(
                        Icons.assignment,
                        "Attendance",
                        const ViewStudentAttendance(),
                        6,
                      ),
                      _drawerItem(
                        Icons.bar_chart,
                        "Reports",
                        const ReportsScreen(),
                        7,
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                _drawerItem(
                  Icons.logout,
                  "Logout",
                  const LoginScreen(),
                  -1,
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Drawer Item with Click Feedback + Selection
  Widget _drawerItem(
    IconData icon,
    String title,
    Widget screen,
    int index, {
    bool isLogout = false,
  }) {
    final bool isSelected = !isLogout && _selectedIndex == index;
    bool isPressed = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) {
            setState(() => isPressed = false);
            if (isLogout) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            } else {
              this.setState(() => _selectedIndex = index);
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            }
          },
          onTapCancel: () => setState(() => isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Colors.amber.withOpacity(0.15)
                      : isPressed
                      ? Colors.white.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected
                        ? Colors.amber.withOpacity(0.3)
                        : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      isLogout
                          ? const Color.fromARGB(255, 252, 252, 252)
                          : isSelected
                          ? Colors.amber
                          : Colors.white70,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color:
                        isLogout
                            ? const Color.fromARGB(255, 254, 253, 253)
                            : isSelected
                            ? Colors.amber
                            : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
