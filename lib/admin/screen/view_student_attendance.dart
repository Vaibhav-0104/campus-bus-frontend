import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ViewStudentAttendance extends StatefulWidget {
  const ViewStudentAttendance({super.key});

  @override
  State<ViewStudentAttendance> createState() => _ViewStudentAttendanceState();
}

class _ViewStudentAttendanceState extends State<ViewStudentAttendance> {
  DateTime? selectedDate;
  String? selectedBus;
  List<Map<String, dynamic>> studentAttendanceList = [];
  bool isLoading = false;
  String? errorMessage;

  // Replace with your backend API base URL
  final String apiBaseUrl = 'http://192.168.31.104:5000/api';

  // Fetch bus numbers from backend
  final List<String> busNumbers = [];

  @override
  void initState() {
    super.initState();
    _fetchBusNumbers();
  }

  // Fetch available bus numbers
  Future<void> _fetchBusNumbers() async {
    try {
      print('Fetching bus numbers from $apiBaseUrl/buses');
      final response = await http.get(Uri.parse('$apiBaseUrl/buses'));
      print('Bus numbers response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> buses = jsonDecode(response.body);
        setState(() {
          busNumbers.clear();
          busNumbers.addAll(buses.map((bus) => bus['busNumber'].toString()));
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load bus numbers: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error fetching bus numbers: $e');
      setState(() {
        errorMessage = 'Error fetching bus numbers: $e';
      });
    }
  }

  // Fetch attendance data
  Future<void> _fetchAttendance() async {
    if (selectedDate == null || selectedBus == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      studentAttendanceList.clear();
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      print('Fetching allocations for bus: $selectedBus');
      final allocationsResponse = await http.get(
        Uri.parse('$apiBaseUrl/allocations/allocations?busNumber=$selectedBus'),
      );
      print(
        'Allocations response: ${allocationsResponse.statusCode} ${allocationsResponse.body}',
      );

      if (allocationsResponse.statusCode != 200) {
        setState(() {
          errorMessage =
              'Failed to load bus allocations: ${allocationsResponse.statusCode} ${allocationsResponse.body}';
          isLoading = false;
        });
        return;
      }

      final List<dynamic> allocations = jsonDecode(allocationsResponse.body);
      final studentIds =
          allocations
              .map((allocation) => allocation['studentId']['_id'].toString())
              .toList();

      if (studentIds.isEmpty) {
        setState(() {
          errorMessage = 'No students allocated to this bus';
          isLoading = false;
        });
        return;
      }

      print(
        'Fetching attendance for students: $studentIds on date: $formattedDate',
      );
      final attendanceResponse = await http.post(
        Uri.parse('$apiBaseUrl/students/attendance/by-date'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'date': formattedDate, 'studentIds': studentIds}),
      );
      print(
        'Attendance response: ${attendanceResponse.statusCode} ${attendanceResponse.body}',
      );

      if (attendanceResponse.statusCode == 200) {
        final List<dynamic> attendanceData = jsonDecode(
          attendanceResponse.body,
        );
        setState(() {
          studentAttendanceList =
              attendanceData.map((data) {
                return {
                  'name': data['studentId']['name'],
                  'status': data['status'],
                };
              }).toList();
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load attendance data: ${attendanceResponse.statusCode}';
        });
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      setState(() {
        errorMessage = 'Error fetching attendance: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        if (selectedBus != null) {
          _fetchAttendance();
        }
      });
    }
  }

  Widget _attendanceStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status == 'Present' ? Colors.deepPurple : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 244, 245),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(103, 58, 183, 1),
        title: const Text(
          'View Student Attendance Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Select Date"),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.black,
              ),
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                selectedDate == null
                    ? "Select Date"
                    : "Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}",
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Select Bus Number"),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              value: selectedBus,
              hint: const Text("Choose Bus Number"),
              items:
                  busNumbers
                      .map(
                        (bus) => DropdownMenuItem(value: bus, child: Text(bus)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  selectedBus = value;
                  if (selectedDate != null) {
                    _fetchAttendance();
                  }
                });
              },
            ),
            const SizedBox(height: 30),
            _buildSectionTitle("Student Attendance List"),
            const SizedBox(height: 10),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : selectedBus == null || selectedDate == null
                      ? const Center(
                        child: Text(
                          "Please select both date and bus number to view attendance.",
                          style: TextStyle(
                            color: Color.fromARGB(179, 16, 16, 16),
                          ),
                        ),
                      )
                      : studentAttendanceList.isEmpty
                      ? const Center(
                        child: Text(
                          "No attendance records found.",
                          style: TextStyle(
                            color: Color.fromARGB(179, 16, 16, 16),
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: studentAttendanceList.length,
                        itemBuilder: (context, index) {
                          final student = studentAttendanceList[index];
                          return Card(
                            color: const Color(0xFF2C5364),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Text(
                                  student["name"][0],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                student["name"],
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: _attendanceStatusChip(
                                student["status"],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
