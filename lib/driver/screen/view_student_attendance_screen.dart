import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:campus_bus_management/config/api_config.dart'; // Import centralized URL

class ViewAttendanceScreen extends StatefulWidget {
  final String driverId; // Driver ID passed to the screen

  const ViewAttendanceScreen({super.key, required this.driverId});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allAttendance = [];
  List<Map<String, dynamic>> _filteredAttendance = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData(); // Fetch data on initialization
    _searchController.addListener(() {
      _filterAttendance(_searchController.text);
    });
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allAttendance = []; // Clear previous data
      _filteredAttendance = []; // Clear previous data
    });

    try {
      // Step 1: Fetch allocations for the driver's bus
      final allocationsResponse = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/allocations/allocations/driver/${widget.driverId}',
        ),
      );

      if (allocationsResponse.statusCode != 200) {
        throw Exception(
          'Failed to fetch driver allocations: ${allocationsResponse.body}',
        );
      }

      final allocationsData =
          jsonDecode(allocationsResponse.body) as List<dynamic>;
      final studentIds =
          allocationsData
              .map((allocation) => allocation['studentId']['_id'].toString())
              .toList();

      if (studentIds.isEmpty) {
        setState(() {
          _allAttendance = [];
          _filteredAttendance = [];
          _isLoading = false;
          _errorMessage = "No students allocated to this driver.";
        });
        return;
      }

      // Step 2: Fetch attendance for the selected date and student IDs
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final attendanceResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/students/attendance/date'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'date': formattedDate, 'studentIds': studentIds}),
      );

      if (attendanceResponse.statusCode == 200) {
        final attendanceData =
            jsonDecode(attendanceResponse.body) as List<dynamic>;
        setState(() {
          _allAttendance =
              attendanceData
                  .map(
                    (record) => {
                      'name': record['studentId']['name'],
                      'status': record['status'],
                    },
                  )
                  .toList();
          _filteredAttendance = _allAttendance;
          _isLoading = false;
        });
        if (_allAttendance.isEmpty) {
          _errorMessage = "No attendance records found for the selected date.";
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch attendance: ${attendanceResponse.statusCode} - ${attendanceResponse.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Error fetching attendance: $e. Please check your network or server.';
        _isLoading = false;
      });
    }
  }

  void _filterAttendance(String query) {
    setState(() {
      _filteredAttendance =
          _allAttendance
              .where(
                (student) =>
                    student['name'].toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1),
      lastDate: now, // Restrict to today or past dates
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchAttendanceData(); // Refresh data when date changes
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to build a liquid glass card for consistent styling
  Widget _buildLiquidGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: padding ?? const EdgeInsets.all(25),
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
          child: child,
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
          "View Student Attendance",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(0.4),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
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
        child: Column(
          children: [
            SizedBox(
              height:
                  AppBar().preferredSize.height +
                  MediaQuery.of(context).padding.top +
                  16,
            ),
            _buildDatePicker(context),
            _buildSearchBar(),
            Expanded(child: _buildAttendanceList()),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildLiquidGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.white.withOpacity(0.8),
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  'Date:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              width: 150,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _selectDate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade400.withOpacity(0.6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_calendar, size: 20, color: Colors.yellow),
                    SizedBox(width: 8),
                    Text("Change Date", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildLiquidGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.8),
              size: 28,
            ),
            hintText: "Search student by name...",
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterAttendance('');
                      },
                    )
                    : null,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildLiquidGlassCard(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.redAccent.shade100),
            ),
          ),
        ),
      );
    }
    if (_filteredAttendance.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildLiquidGlassCard(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Text(
              _searchController.text.isEmpty
                  ? "No students found for the selected date."
                  : "No students matching \"${_searchController.text}\" found.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredAttendance.length,
      itemBuilder: (context, index) {
        final student = _filteredAttendance[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildAttendanceCard(student['name'], student['status']),
        );
      },
    );
  }

  Widget _buildAttendanceCard(String name, String status) {
    bool isPresent = status == 'Present';
    Color iconBackgroundColor =
        isPresent ? Colors.green.shade600 : Colors.red.shade600;
    IconData statusIcon = isPresent ? Icons.check : Icons.close;
    Color statusTextColor = isPresent ? Colors.greenAccent : Colors.redAccent;

    return _buildLiquidGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconBackgroundColor,
            radius: 28,
            child: Icon(statusIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Status: ",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: statusTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}
