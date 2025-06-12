import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    final response = await http.get(
      Uri.parse('https://campus-bus-backend.onrender.com:5000/api/students'),
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
    }
  }

  Future<void> fetchBuses() async {
    final response = await http.get(
      Uri.parse('https://campus-bus-backend.onrender.com/api/buses'),
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
    }
  }

  Future<void> fetchAllocations() async {
    final response = await http.get(
      Uri.parse(
        'https://campus-bus-backend.onrender.com/api/allocations/allocations',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        allocations = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> allocateBus() async {
    if (selectedStudentId != null &&
        selectedBusId != null &&
        selectedTo != null) {
      final response = await http.post(
        Uri.parse(
          'https://campus-bus-backend.onrender.com/api/allocations/allocate',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'studentId': selectedStudentId,
          'busId': selectedBusId,
          'to': selectedTo,
        }),
      );

      if (response.statusCode == 200) {
        fetchAllocations();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus allocated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to allocate bus')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Student, To, and Bus')),
      );
    }
  }

  void filterBusesByTo(String? to) {
    setState(() {
      selectedTo = to;
      selectedBusId = null; // Reset bus selection when 'to' changes
      if (to != null && to.isNotEmpty) {
        filteredBuses = buses.where((bus) => bus['to'] == to).toList();
      } else {
        filteredBuses = buses;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 237, 238),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(103, 58, 183, 1),
        title: const Text(
          'Allocate Bus to Student Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormCard(),
            const SizedBox(height: 30),
            _buildBusAssignmentTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: _inputDecoration("Select Enrollment Number"),
              value: selectedStudentId,
              items:
                  students.map<DropdownMenuItem<String>>((student) {
                    return DropdownMenuItem<String>(
                      value: student['id'] as String,
                      child: Text("${student['envNumber']}"),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStudentId = value;
                  studentName =
                      students.firstWhere((s) => s['id'] == value)['name'];
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              readOnly: true,
              decoration: _inputDecoration(
                studentName.isEmpty ? "Student Name" : studentName,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration("Select To Destination"),
              value: selectedTo,
              items:
                  toDestinations.map<DropdownMenuItem<String>>((to) {
                    return DropdownMenuItem<String>(value: to, child: Text(to));
                  }).toList(),
              onChanged: filterBusesByTo,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration("Select Bus"),
              value: selectedBusId,
              items:
                  filteredBuses.map<DropdownMenuItem<String>>((bus) {
                    return DropdownMenuItem<String>(
                      value: bus['id'] as String,
                      child: Text(bus['busNumber']),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => selectedBusId = value),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(180, 50),
                ),
                onPressed: allocateBus,
                icon: const Icon(Icons.save_alt, color: Colors.white),
                label: const Text(
                  "Save/Update Assignment",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildBusAssignmentTable() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Student Name')),
            DataColumn(label: Text('Bus Number')),
            DataColumn(label: Text('To')),
          ],
          rows:
              allocations.map<DataRow>((allocation) {
                final student = allocation['studentId'];
                final bus = allocation['busId'];

                final studentName =
                    student != null ? student['name'] ?? '' : 'N/A';
                final busNumber = bus != null ? bus['busNumber'] ?? '' : 'N/A';
                final to = bus != null ? bus['to'] ?? '' : 'N/A';

                return DataRow(
                  cells: [
                    DataCell(Text(studentName)),
                    DataCell(Text(busNumber)),
                    DataCell(Text(to)),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}
