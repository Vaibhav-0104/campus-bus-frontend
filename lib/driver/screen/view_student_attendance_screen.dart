import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

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
    _filteredAttendance = _allAttendance;
    _fetchAttendanceData(); // Fetch data on initialization
    _searchController.addListener(() {
      _filterAttendance(_searchController.text);
    });
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Fetch allocations for the driver's bus
      final allocationsResponse = await http.get(
        Uri.parse(
          'http://192.168.31.104:5000/api/allocations/allocations/driver/${widget.driverId}',
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
        });
        return;
      }

      // Step 2: Fetch attendance for the selected date and student IDs
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final attendanceResponse = await http.post(
        Uri.parse('http://192.168.31.104:5000/api/students/attendance/by-date'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'date': formattedDate, 'studentIds': studentIds}),
      );

      if (attendanceResponse.statusCode != 200) {
        throw Exception(
          'Failed to fetch attendance: ${attendanceResponse.body}',
        );
      }

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
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching attendance: $e';
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1),
      lastDate: DateTime(2025, 12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "View Student Attendance",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildDatePicker(context),
          _buildSearchBar(),
          Expanded(child: _buildAttendanceList()),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Selected Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          ElevatedButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text("Pick Date"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 229, 230, 232),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: "Search student by name...",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }
    if (_filteredAttendance.isEmpty) {
      return const Center(
        child: Text(
          "No students found for the selected date.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredAttendance.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final student = _filteredAttendance[index];
        return ListTile(
          tileColor:
              student['status'] == 'Present'
                  ? Colors.green.shade50
                  : Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: CircleAvatar(
            backgroundColor:
                student['status'] == 'Present' ? Colors.green : Colors.red,
            child: Icon(
              student['status'] == 'Present' ? Icons.check : Icons.close,
              color: Colors.white,
            ),
          ),
          title: Text(
            student['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          trailing: Text(
            student['status'],
            style: TextStyle(
              color:
                  student['status'] == 'Present'
                      ? Colors.green.shade800
                      : Colors.red.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
