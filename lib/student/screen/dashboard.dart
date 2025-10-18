import 'package:campus_bus_management/student/screen/preview_fees.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:intl/intl.dart'; // For date formatting and month names
import 'package:campus_bus_management/login.dart';
import 'package:campus_bus_management/student/screen/help.dart';
import 'package:campus_bus_management/student/screen/fees_screen.dart'; // Ensure this is the correct path to FeesPaymentScreen
import 'package:campus_bus_management/driver/screen/attendance_screen.dart';
import 'package:campus_bus_management/student/screen/notifications_screen.dart';
import 'package:campus_bus_management/student/screen/monthly_attendance_screen.dart'; // New import for the monthly attendance screen
import 'package:campus_bus_management/config/api_config.dart'; // ✅ Import centralized URL

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
  String currentMonthName = DateFormat('MMMM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  // Helper to calculate total possible days in a month, excluding Sundays
  int _getTotalPossibleDaysInMonth(int year, int month) {
    int totalDays = 0;
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    // Loop through each day of the month, ensuring the last day is included
    for (
      var d = firstDayOfMonth;
      !d.isAfter(lastDayOfMonth);
      d = d.add(const Duration(days: 1))
    ) {
      if (d.weekday != DateTime.sunday) {
        totalDays++;
      }
    }
    return totalDays;
  }

  Future<void> fetchDashboardData() async {
    try {
      // Fetch Total Fees
      final feesResponse = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/fees/student/${widget.envNumber}'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      print(
        'Fees API Response: Status=${feesResponse.statusCode}, Body=${feesResponse.body}',
      );
      if (feesResponse.statusCode == 200) {
        final feesData = jsonDecode(feesResponse.body);
        setState(() {
          // Check for 'feeAmount' or 'amount' as per backend response
          totalFees =
              (feesData['feeAmount']?.toString() ??
                  feesData['amount']?.toString() ??
                  '0') +
              " INR"; // Appending INR for clarity
          if (totalFees == '0 INR') {
            print(
              'Warning: Total Fees is 0, check if fee record exists for envNumber=${widget.envNumber}',
            );
          }
        });
      } else if (feesResponse.statusCode == 404) {
        setState(() {
          totalFees = 'No Fee Set'; // Specific message for 404
        });
      } else {
        print(
          'Fees API Error: Status=${feesResponse.statusCode}, Response=${feesResponse.body}',
        );
        setState(() {
          totalFees = 'Unavailable';
        });
      }

      // Fetch Attendance for Current Month
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(
        now.year,
        now.month + 1,
        0,
      ); // Last day of current month

      final attendanceResponse = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/students/attendance/by-date', // This route should map to getAttendancePercentageByDateRange
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'envNumber': widget.envNumber,
              'startDate': DateFormat('yyyy-MM-dd').format(firstDayOfMonth),
              'endDate': DateFormat('yyyy-MM-dd').format(lastDayOfMonth),
            }),
          )
          .timeout(const Duration(seconds: 10));
      print(
        'Attendance API Response: Status=${attendanceResponse.statusCode}, Body=${attendanceResponse.body}',
      );
      if (attendanceResponse.statusCode == 200) {
        final attendanceData = jsonDecode(attendanceResponse.body);
        setState(() {
          int presentDays = 0;
          if (attendanceData['presentDays'] != null) {
            presentDays = attendanceData['presentDays'] as int;
          }

          final int totalPossibleDaysInCurrentMonth =
              _getTotalPossibleDaysInMonth(now.year, now.month);

          double calculatedPercentage = 0.0;
          if (totalPossibleDaysInCurrentMonth > 0) {
            calculatedPercentage =
                (presentDays / totalPossibleDaysInCurrentMonth) * 100;
          }

          attendance =
              '${presentDays} / ${totalPossibleDaysInCurrentMonth} days (${calculatedPercentage.toStringAsFixed(1)}%)';

          if (attendanceData['message'] != null &&
              attendanceData['message'].contains("No attendance data")) {
            attendance =
                "No data this month"; // More specific for current month
          }
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
            Uri.parse('${ApiConfig.baseUrl}/notifications/view/Students'),
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

  // A reusable widget to create a "Liquid Glass" style card
  Widget _buildLiquidGlassCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    Color iconColor = Colors.white, // Default icon color
    VoidCallback? onTap, // Added onTap callback
  }) {
    return GestureDetector(
      // Make the card tappable
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25), // Increased rounded corners
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15.0,
              sigmaY: 15.0,
            ), // Stronger blur effect
            child: Container(
              padding: const EdgeInsets.all(25), // Increased padding
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      gradientColors
                          .map((color) => color.withOpacity(0.15))
                          .toList(), // Slightly more transparent gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ), // Lighter border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.2,
                    ), // Darker shadow for depth
                    blurRadius: 25, // Increased blur radius
                    spreadRadius: 3, // Increased spread radius
                    offset: const Offset(8, 8), // More pronounced offset
                  ),
                  BoxShadow(
                    // Inner light shadow for a subtle glow
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: Offset(-5, -5), // Top-left inner glow
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 52, // Even larger icon size
                    color: iconColor,
                    shadows: [
                      Shadow(
                        blurRadius: 12.0, // More blur for icon shadow
                        color: Colors.black.withOpacity(0.6),
                        offset: Offset(3.0, 3.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), // Increased spacing
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24, // Larger title font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 6.0,
                          color: Colors.black45,
                          offset: Offset(1.5, 1.5),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10), // Increased spacing
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 19, // Larger subtitle font size
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Extend body behind app bar for full gradient
      appBar: AppBar(
        title: const Text(
          "Student Dashboard", // Generic title for the dashboard
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(
          0.3,
        ), // Even more transparent app bar
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0, // Remove shadow for flat look
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
      drawer: _buildDrawer(context), // The navigation drawer
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade500,
            ], // Richer gradient background
            stops: const [
              0.0,
              0.5,
              1.0,
            ], // Adjusted stops for smoother transition
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top + 20,
              ), // Spacing below app bar
              // Combined Student Name & Email Card
              _buildLiquidGlassCard(
                icon: Icons.person_outline,
                title: "Welcome, ${widget.studentName}!",
                subtitle: "Email: ${widget.studentEmail}",
                gradientColors: [Colors.blue.shade300, Colors.cyan.shade600],
                iconColor: Colors.lightBlueAccent.shade100,
              ),
              // Total Fees Card
              _buildLiquidGlassCard(
                icon: Icons.payments_outlined,
                title: "Total Fees",
                subtitle: totalFees,
                gradientColors: [Colors.orange.shade300, Colors.red.shade600],
                iconColor: Colors.orangeAccent.shade100,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              PreviewFeesScreen(envNumber: widget.envNumber),
                    ),
                  );
                },
              ),
              // Attendance Card (now navigable to MonthlyAttendanceScreen)
              _buildLiquidGlassCard(
                icon: Icons.fingerprint,
                title: "Attendance",
                subtitle:
                    "$currentMonthName Average: $attendance", // Display current month average
                gradientColors: [Colors.purple.shade300, Colors.pink.shade600],
                iconColor: Colors.purpleAccent.shade100,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MonthlyAttendanceScreen(
                            envNumber: widget.envNumber,
                          ),
                    ),
                  );
                },
              ),
              // Notifications Card
              _buildLiquidGlassCard(
                icon: Icons.notifications_active_outlined,
                title: "New Notifications",
                subtitle: notifications,
                gradientColors: [Colors.indigo.shade300, Colors.blue.shade600],
                iconColor: Colors.blueAccent.shade100,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ViewNotificationsScreen(userRole: 'Students'),
                    ),
                  );
                },
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
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade600,
              Colors.deepPurple.shade400,
            ], // Enhanced gradient for richer background
            stops: const [0.0, 0.5, 1.0], // Smooth gradient transition
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Liquid Glass Drawer Header
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(15), // Unified padding
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  20,
                ), // Consistent rounded corners
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 15.0,
                    sigmaY: 15.0,
                  ), // Strong blur effect
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade800.withOpacity(0.4),
                          Colors.purple.shade400.withOpacity(0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(5, 5),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(-5, -5), // Inner glow effect
                        ),
                      ],
                    ),
                    // Center the content in the container
                    child: Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Center vertically
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // Center horizontally
                        children: [
                          Text(
                            widget.studentName,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 6, color: Colors.black54),
                              ],
                            ),
                            textAlign:
                                TextAlign.center, // Ensure text is centered
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.studentEmail,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign:
                                TextAlign.center, // Ensure text is centered
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enrollment: ${widget.envNumber}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white60,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign:
                                TextAlign.center, // Ensure text is centered
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Liquid Glass Drawer Items
            // _buildDrawerItem(
            //   Icons.check_circle_outline,
            //   "Attendance",
            //   "View your daily attendance records",
            //   Colors.lightBlueAccent,
            //   const FaceAttendanceScreen(),
            // ),
            _buildDrawerItem(
              Icons.payment,
              "Pay Fees",
              "Manage and pay your bus fees",
              Colors.greenAccent,
              FeesPaymentScreen(envNumber: widget.envNumber),
            ),
            _buildDrawerItem(
              Icons.notifications_none,
              "Notifications",
              "Check for new announcements and updates",
              Colors.orangeAccent,
              const ViewNotificationsScreen(userRole: 'Students'),
            ),
            _buildDrawerItem(
              Icons.help_outline,
              "Help & Support",
              "Get assistance and contact support",
              Colors.purpleAccent,
              const HelpSupportScreen(),
            ),
            const Divider(color: Colors.white30, height: 20, thickness: 1),
            // Logout item (can also be liquid glass if desired)
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
    IconData icon,
    String title,
    String description,
    Color iconColor,
    Widget screen,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 5.0,
      ), // Add padding for liquid glass cards
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          15,
        ), // Rounded corners for each drawer item
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10.0,
            sigmaY: 10.0,
          ), // Blur effect for liquid glass
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.deepPurple.shade300.withOpacity(0.1),
                ], // Subtle gradient for drawer items
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
              ), // Light border
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
              leading: Icon(
                icon,
                color: iconColor,
                size: 28,
              ), // Larger icon with specific color
              title: Column(
                // Wrap title and description in a Column
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align text to the left
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white, // White text for consistency
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(blurRadius: 3, color: Colors.black54),
                      ], // Text shadow
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ), // Small spacing between title and description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color:
                          Colors
                              .white70, // Slightly transparent white for description
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
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
}
