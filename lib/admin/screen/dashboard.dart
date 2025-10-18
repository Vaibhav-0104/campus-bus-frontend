import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/config/api_config.dart'; // ✅ Import centralized URL
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
  // Function to fetch total students count
  Future<int> fetchTotalStudents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/students'),
      ); // ✅ Updated URL
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

  // Function to fetch total buses count
  Future<int> fetchTotalBuses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/buses'),
      ); // ✅ Updated URL
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

  // Function to fetch total drivers count
  Future<int> fetchTotalDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/drivers'),
      ); // ✅ Updated URL
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
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade800.withOpacity(0.3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Container(
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height:
                        AppBar().preferredSize.height +
                        MediaQuery.of(context).padding.top +
                        10,
                  ),
                  FutureBuilder<int>(
                    future: fetchTotalStudents(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _statCard(
                          Icons.school,
                          Colors.lightBlueAccent,
                          "Total Students",
                          "Loading...",
                        );
                      } else if (snapshot.hasError) {
                        return _statCard(
                          Icons.school,
                          Colors.redAccent,
                          "Total Students",
                          "Error: ${snapshot.error}",
                        );
                      } else {
                        return _statCard(
                          Icons.school,
                          Colors.lightBlueAccent,
                          "Total Students",
                          snapshot.data.toString(),
                        );
                      }
                    },
                  ),
                  FutureBuilder<int>(
                    future: fetchTotalDrivers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _statCard(
                          Icons.group,
                          Colors.greenAccent,
                          "Total Drivers",
                          "Loading...",
                        );
                      } else if (snapshot.hasError) {
                        return _statCard(
                          Icons.group,
                          Colors.redAccent,
                          "Total Drivers",
                          "Error: ${snapshot.error}",
                        );
                      } else {
                        return _statCard(
                          Icons.group,
                          Colors.greenAccent,
                          "Total Drivers",
                          snapshot.data.toString(),
                        );
                      }
                    },
                  ),
                  FutureBuilder<int>(
                    future: fetchTotalBuses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _statCard(
                          Icons.directions_bus_filled,
                          Colors.orangeAccent,
                          "Total Buses",
                          "Loading...",
                        );
                      } else if (snapshot.hasError) {
                        return _statCard(
                          Icons.directions_bus_filled,
                          Colors.redAccent,
                          "Total Buses",
                          "Error: ${snapshot.error}",
                        );
                      } else {
                        return _statCard(
                          Icons.directions_bus_filled,
                          Colors.orangeAccent,
                          "Total Buses",
                          snapshot.data.toString(),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
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
            colors: [Colors.blue.shade900, Colors.blue.shade600],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
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
            _buildDrawerItem(
              context,
              Icons.directions_bus,
              "Manage Bus Details",
              const ManageBusDetailsScreen(),
              Colors.lightBlueAccent,
            ),
            _buildDrawerItem(
              context,
              Icons.person,
              "Manage Driver Details",
              const ManageBusDriverDetailsScreen(),
              Colors.greenAccent,
            ),
            _buildDrawerItem(
              context,
              Icons.school,
              "Manage Student Details",
              const ManageStudentDetailsScreen(),
              Colors.orangeAccent,
            ),
            _buildDrawerItem(
              context,
              Icons.swap_horiz,
              "Allocate Bus to Student",
              const AllocateBusScreen(),
              Colors.purpleAccent,
            ),
            _buildDrawerItem(
              context,
              Icons.payment,
              "Manage Fees",
              const ManageStudentFeesScreen(),
              Colors.pinkAccent,
            ),
            _buildDrawerItem(
              context,
              Icons.notifications,
              "Manage Notifications",
              const NotificationsScreen(userRole: "Admin"),
              Colors.tealAccent,
            ),
            _buildDrawerItem(
              context,
              Icons.assignment,
              "View Student Attendance",
              const ViewStudentAttendance(),
              Colors.redAccent,
            ),
            _buildDrawerItem(
              context,
              Icons.bar_chart,
              "Reports",
              const ReportsScreen(),
              Colors.yellowAccent.shade100,
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
    Color iconColor,
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
                  Colors.blue.shade300.withOpacity(0.1),
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
              leading: Icon(icon, color: iconColor, size: 28),
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
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      height: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade300.withOpacity(0.18),
                  Colors.blue.shade600.withOpacity(0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 30,
                  spreadRadius: 4,
                  offset: const Offset(10, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
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
                  size: 60,
                  color: iconColor,
                  shadows: const [
                    Shadow(
                      blurRadius: 15.0,
                      color: Colors.black87,
                      offset: Offset(4.0, 4.0),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 21,
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
