import 'package:campus_bus_management/student/screen/preview_fees.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:campus_bus_management/login.dart';
import 'package:campus_bus_management/student/screen/help.dart';
import 'package:campus_bus_management/student/screen/fees_screen.dart';
import 'package:campus_bus_management/student/screen/notifications_screen.dart';
import 'package:campus_bus_management/student/screen/monthly_attendance_screen.dart';
import 'package:campus_bus_management/config/api_config.dart';

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

  int _getTotalPossibleDaysInMonth(int year, int month) {
    int totalDays = 0;
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    for (
      var d = firstDayOfMonth;
      !d.isAfter(lastDayOfMonth);
      d = d.add(const Duration(days: 1))
    ) {
      if (d.weekday != DateTime.sunday) totalDays++;
    }
    return totalDays;
  }

  Future<void> fetchDashboardData() async {
    try {
      final feesResponse = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/fees/student/${widget.envNumber}'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (feesResponse.statusCode == 200) {
        final feesData = jsonDecode(feesResponse.body);
        setState(() {
          totalFees =
              (feesData['feeAmount']?.toString() ??
                  feesData['amount']?.toString() ??
                  '0') +
              " INR";
        });
      } else if (feesResponse.statusCode == 404) {
        setState(() => totalFees = 'No Fee Set');
      } else {
        setState(() => totalFees = 'Unavailable');
      }

      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      final attendanceResponse = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/students/attendance/by-date'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'envNumber': widget.envNumber,
              'startDate': DateFormat('yyyy-MM-dd').format(firstDay),
              'endDate': DateFormat('yyyy-MM-dd').format(lastDay),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (attendanceResponse.statusCode == 200) {
        final data = jsonDecode(attendanceResponse.body);
        int presentDays = data['presentDays'] ?? 0;
        int totalDays = _getTotalPossibleDaysInMonth(now.year, now.month);
        double percentage = totalDays > 0 ? (presentDays / totalDays) * 100 : 0;

        setState(() {
          attendance =
              '${presentDays} / $totalDays days (${percentage.toStringAsFixed(1)}%)';
          if (data['message']?.contains("No attendance data") == true) {
            attendance = "No data this month";
          }
        });
      } else {
        setState(() => attendance = 'Unavailable');
      }

      final notifResponse = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/notifications/view/Students'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (notifResponse.statusCode == 200) {
        final data = jsonDecode(notifResponse.body);
        setState(
          () => notifications = (data is List) ? data.length.toString() : '0',
        );
      } else {
        setState(() => notifications = 'Unavailable');
      }
    } catch (e) {
      setState(() {
        totalFees = attendance = notifications = 'Unavailable';
      });
    }
  }

  // GLASS CARD
  Widget _glassCard({
    required Widget content,
    required List<Color> gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient.map((c) => c.withOpacity(0.22)).toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(4, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(-3, -3),
                  ),
                ],
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Student Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF87CEEB), Color(0xFF4682B4), Color(0xFF1E90FF)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Column(
          children: [
            // EXTRA SPACE ADDED HERE
            const SizedBox(
              height: kToolbarHeight + 50,
            ), // Increased from +20 to +50

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // STUDENT INFO CARD
                    _glassCard(
                      gradient: [Colors.blue.shade400, Colors.cyan.shade500],
                      content: Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            child: Text(
                              widget.studentName.isNotEmpty
                                  ? widget.studentName
                                      .trim()
                                      .split(' ')
                                      .first[0]
                                      .toUpperCase()
                                  : "S",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.studentName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.studentEmail,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // FEES + ATTENDANCE ROW
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _glassCard(
                                  gradient:
                                      totalFees.contains("INR")
                                          ? [
                                            Colors.green.shade400,
                                            Colors.green.shade700,
                                          ]
                                          : [
                                            Colors.orange.shade400,
                                            Colors.orange.shade700,
                                          ],
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => PreviewFeesScreen(
                                                envNumber: widget.envNumber,
                                              ),
                                        ),
                                      ),
                                  content: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.payments,
                                        size: 38,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Fees Status",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              totalFees.contains("INR")
                                                  ? Colors.green
                                                  : Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (totalFees.contains("INR"))
                                              const Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            if (totalFees.contains("INR"))
                                              const SizedBox(width: 4),
                                            Text(
                                              totalFees.contains("INR")
                                                  ? "PAID"
                                                  : totalFees,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _glassCard(
                                  gradient: [
                                    Colors.purple.shade400,
                                    Colors.pink.shade500,
                                  ],
                                  onTap:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => MonthlyAttendanceScreen(
                                                envNumber: widget.envNumber,
                                              ),
                                        ),
                                      ),
                                  content: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 66,
                                        height: 66,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value:
                                                  attendance.contains("%")
                                                      ? (double.tryParse(
                                                                attendance
                                                                    .split("(")
                                                                    .last
                                                                    .replaceAll(
                                                                      "%",
                                                                      "",
                                                                    )
                                                                    .replaceAll(
                                                                      ")",
                                                                      "",
                                                                    ),
                                                              ) ??
                                                              0) /
                                                          100
                                                      : 0,
                                              strokeWidth: 5.5,
                                              backgroundColor: Colors.white24,
                                              valueColor:
                                                  const AlwaysStoppedAnimation(
                                                    Colors.white,
                                                  ),
                                            ),
                                            Text(
                                              attendance.contains("%")
                                                  ? "${(double.tryParse(attendance.split("(").last.replaceAll("%", "").replaceAll(")", "")) ?? 0).toStringAsFixed(0)}%"
                                                  : "N/A",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Attendance",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _statusDot(Colors.white, "Present"),
                                          const SizedBox(width: 6),
                                          _statusDot(Colors.white38, "Absent"),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // NOTIFICATIONS CARD
                    _glassCard(
                      gradient: [Colors.indigo.shade400, Colors.blue.shade600],
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ViewNotificationsScreen(
                                    userRole: 'Students',
                                  ),
                            ),
                          ),
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_active,
                                size: 46,
                                color: Colors.white,
                              ),
                              if (notifications != "0" &&
                                  notifications != "Unavailable")
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      notifications,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "New Notifications",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notifications == "0"
                                ? "All caught up!"
                                : "$notifications unread",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
      ],
    );
  }

  // DRAWER
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.studentName.isNotEmpty
                          ? widget.studentName
                              .trim()
                              .split(' ')
                              .first[0]
                              .toUpperCase()
                          : "S",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      widget.studentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      widget.studentEmail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(
              Icons.payment,
              "Pay Fees",
              FeesPaymentScreen(envNumber: widget.envNumber),
            ),
            _drawerItem(
              Icons.notifications,
              "Notifications",
              const ViewNotificationsScreen(userRole: 'Students'),
            ),
            _drawerItem(
              Icons.help,
              "Help & Support",
              const HelpSupportScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}
