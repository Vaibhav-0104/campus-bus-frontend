import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:flutter/foundation.dart' show debugPrint; // For debugPrint

class AllocateBusScreen extends StatefulWidget {
  const AllocateBusScreen({super.key});

  @override
  State<AllocateBusScreen> createState() => _AllocateBusScreenState();
}

class _AllocateBusScreenState extends State<AllocateBusScreen> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> buses = [];
  List<Map<String, dynamic>> allocations = [];
  List<String> toDestinations = [];

  String? selectedStudentId;
  String studentName = '';
  String? selectedTo;
  String? selectedBusId;
  List<Map<String, dynamic>> filteredBuses = [];

  @override
  void initState() {
    super.initState();
    fetchStudents();
    fetchBuses();
    fetchAllocations();
  }

  Future<void> fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.20.10.9:5000/api/students'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          students = List<Map<String, dynamic>>.from(
            data.map(
              (student) => {
                'id': student['_id'],
                'envNumber': student['envNumber'],
                'name': student['name'],
              },
            ),
          );
        });
      } else {
        _showSnackBar('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      _showSnackBar('Error fetching students: $e');
    }
  }

  Future<void> fetchBuses() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.20.10.9:5000/api/buses'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          buses = List<Map<String, dynamic>>.from(
            data.map(
              (bus) => {
                'id': bus['_id'],
                'busNumber': bus['busNumber'],
                'to': bus['to'] ?? '',
              },
            ),
          );
          // Extract unique 'to' destinations
          toDestinations =
              buses
                  .map((bus) => bus['to'] as String)
                  .where((to) => to.isNotEmpty)
                  .toSet()
                  .toList();
        });
      } else {
        _showSnackBar('Failed to load buses: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching buses: $e');
      _showSnackBar('Error fetching buses: $e');
    }
  }

  Future<void> fetchAllocations() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.20.10.9:5000/api/allocations/allocations'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allocations = List<Map<String, dynamic>>.from(data);
        });
      } else {
        _showSnackBar('Failed to load allocations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching allocations: $e');
      _showSnackBar('Error fetching allocations: $e');
    }
  }

  Future<void> allocateBus() async {
    if (selectedStudentId != null &&
        selectedBusId != null &&
        selectedTo != null) {
      try {
        final response = await http.post(
          Uri.parse('http://172.20.10.9:5000/api/allocations/allocate'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'studentId': selectedStudentId,
            'busId': selectedBusId,
            'to': selectedTo,
          }),
        );

        if (response.statusCode == 200) {
          fetchAllocations();
          _showSnackBar('Bus allocated successfully!', isSuccess: true);
        } else {
          _showSnackBar(
            'Failed to allocate bus: ${response.statusCode}. ${jsonDecode(response.body)['message'] ?? ''}',
          );
        }
      } catch (e) {
        debugPrint('Error allocating bus: $e');
        _showSnackBar('Error allocating bus: $e');
      }
    } else {
      _showSnackBar('Please select Student, To, and Bus');
    }
  }

  void filterBusesByTo(String? to) {
    setState(() {
      selectedTo = to;
      selectedBusId = null; // Reset bus selection when 'to' changes
      if (to != null && to.isNotEmpty) {
        filteredBuses = buses.where((bus) => bus['to'] == to).toList();
      } else {
        filteredBuses = []; // Clear filtered buses if 'to' is cleared
      }
    });
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Allocate Bus to Student Details',
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
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top:
                AppBar().preferredSize.height +
                MediaQuery.of(context).padding.top +
                16,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCard(),
              const SizedBox(height: 30),
              _buildBusAssignmentTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return ClipRRect(
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
          child: Column(
            children: [
              Text(
                "Allocate Bus to Student",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28 + 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 30),
              _buildDropdownFormField(
                value: selectedStudentId,
                hint: "Select Enrollment Number",
                items:
                    students.map<DropdownMenuItem<String>>((student) {
                      return DropdownMenuItem<String>(
                        value: student['id'] as String,
                        child: Text(
                          "${student['envNumber']}",
                          style: TextStyle(fontSize: 16 + 2),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStudentId = value;
                    studentName =
                        students.firstWhere((s) => s['id'] == value)['name'];
                  });
                },
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildReadOnlyTextField(
                studentName.isEmpty ? "Student Name" : studentName,
                Icons.person,
              ),
              const SizedBox(height: 20),
              _buildDropdownFormField(
                value: selectedTo,
                hint: "Select To Destination",
                items:
                    toDestinations.map<DropdownMenuItem<String>>((to) {
                      return DropdownMenuItem<String>(
                        value: to,
                        child: Text(to, style: TextStyle(fontSize: 16 + 2)),
                      );
                    }).toList(),
                onChanged: filterBusesByTo,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 20),
              _buildDropdownFormField(
                value: selectedBusId,
                hint: "Select Bus",
                items:
                    filteredBuses.map<DropdownMenuItem<String>>((bus) {
                      return DropdownMenuItem<String>(
                        value: bus['id'] as String,
                        child: Text(
                          bus['busNumber'],
                          style: TextStyle(fontSize: 16 + 2),
                        ),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => selectedBusId = value),
                icon: Icons.directions_bus_outlined,
              ),
              const SizedBox(height: 30),
              _buildAllocateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFormField({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          hint,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16 + 2,
          ),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16 + 2),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.lightBlueAccent, size: 24),
          labelText: hint,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16 + 2,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        dropdownColor: Colors.blue.shade800.withOpacity(0.7),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildReadOnlyTextField(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: text,
        readOnly: true,
        style: const TextStyle(color: Colors.white, fontSize: 16 + 2),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.lightBlueAccent, size: 24),
          labelText: text,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16 + 2,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.lightBlueAccent,
              width: 2.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade800.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: ElevatedButton.icon(
            onPressed: allocateBus,
            icon: const Icon(Icons.save_alt, color: Colors.white),
            label: const Text(
              "Save/Update Assignment",
              style: TextStyle(
                fontSize: 16 + 2,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusAssignmentTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                allocations.isEmpty
                    ? const Center(
                      child: Text(
                        'No bus assignments available!',
                        style: TextStyle(
                          fontSize: 18 + 2,
                          color: Colors.white70,
                        ),
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) =>
                                  Colors.blue.shade800.withOpacity(0.6),
                            ),
                        dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) =>
                              Colors.white.withOpacity(0.05),
                        ),
                        columnSpacing: 25,
                        dataRowHeight: 60,
                        headingRowHeight: 70,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Student Name',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16 + 2,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Bus Number',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16 + 2,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'To',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16 + 2,
                              ),
                            ),
                          ),
                        ],
                        rows:
                            allocations.map<DataRow>((allocation) {
                              final student = allocation['studentId'];
                              final bus = allocation['busId'];

                              final studentName =
                                  student != null
                                      ? student['name'] ?? 'N/A'
                                      : 'N/A';
                              final busNumber =
                                  bus != null
                                      ? bus['busNumber'] ?? 'N/A'
                                      : 'N/A';
                              final to =
                                  bus != null ? bus['to'] ?? 'N/A' : 'N/A';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ), // Added padding to contain text
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(
                                          0.1,
                                        ), // Subtle background to highlight cell
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        studentName,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14 + 2,
                                        ),
                                        overflow:
                                            TextOverflow
                                                .ellipsis, // Handle long text
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        busNumber,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14 + 2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        to,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14 + 2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
