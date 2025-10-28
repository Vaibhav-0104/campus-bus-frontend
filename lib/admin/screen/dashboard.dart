import 'package:flutter/material.dart';
import 'dart:ui'; // Important for BackdropFilter
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
  // Define the required color palette
  final Color primaryColor = Colors.blue.shade700;
  final Color secondaryColor = Colors.pinkAccent; // Used for accents
  final Color primaryTextColor = Colors.white;
  final Color secondaryTextColor = Colors.white70;
  final Color logoutColor = Colors.red.shade400;

  // Background for the Liquid Glass effect
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade600,
            Colors.lightBlue.shade300,
          ],
        ),
      ),
    );
  }

  Future<int> fetchTotalStudents() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/students'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.length;
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching students: $e');
      return 0;
    }
  }

  Future<int> fetchTotalBuses() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/buses'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.length;
      } else {
        throw Exception('Failed to load buses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching buses: $e');
      return 0;
    }
  }

  Future<int> fetchTotalDrivers() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/drivers'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.length;
      } else {
        throw Exception('Failed to load drivers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching drivers: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: primaryTextColor,
          ),
        ),
        backgroundColor: Colors.transparent, // Make App Bar transparent
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor, size: 28),
        centerTitle: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: primaryColor.withOpacity(0.3), // Semi-transparent blue App Bar
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          _buildBackground(), // Vibrant gradient background
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Total Students Card
                  FutureBuilder<int>(
                    future: fetchTotalStudents(),
                    builder: (context, snapshot) {
                      return _liquidGlassCard(
                        Icons.school,
                        Colors.cyan.shade300,
                        "Total Students",
                        snapshot.connectionState == ConnectionState.waiting
                            ? "Loading..."
                            : snapshot.hasError
                                ? "Error: ${snapshot.error}"
                                : snapshot.data.toString(),
                      );
                    },
                  ),
                  // Total Drivers Card - Made tappable
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShowDriversScreen(),
                        ),
                      );
                    },
                    child: FutureBuilder<int>(
                      future: fetchTotalDrivers(),
                      builder: (context, snapshot) {
                        return _liquidGlassCard(
                          Icons.group,
                          Colors.lightGreenAccent.shade400,
                          "Total Drivers",
                          snapshot.connectionState == ConnectionState.waiting
                              ? "Loading..."
                              : snapshot.hasError
                                  ? "Error: ${snapshot.error}"
                                  : snapshot.data.toString(),
                        );
                      },
                    ),
                  ),
                  // Total Buses Card
                  FutureBuilder<int>(
                    future: fetchTotalBuses(),
                    builder: (context, snapshot) {
                      return _liquidGlassCard(
                        Icons.directions_bus_filled,
                        secondaryColor, // Pink accent
                        "Total Buses",
                        snapshot.connectionState == ConnectionState.waiting
                            ? "Loading..."
                            : snapshot.hasError
                                ? "Error: ${snapshot.error}"
                                : snapshot.data.toString(),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          _buildBackground(), // Background visible through the blur
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.25), // Dark blur overlay
                child: Column(
                  children: [
                    // Custom Drawer Header with Glassmorphism effect
                    Container(
                      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16, right: 16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Campus Bus Admin',
                            style: TextStyle(
                              fontSize: 24,
                              color: primaryTextColor,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)
                              ]
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dashboard & Management',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildDrawerItem(
                            context, Icons.directions_bus, "Manage Bus Details", 
                            const ManageBusDetailsScreen(), Colors.cyan.shade300,
                          ),
                          _buildDrawerItem(
                            context, Icons.person, "Manage Driver Details", 
                            const ManageBusDriverDetailsScreen(), Colors.lightGreenAccent.shade400,
                          ),
                          _buildDrawerItem(
                            context, Icons.school, "Manage Student Details", 
                            const ManageStudentDetailsScreen(), Colors.amber.shade300,
                          ),
                          _buildDrawerItem(
                            context, Icons.swap_horiz, "Allocate Bus to Student", 
                            const AllocateBusScreen(), Colors.purple.shade300,
                          ),
                          _buildDrawerItem(
                            context, Icons.payment, "Manage Fees", 
                            const ManageStudentFeesScreen(), secondaryColor, // Pink accent
                          ),
                          _buildDrawerItem(
                            context, Icons.notifications, "Manage Notifications", 
                            const NotificationsScreen(userRole: "Admin"), Colors.blue.shade300,
                          ),
                          _buildDrawerItem(
                            context, Icons.assignment, "View Student Attendance", 
                            const ViewStudentAttendance(), Colors.red.shade300,
                          ),
                          _buildDrawerItem(
                            context, Icons.bar_chart, "Reports", 
                            const ReportsScreen(), Colors.teal.shade300,
                          ),
                        ],
                      ),
                    ),
                    // Logout button at the bottom
                    Divider(color: secondaryTextColor.withOpacity(0.4), thickness: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        leading: Icon(Icons.logout, color: logoutColor, size: 26),
                        title: Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 16,
                            color: logoutColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
    Color iconColor,
  ) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 26),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: primaryTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }

  // Liquid Glass Stat Card
  Widget _liquidGlassCard(IconData icon, Color iconColor, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryTextColor.withOpacity(0.15), // Semi-transparent glass base
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryTextColor.withOpacity(0.2), // Light border for definition
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryTextColor.withOpacity(0.2),
                  ),
                  child: Icon(icon, size: 40, color: iconColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 32,
                          color: iconColor, // Color accent for the count
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)
                          ]
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