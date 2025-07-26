import 'package:flutter/material.dart';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // Required for jsonDecode

import 'package:campus_bus_management/login.dart';
import 'package:campus_bus_management/admin/screen/manage_bus_details.dart';
import 'package:campus_bus_management/admin/screen/manage_driver_details.dart';
import 'package:campus_bus_management/admin/screen/allocate_bus_to_student.dart';
import 'package:campus_bus_management/admin/screen/manage_student_details.dart';
import 'package:campus_bus_management/admin/screen/manage_student_fees.dart';
import 'package:campus_bus_management/admin/screen/manage_notification.dart';
import 'package:campus_bus_management/admin/screen/view_student_attendance.dart';
import 'package:campus_bus_management/admin/screen/reports.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Base URL for your API
  final String _baseUrl = 'http://192.168.31.104:5000/api';

  // Function to fetch total students count
  Future<int> fetchTotalStudents() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/students'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.length; // Assuming the API returns a list of students
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching students: $e');
      return 0; // Return 0 or handle error appropriately
    }
  }

  // Function to fetch total buses count
  Future<int> fetchTotalBuses() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/buses'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.length; // Assuming the API returns a list of buses
      } else {
        throw Exception('Failed to load buses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching buses: $e');
      return 0; // Return 0 or handle error appropriately
    }
  }

  // Function to fetch total drivers count
  Future<int> fetchTotalDrivers() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/drivers'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.length; // Assuming the API returns a list of drivers
      } else {
        throw Exception('Failed to load drivers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching drivers: $e');
      return 0; // Return 0 or handle error appropriately
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Extend body behind app bar for full gradient
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade800.withOpacity(
          0.3,
        ), // Liquid glass app bar
        elevation: 0, // Remove shadow for flat look
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ), // Increased blur for app bar background
            child: Container(
              color: Colors.transparent, // Transparent to allow blur to show
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Container(
        // The gradient background now fully fills the screen,
        // as the Scaffold body is inherently sized to fill.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ], // Blue themed gradient background
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0), // Simplified padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Add SizedBox to push content below the AppBar and status bar explicitly
                  SizedBox(
                    height:
                        AppBar().preferredSize.height +
                        MediaQuery.of(context).padding.top +
                        10,
                  ),
                  // Stat Card for Total Students
                  FutureBuilder<int>(
                    future: fetchTotalStudents(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _statCard(
                          Icons.school, // Example icon for students
                          Colors.lightBlueAccent, // Icon color
                          "Total Students",
                          "Loading...",
                        );
                      } else if (snapshot.hasError) {
                        return _statCard(
                          Icons.school, // Example icon for students
                          Colors.redAccent, // Icon color for error
                          "Total Students",
                          "Error: ${snapshot.error}",
                        );
                      } else {
                        return _statCard(
                          Icons.school, // Example icon for students
                          Colors.lightBlueAccent, // Icon color
                          "Total Students",
                          snapshot.data.toString(),
                        );
                      }
                    },
                  ),
                  // Stat Card for Total Drivers
                  FutureBuilder<int>(
                    future: fetchTotalDrivers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _statCard(
                          Icons.group, // Example icon for drivers
                          Colors.greenAccent, // Icon color
                          "Total Drivers",
                          "Loading...",
                        );
                      } else if (snapshot.hasError) {
                        return _statCard(
                          Icons.group, // Example icon for drivers
                          Colors.redAccent, // Icon color for error
                          "Total Drivers",
                          "Error: ${snapshot.error}",
                        );
                      } else {
                        return _statCard(
                          Icons.group, // Example icon for drivers
                          Colors.greenAccent, // Icon color
                          "Total Drivers",
                          snapshot.data.toString(),
                        );
                      }
                    },
                  ),
                  // Stat Card for Total Buses
                  FutureBuilder<int>(
                    future: fetchTotalBuses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _statCard(
                          Icons.directions_bus_filled, // Example icon for buses
                          Colors.orangeAccent, // Icon color
                          "Total Buses",
                          "Loading...",
                        );
                      } else if (snapshot.hasError) {
                        return _statCard(
                          Icons.directions_bus_filled, // Example icon for buses
                          Colors.redAccent, // Icon color for error
                          "Total Buses",
                          "Error: ${snapshot.error}",
                        );
                      } else {
                        return _statCard(
                          Icons.directions_bus_filled, // Example icon for buses
                          Colors.orangeAccent, // Icon color
                          "Total Buses",
                          snapshot.data.toString(),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16.0), // Added bottom padding
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
            ], // Blue themed gradient for drawer background
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Liquid Glass Drawer Header
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Campus Bus Admin',
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Dashboard & Management',
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ],
              ),
            ),
            // Liquid Glass Drawer Items
            _buildDrawerItem(
              context,
              Icons.directions_bus,
              "Manage Bus Details",
              const ManageBusDetailsScreen(),
              Colors.lightBlueAccent, // Icon color
            ),
            _buildDrawerItem(
              context,
              Icons.person,
              "Manage Driver Details",
              const ManageBusDriverDetailsScreen(),
              Colors.greenAccent, // Icon color
            ),
            _buildDrawerItem(
              context,
              Icons.school,
              "Manage Student Details",
              const ManageStudentDetailsScreen(),
              Colors.orangeAccent, // Icon color
            ),
            _buildDrawerItem(
              context,
              Icons.swap_horiz,
              "Allocate Bus to Student",
              const AllocateBusScreen(),
              Colors.purpleAccent, // Icon color
            ),
            _buildDrawerItem(
              context,
              Icons.payment,
              "Manage Fees",
              const ManageStudentFeesScreen(),
              Colors.pinkAccent, // Icon color
            ),
            _buildDrawerItem(
              context,
              Icons.notifications,
              "Manage Notifications",
              const NotificationsScreen(userRole: "Admin"),
              Colors.tealAccent, // Icon color
            ),
            _buildDrawerItem(
              context,
              Icons.assignment,
              "View Student Attendance",
              const ViewStudentAttendance(),
              Colors.redAccent, // Icon color
            ),
            _buildDrawerItem(
              context,
              Icons.bar_chart,
              "Reports",
              const ReportsScreen(),
              Colors.yellowAccent.shade100, // Icon color
            ),
            const Divider(color: Colors.white30, height: 20, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 5.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade400.withOpacity(0.15),
                          Colors.red.shade700.withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                      title: const Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 3, color: Colors.black54),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
    Color iconColor, // Added iconColor parameter
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.blue.shade300.withOpacity(
                    0.1,
                  ), // Blue-themed gradient for items
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(icon, color: iconColor, size: 28), // Use iconColor
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => screen),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    IconData icon,
    Color iconColor,
    String title,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
      ), // Added vertical margin for spacing
      height: 180, // Increased height to make it more visibly rectangular
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25), // Increased rounded corners
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Stronger blur
          child: Container(
            padding: const EdgeInsets.all(25), // Increased padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade300.withOpacity(
                    0.18,
                  ), // Slightly less transparent for richer look
                  Colors.blue.shade600.withOpacity(0.18),
                ], // Blue-themed liquid glass gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ), // Slightly stronger border
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    0.25,
                  ), // Stronger shadow for depth
                  blurRadius: 30, // Increased blur radius
                  spreadRadius: 4, // Increased spread radius
                  offset: const Offset(10, 10), // More pronounced offset
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(
                    0.15,
                  ), // Slightly brighter inner glow
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(-6, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 60, // Even larger icon size
                  color: iconColor, // Use dynamic icon color
                  shadows: const [
                    Shadow(
                      blurRadius: 15.0, // More blur for icon shadow
                      color: Colors.black87, // Darker icon shadow
                      offset: Offset(4.0, 4.0),
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Increased spacing
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26, // Larger title font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0, // More blur for text shadow
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3), // Increased spacing
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 21, // Larger subtitle font size
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
