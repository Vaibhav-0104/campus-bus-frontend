import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:campus_bus_management/config/api_config.dart';

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

  final List<String> busNumbers = [];

  @override
  void initState() {
    super.initState();
    _fetchBusNumbers();
  }

  Future<void> _fetchBusNumbers() async {
    try {
      print('Fetching bus numbers from ${ApiConfig.baseUrl}/buses');
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/buses'));
      print('Bus numbers response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> buses = jsonDecode(response.body);
        setState(() {
          busNumbers.clear();
          busNumbers.addAll(buses.map((bus) => bus['busNumber'].toString()));
          if (busNumbers.length == 1) {
            selectedBus = busNumbers.first;
            if (selectedDate != null) {
              _fetchAttendance();
            }
          }
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
        Uri.parse(
          '${ApiConfig.baseUrl}/allocations/allocations?busNumber=$selectedBus',
        ),
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
        Uri.parse('${ApiConfig.baseUrl}/students/attendance/date'),
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
                  'name': data['studentId']['name'] ?? 'Unknown Student',
                  'status': data['status'] ?? 'Unknown',
                };
              }).toList();
          studentAttendanceList.removeWhere(
            (student) =>
                student['name'] == 'Unknown Student' ||
                student['status'] == 'Unknown',
          );

          if (studentAttendanceList.isEmpty && studentIds.isNotEmpty) {
            errorMessage =
                "No attendance recorded for allocated students on this date.";
          }
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load attendance data: ${attendanceResponse.statusCode}. ${jsonDecode(attendanceResponse.body)['message'] ?? ''}';
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
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2023),
      lastDate: now,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: Colors.blueGrey.shade800,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.blueGrey.shade900,
          ),
          child: child!,
        );
      },
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
    Color chipColor = Colors.grey.shade700;
    if (status == 'Present') {
      chipColor = Colors.green.shade600;
    } else if (status == 'Absent') {
      chipColor = Colors.red.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
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
          'View Student Attendance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800.withOpacity(0.3),
        centerTitle: true,
        elevation: 0,
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
        child: Padding(
          padding: EdgeInsets.only(
            top:
                MediaQuery.of(context).padding.top +
                AppBar().preferredSize.height +
                16,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle("Select Date and Bus:"),
              const SizedBox(height: 20),
              // Select Date
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueGrey.shade300.withOpacity(0.15),
                          Colors.blueGrey.shade700.withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.lightBlueAccent,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              selectedDate == null
                                  ? 'Select Date'
                                  : DateFormat(
                                    'dd MMM yyyy',
                                  ).format(selectedDate!),
                              style: TextStyle(
                                color:
                                    selectedDate == null
                                        ? Colors.white70
                                        : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Select Bus
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueGrey.shade300.withOpacity(0.15),
                          Colors.blueGrey.shade700.withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                    child: DropdownButtonFormField<String>(
                      value: selectedBus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.lightBlueAccent,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.directions_bus,
                          color: Colors.lightBlueAccent,
                        ),
                        labelText: 'Select Bus',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      dropdownColor: Colors.blueGrey.shade800,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items:
                          busNumbers.isEmpty
                              ? [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    'No buses available',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ]
                              : busNumbers.map((bus) {
                                return DropdownMenuItem<String>(
                                  value: bus,
                                  child: Text(bus),
                                );
                              }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBus = value;
                          if (selectedDate != null && value != null) {
                            _fetchAttendance();
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionTitle("Student Attendance List:"),
              const SizedBox(height: 15),
              Expanded(
                child:
                    isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : errorMessage != null
                        ? Center(
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.redAccent.shade100,
                              fontSize: 18,
                            ),
                          ),
                        )
                        : (selectedBus == null ||
                            selectedDate == null ||
                            studentAttendanceList.isEmpty)
                        ? Center(
                          child: Text(
                            studentAttendanceList.isEmpty &&
                                    selectedBus != null &&
                                    selectedDate != null
                                ? "No attendance records found for this selection. Try a different date or bus."
                                : "Please select both a date and a bus number to view attendance.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 18,
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: studentAttendanceList.length,
                          itemBuilder: (context, index) {
                            final student = studentAttendanceList[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 15,
                                    sigmaY: 15,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blueGrey.shade300.withOpacity(
                                            0.1,
                                          ),
                                          Colors.blueGrey.shade700.withOpacity(
                                            0.1,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                          offset: const Offset(5, 5),
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.05),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                          offset: const Offset(-3, -3),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue.shade400
                                            .withOpacity(0.6),
                                        child: Text(
                                          student["name"] != null &&
                                                  student["name"].isNotEmpty
                                              ? student["name"][0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        student["name"] ?? "N/A",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: _attendanceStatusChip(
                                        student["status"],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            blurRadius: 5.0,
            color: Colors.black54,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    );
  }
}
