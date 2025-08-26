import 'dart:convert';
import 'dart:ui'; // For ImageFilter

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:campus_bus_management/driver/screen/attendance_screen.dart';
import 'package:campus_bus_management/driver/screen/view_notification_screen.dart';
import 'package:campus_bus_management/driver/screen/view_student_attendance_screen.dart';
import 'package:campus_bus_management/driver/screen/view_student_details.dart';
import 'package:campus_bus_management/login.dart';

class DriverDashboardScreen extends StatefulWidget {
  final String driverName;
  final String driverId;

  const DriverDashboardScreen({
    super.key,
    required this.driverName,
    required this.driverId,
  });

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int totalStudents = 0;
  String driverEmail = ""; // Fetch dynamically
  int totalNotifications = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Fetch allocations to get total students
      final allocationResponse = await http.get(
        Uri.parse(
          'http://172.20.10.9:5000/api/allocations/allocations/driver/${widget.driverId}',
        ),
      );
      if (allocationResponse.statusCode == 200) {
        final allocations = jsonDecode(allocationResponse.body) as List;
        setState(() {
          totalStudents = allocations.length;
        });
      } else {
        print('Failed to fetch allocations: ${allocationResponse.statusCode}');
      }

      // Fetch notifications for driver role
      final notificationResponse = await http.get(
        Uri.parse('http://172.20.10.9:5000/api/notifications/view/Drivers'),
      );
      if (notificationResponse.statusCode == 200) {
        final notifications = jsonDecode(notificationResponse.body) as List;
        setState(() {
          totalNotifications = notifications.length;
        });
      } else {
        print(
          'Failed to fetch notifications: ${notificationResponse.statusCode}',
        );
      }

      // Fetch driver email
      final driverResponse = await http.get(
        Uri.parse('http://172.20.10.9:5000/api/drivers/${widget.driverId}'),
      );
      if (driverResponse.statusCode == 200) {
        final driverData = jsonDecode(driverResponse.body);
        setState(() {
          driverEmail = driverData['email'] ?? "No Email";
        });
      } else {
        print('Failed to fetch driver email: ${driverResponse.statusCode}');
        setState(() {
          driverEmail = "No Email";
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() {
        driverEmail = "No Email";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade800.withOpacity(0.3),
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
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                height:
                    MediaQuery.of(context).padding.top +
                    AppBar().preferredSize.height +
                    16,
              ),
              _buildLiquidGlassCard(
                icon: Icons.person_outline,
                title: "Welcome, ${widget.driverName}!",
                gradientColors: [
                  Colors.purple.shade300,
                  Colors.deepPurple.shade600,
                ],
                iconColor: Colors.purpleAccent.shade100,
                subtitle: '',
              ),
              const SizedBox(height: 16),
              _statCard("Total Students", "$totalStudents", Icons.group),
              const SizedBox(height: 16),
              _statCard(
                "Total Notifications",
                "$totalNotifications",
                Icons.notifications,
              ),
            ],
          ),
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
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade600],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade900.withOpacity(0.4),
                image: DecorationImage(
                  image: NetworkImage(
                    'https://placehold.co/600x400/311B92/FFFFFF?text=Driver+Dashboard',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.only(bottom: 16.0, left: 16.0),
                    child: Text(
                      'Driver Menu\nName : ${widget.driverName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 5.0,
                            color: Colors.black54,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              Icons.person,
              "View Student Details",
              ViewStudentDetailsScreen(driverId: widget.driverId),
            ),
            _buildDrawerItem(
              context,
              Icons.check_circle_outline,
              "Attendance",
              // "View your daily attendance records",
              // Colors.lightBlueAccent,
              const FaceAttendanceScreen(),
            ),
            _buildDrawerItem(
              context,
              Icons.notifications,
              "View Notifications",
              const ViewNotificationsScreen(userRole: 'Drivers'),
            ),
            _buildDrawerItem(
              context,
              Icons.calendar_today,
              "View Attendance",
              ViewAttendanceScreen(driverId: widget.driverId),
            ),
            const Divider(color: Colors.white54, thickness: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
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
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: ListTile(
            leading: Icon(icon, color: Colors.white.withOpacity(0.9)),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            tileColor: Colors.white.withOpacity(0.08),
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
    );
  }

  Widget _statCard(String title, String subtitle, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.amberAccent.shade200, size: 48),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                  shadows: [
                    Shadow(
                      blurRadius: 5.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGlassCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required Color iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 48),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                  shadows: [
                    Shadow(
                      blurRadius: 5.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
