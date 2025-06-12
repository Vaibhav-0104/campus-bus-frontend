import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/login.dart';
import 'package:campus_bus_management/student/screen/help.dart';
import 'package:campus_bus_management/student/screen/fees_screen.dart';
import 'package:campus_bus_management/student/screen/attendance_screen.dart';
import 'package:campus_bus_management/student/screen/notifications_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  final String studentName;
  final String studentEmail;
  final String envNumber;

  const StudentDashboardScreen({
    super.key,
    required this.studentName,
    required this.studentEmail,
    required this.envNumber,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  String totalFees = "Loading...";
  String attendance = "Loading...";
  String notifications = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      // Fetch Total Fees
      final feesResponse = await http
          .get(
            Uri.parse(
              'http://192.168.31.104:5000/api/fees/student/${widget.envNumber}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      print(
        'Fees API Response: Status=${feesResponse.statusCode}, Body=${feesResponse.body}',
      );
      if (feesResponse.statusCode == 200) {
        final feesData = jsonDecode(feesResponse.body);
        setState(() {
          totalFees =
              (feesData['totalFees']?.toString() ??
                  feesData['amount']?.toString() ??
                  '0');
          if (totalFees == '0') {
            print(
              'Warning: Total Fees is 0, check if fee record exists for envNumber=${widget.envNumber}',
            );
          }
        });
      } else {
        print(
          'Fees API Error: Status=${feesResponse.statusCode}, Response=${feesResponse.body}',
        );
        setState(() {
          totalFees = 'Unavailable';
        });
      }

      // Fetch Attendance
      final attendanceResponse = await http
          .post(
            Uri.parse(
              'http://192.168.31.104:5000/api/students/attendance/by-date',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'envNumber': widget.envNumber,
              'startDate': '2025-01-01',
              'endDate': '2025-04-27',
            }),
          )
          .timeout(const Duration(seconds: 10));
      print(
        'Attendance API Response: Status=${attendanceResponse.statusCode}, Body=${attendanceResponse.body}',
      );
      if (attendanceResponse.statusCode == 200) {
        final attendanceData = jsonDecode(attendanceResponse.body);
        setState(() {
          attendance =
              attendanceData['percentage'] != null
                  ? '${attendanceData['percentage']}%'
                  : 'No data';
        });
      } else {
        print(
          'Attendance API Error: Status=${attendanceResponse.statusCode}, Response=${attendanceResponse.body}',
        );
        setState(() {
          attendance = 'Unavailable';
        });
      }

      // Fetch Notifications
      final notificationsResponse = await http
          .get(
            Uri.parse(
              'http://192.168.31.104:5000/api/notifications/view/Students',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      print(
        'Notifications API Response: Status=${notificationsResponse.statusCode}, Body=${notificationsResponse.body}',
      );
      if (notificationsResponse.statusCode == 200) {
        final notificationsData = jsonDecode(notificationsResponse.body);
        setState(() {
          notifications =
              (notificationsData is List)
                  ? notificationsData.length.toString()
                  : '0';
        });
      } else {
        print(
          'Notifications API Error: Status=${notificationsResponse.statusCode}, Response=${notificationsResponse.body}',
        );
        setState(() {
          notifications = 'Unavailable';
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() {
        totalFees = 'Unavailable';
        attendance = 'Unavailable';
        notifications = 'Unavailable';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 252, 253),
      appBar: AppBar(
        title: Text(
          "Welcome, ${widget.studentName}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _statCard("Total Fees", totalFees),
              const SizedBox(height: 16),
              _statCard("Attendance", attendance),
              const SizedBox(height: 16),
              _statCard("Notifications", notifications),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent, Colors.redAccent],
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 20,
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepPurple),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.studentEmail,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            Icons.check_circle,
            "Attendance",
            const FaceAttendanceScreen(),
          ),
          _buildDrawerItem(
            Icons.payment,
            "Pay Fees",
            FeesPaymentScreen(envNumber: widget.envNumber),
          ),
          _buildDrawerItem(
            Icons.notifications,
            "Notifications",
            const ViewNotificationsScreen(userRole: 'Students'),
          ),
          _buildDrawerItem(
            Icons.help,
            "Help & Support",
            const HelpSupportScreen(),
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

  Widget _buildDrawerItem(IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
