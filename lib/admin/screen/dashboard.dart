import 'package:flutter/material.dart';
import 'package:campus_bus_management/login.dart';
import 'package:campus_bus_management/admin/screen/manage_bus_details.dart';
import 'package:campus_bus_management/admin/screen/manage_driver_details.dart';
import 'package:campus_bus_management/admin/screen/allocate_bus_to_student.dart';
import 'package:campus_bus_management/admin/screen/manage_student_details.dart';
import 'package:campus_bus_management/admin/screen/manage_student_fees.dart';
import 'package:campus_bus_management/admin/screen/manage_notification.dart';
import 'package:campus_bus_management/admin/screen/view_student_attendance.dart';
import 'package:campus_bus_management/admin/screen/reports.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 252, 253),
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 1, // Changed to 1 to stack cards vertically
              childAspectRatio:
                  constraints.maxWidth / 150, // Adjust the height of the card
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _statCard("Total Student", "100"),
                _statCard("Total Driver", "10"),
                _statCard("Total Bus", "7"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: const Text(
              'Campus Bus Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.directions_bus,
            "Manage Bus Details",
            const ManageBusDetailsScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.person,
            "Manage Driver Details",
            const ManageBusDriverDetailsScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.school,
            "Manage Student Details",
            const ManageStudentDetailsScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.swap_horiz,
            "Allocate Bus to Student",
            const AllocateBusScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.payment,
            "Manage Fees",
            const ManageFeesScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.notifications,
            "Manage Notifications",
            const NotificationsScreen(userRole: "Admin"),
          ),
          _buildDrawerItem(
            context,
            Icons.assignment,
            "View Student Attendance",
            const ViewStudentAttendance(),
          ),
          _buildDrawerItem(
            context,
            Icons.bar_chart,
            "Reports",
            const ReportsScreen(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
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
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.deepPurple,
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

  Widget _statCard(String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            Colors.blue, // First gradient color
            Colors.purple, // Second gradient color
            Colors.red, // Third gradient color
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16), // Padding around the text
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
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
