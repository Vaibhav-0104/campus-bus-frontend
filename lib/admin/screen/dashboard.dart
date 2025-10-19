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
// Note: You must create and import the new screen
// For simplicity, the new screen code is included at the bottom of this file.

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
      ); // Updated URL
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
      ); // Updated URL
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
      ); // Updated URL
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

                  // 👇 WRAPPED IN GESTUREDETECTOR TO NAVIGATE
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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

// ----------------------------------------------------------------------
//
// New Screen to Display All Driver Details: ShowDriversScreen
//
// ----------------------------------------------------------------------

class ShowDriversScreen extends StatefulWidget {
  const ShowDriversScreen({super.key});

  @override
  State<ShowDriversScreen> createState() => _ShowDriversScreenState();
}

class _ShowDriversScreenState extends State<ShowDriversScreen> {
  Future<List<Driver>>? _driversFuture;

  @override
  void initState() {
    super.initState();
    _driversFuture = fetchDrivers();
  }

  // Fetch all drivers from the backend /api/drivers endpoint
  Future<List<Driver>> fetchDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/drivers'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> driversJson = jsonDecode(response.body);
        return driversJson.map((json) => Driver.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load drivers. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching drivers: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Drivers Details'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade700],
          ),
        ),
        child: FutureBuilder<List<Driver>>(
          future: _driversFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error: ${snapshot.error.toString().contains('Failed to load') ? 'Failed to connect to server or load data.' : 'An unexpected error occurred.'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No drivers found.',
                  style: TextStyle(color: Colors.white70, fontSize: 20),
                ),
              );
            }

            final drivers = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                return DriverDetailCard(driver: drivers[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

// Data Model to map API response
class Driver {
  final String id;
  final String name;
  final String contact;
  final String license;
  final String email;
  final String status;
  final String? licenseDocument;

  Driver({
    required this.id,
    required this.name,
    required this.contact,
    required this.license,
    required this.email,
    required this.status,
    this.licenseDocument,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id'] as String,
      name: json['name'] as String,
      contact: json['contact'] as String,
      license: json['license'] as String,
      email: json['email'] as String,
      // Note: password is removed from the model as it's not needed for display
      status: json['status'] as String,
      licenseDocument: json['licenseDocument'] as String?,
    );
  }
}

// UI Card Component for each Driver
class DriverDetailCard extends StatelessWidget {
  final Driver driver;

  const DriverDetailCard({super.key, required this.driver});

  // Helper method to resolve the full URL for the document
  String _getDocumentUrl(String? docPath) {
    if (docPath == null || docPath.isEmpty) {
      return '';
    }
    // Your backend serves files under /uploads route
    // The server.js has: app.use('/api/uploads', express.static(path.join(path.resolve(), 'uploads')));
    // The driverController.js saves: licenseDocument: `/uploads/${req.file.filename}`
    // You need to combine the base URL and the relative path
    // Example: http://your-api-url.com/api/uploads/driver-license-1234.pdf
    return '${ApiConfig.baseUrl}$docPath';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = driver.status == 'Active' ? Colors.green : Colors.red;
    final documentUrl = _getDocumentUrl(driver.licenseDocument);
    final isDocumentAvailable = documentUrl.isNotEmpty;

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Name & Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    driver.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    driver.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1.5, color: Colors.black12),

            // Driver Details
            _buildDetailRow(Icons.email, 'Email:', driver.email),
            _buildDetailRow(Icons.phone, 'Contact:', driver.contact),
            _buildDetailRow(Icons.badge, 'License No:', driver.license),

            const SizedBox(height: 15),

            // License Document/Screenshot
            Text(
              'License Document:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade100,
              ),
              child:
                  isDocumentAvailable
                      ? Center(
                        child: GestureDetector(
                          onTap: () {
                            // Handle document opening/viewing (e.g., launch URL)
                            print('Attempting to open document: $documentUrl');
                            // You would typically use a package like url_launcher here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Document available at: $documentUrl',
                                ),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                size: 40,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'View License Document (Tap)',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.document_scanner,
                              size: 40,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'No Document Uploaded',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.blue.shade600),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
