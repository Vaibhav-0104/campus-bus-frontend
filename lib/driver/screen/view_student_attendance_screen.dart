import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:campus_bus_management/config/api_config.dart';

class ViewAttendanceScreen extends StatefulWidget {
  final String driverId;
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
    _fetchAttendanceData();
    _searchController.addListener(() {
      _filterAttendance(_searchController.text);
    });
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allAttendance = [];
      _filteredAttendance = [];
    });

    try {
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
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black87,
              surface: Color(0xFF2D2D2D),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.amber),
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
      await _fetchAttendanceData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Reusable Glass Card
  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "View Student Attendance",
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
      ),
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
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Date Picker Card
              _buildDatePicker(context),

              // Proper Spacing Added
              const SizedBox(height: 20),

              // Search Bar
              _buildSearchBar(),

              const SizedBox(height: 16),

              // Attendance List
              Expanded(child: _buildAttendanceList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _glassCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, color: Colors.amber, size: 26),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.edit_calendar, color: Colors.black87),
              label: const Text(
                "Change Date",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 10,
                shadowColor: Colors.black.withOpacity(0.6),
              ).copyWith(
                overlayColor: MaterialStateProperty.all(Colors.amber.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _glassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.amber, size: 28),
            hintText: "Search student by name...",
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 18,
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
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
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: _glassCard(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    if (_filteredAttendance.isEmpty) {
      return Center(
        child: _glassCard(
          padding: const EdgeInsets.all(24),
          child: Text(
            _searchController.text.isEmpty
                ? "No students found for the selected date."
                : "No students matching \"${_searchController.text}\" found.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredAttendance.length,
      itemBuilder: (context, index) {
        final student = _filteredAttendance[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildAttendanceCard(student['name'], student['status']),
        );
      },
    );
  }

  Widget _buildAttendanceCard(String name, String status) {
    bool isPresent = status == 'Present';
    return _glassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                isPresent ? Colors.green.shade600 : Colors.red.shade600,
            child: Icon(
              isPresent ? Icons.check : Icons.close,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black54,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Status: $status",
                  style: TextStyle(
                    fontSize: 16,
                    color: isPresent ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
