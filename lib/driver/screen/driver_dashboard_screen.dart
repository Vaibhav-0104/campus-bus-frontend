import 'dart:convert';
import 'dart:ui';
import 'package:campus_bus_management/driver/screen/live_location_share_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:campus_bus_management/config/api_config.dart';
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
  int totalNotifications = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Fetch total students
      final allocationResponse = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/allocations/allocations/driver/${widget.driverId}',
        ),
      );
      if (allocationResponse.statusCode == 200) {
        final allocations = jsonDecode(allocationResponse.body) as List;
        setState(() {
          totalStudents = allocations.length;
        });
      }

      // Fetch total notifications
      final notificationResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/view/Drivers'),
      );
      if (notificationResponse.statusCode == 200) {
        final notifications = jsonDecode(notificationResponse.body) as List;
        setState(() {
          totalNotifications = notifications.length;
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                splashColor: Colors.amber.withOpacity(0.4),
                highlightColor: Colors.amber.withOpacity(0.2),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushReplacement(
                    context,
                    _fadeRoute(const LoginScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D), Color(0xFF121212)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // CARD 1: Welcome
                _glassCard(
                  gradientColors: [
                    Colors.amber.shade600,
                    Colors.amber.shade800,
                  ],
                  icon: Icons.person_outline,
                  iconColor: Colors.black87,
                  title: "Welcome, ${widget.driverName}!",
                  subtitle: "Have a safe journey!",
                ),
                const SizedBox(height: 16),

                // CARD 2: Total Students → CLICKABLE
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      _fadeRoute(
                        ViewStudentDetailsScreen(driverId: widget.driverId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(25),
                  splashColor: Colors.amber.withOpacity(0.3),
                  child: _glassCard(
                    icon: Icons.group,
                    iconColor: Colors.amber,
                    title: "Total Students",
                    subtitle: "$totalStudents",
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // CARD 3: Total Notifications → CLICKABLE
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      _fadeRoute(
                        const ViewNotificationsScreen(userRole: 'Drivers'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(25),
                  splashColor: Colors.amber.withOpacity(0.3),
                  child: _glassCard(
                    icon: Icons.notifications_active,
                    iconColor: Colors.amber,
                    title: "Total Notifications",
                    subtitle: "$totalNotifications",
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Glass Card
  Widget _glassCard({
    IconData? icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    List<Color>? gradientColors,
    Color? textColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  gradientColors ??
                  [
                    Colors.white.withOpacity(0.15),
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
                blurRadius: 25,
                offset: const Offset(8, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(-5, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 48, color: iconColor),
                const SizedBox(height: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.black87,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.4),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Drawer
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 120,
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Driver Menu",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Name: ${widget.driverName}",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(
              Icons.person,
              "View Student Details",
              ViewStudentDetailsScreen(driverId: widget.driverId),
            ),
            _drawerItem(
              Icons.check_circle_outline,
              "Attendance",
              const FaceAttendanceScreen(),
            ),
            _drawerItem(
              Icons.notifications,
              "View Notifications",
              const ViewNotificationsScreen(userRole: 'Drivers'),
            ),
            _drawerItem(
              Icons.calendar_today,
              "View Attendance",
              ViewAttendanceScreen(driverId: widget.driverId),
            ),
            _drawerItem(
              Icons.location_on,
              "Live Location",
              LiveLocationShareScreen(driverId: widget.driverId),
            ),
            const Divider(color: Colors.white24, height: 1),
            _drawerItem(
              Icons.logout,
              "Logout",
              const LoginScreen(),
              pushReplacement: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String title,
    Widget screen, {
    bool pushReplacement = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.amber.withOpacity(0.5),
          highlightColor: Colors.amber.withOpacity(0.25),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 180), () {
              if (pushReplacement) {
                Navigator.pushReplacement(context, _fadeRoute(screen));
              } else {
                Navigator.push(context, _fadeRoute(screen));
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.amber, size: 26),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
