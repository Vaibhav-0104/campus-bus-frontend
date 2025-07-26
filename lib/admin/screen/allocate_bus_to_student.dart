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
  String? editingAllocationId; // Track the allocation being edited
  List<Map<String, dynamic>> filteredBuses = [];
  bool isLoadingStudents = true; // Track student loading state

  @override
  void initState() {
    super.initState();
    fetchStudents();
    fetchBuses();
    fetchAllocations();
  }

  Future<void> fetchStudents() async {
    try {
      setState(() => isLoadingStudents = true);
      final response = await http.get(
        Uri.parse('http://192.168.31.104:5000/api/students'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          students = List<Map<String, dynamic>>.from(
            data.map(
              (student) => {
                'id': student['_id'],
                'envNumber': student['envNumber'],
                'name': student['name'] ?? 'Unknown',
              },
            ),
          );
          isLoadingStudents = false;
        });
      } else {
        _showSnackBar('Failed to load students: ${response.statusCode}');
        setState(() => isLoadingStudents = false);
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      _showSnackBar('Error fetching students: $e');
      setState(() => isLoadingStudents = false);
    }
  }

  Future<void> fetchBuses() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.31.104:5000/api/buses'),
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
        Uri.parse('http://192.168.31.104:5000/api/allocations/allocations'),
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
        final allocationData = {
          'studentId': selectedStudentId,
          'busId': selectedBusId,
          'to': selectedTo,
        };
        http.Response response;
        String message;

        if (editingAllocationId == null) {
          response = await http.post(
            Uri.parse('http://192.168.31.104:5000/api/allocations/allocate'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(allocationData),
          );
          message = 'Bus allocated successfully!';
        } else {
          response = await http.put(
            Uri.parse(
              'http://192.168.31.104:5000/api/allocations/$editingAllocationId',
            ),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(allocationData),
          );
          message = 'Bus allocation updated successfully!';
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          await fetchAllocations();
          _showSnackBar(message, isSuccess: true);
          _clearForm();
        } else {
          _showSnackBar(
            'Failed to ${editingAllocationId == null ? 'allocate' : 'update'} bus: ${response.statusCode}. ${jsonDecode(response.body)['message'] ?? ''}',
          );
        }
      } catch (e) {
        debugPrint(
          'Error ${editingAllocationId == null ? 'allocating' : 'updating'} bus: $e',
        );
        _showSnackBar(
          'Error ${editingAllocationId == null ? 'allocating' : 'updating'} bus: $e',
        );
      }
    } else {
      _showSnackBar('Please select Student, To, and Bus');
    }
  }

  Future<void> deleteAllocation(String allocationId) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.blue.shade800.withValues(alpha: 0.8),
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this bus allocation?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final response = await http.delete(
                    Uri.parse(
                      'http://192.168.31.104:5000/api/allocations/$allocationId',
                    ),
                    headers: {'Content-Type': 'application/json'},
                  );
                  if (response.statusCode == 200) {
                    await fetchAllocations();
                    _showSnackBar(
                      'Bus allocation deleted successfully!',
                      isSuccess: true,
                    );
                  } else {
                    _showSnackBar(
                      'Failed to delete allocation: ${response.statusCode}. ${jsonDecode(response.body)['message'] ?? ''}',
                    );
                  }
                } catch (e) {
                  debugPrint('Error deleting allocation: $e');
                  _showSnackBar('Error deleting allocation: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void editAllocation(Map<String, dynamic> allocation) {
    setState(() {
      editingAllocationId = allocation['_id'];
      selectedStudentId = allocation['studentId']?['_id'] ?? '';
      studentName = allocation['studentId']?['name'] ?? 'N/A';
      selectedTo = allocation['to'] ?? allocation['busId']?['to'] ?? '';
      selectedBusId = allocation['busId']?['_id'] ?? '';
      filterBusesByTo(selectedTo);
    });
  }

  void filterBusesByTo(String? to) {
    setState(() {
      selectedTo = to;
      selectedBusId = null;
      if (to != null && to.isNotEmpty) {
        filteredBuses = buses.where((bus) => bus['to'] == to).toList();
      } else {
        filteredBuses = [];
      }
    });
  }

  void _clearForm() {
    setState(() {
      selectedStudentId = null;
      studentName = '';
      selectedTo = null;
      selectedBusId = null;
      editingAllocationId = null;
      filteredBuses = [];
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
        backgroundColor: Colors.blue.shade800.withValues(alpha: 0.3),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Colors.blueGrey.shade300.withValues(alpha: 0.15),
                Colors.blueGrey.shade700.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(10, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(-8, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                editingAllocationId == null
                    ? 'Allocate Bus to Student'
                    : 'Update Bus Allocation',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 30),
              isLoadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDropdownFormField(
                    value: selectedStudentId,
                    hint: 'Select Enrollment Number',
                    items:
                        students.map<DropdownMenuItem<String>>((student) {
                          return DropdownMenuItem<String>(
                            value: student['id'] as String,
                            child: Text(
                              '${student['envNumber']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStudentId = value;
                        final selectedStudent = students.firstWhere(
                          (s) => s['id'] == value,
                          orElse: () => {'name': 'Unknown'},
                        );
                        studentName = selectedStudent['name'] as String;
                        debugPrint(
                          'Selected student ID: $value, Name: $studentName',
                        );
                      });
                    },
                    icon: Icons.person_outline,
                  ),
              const SizedBox(height: 20),
              _buildReadOnlyTextField(
                studentName.isEmpty ? 'Student Name' : studentName,
                Icons.person,
              ),
              const SizedBox(height: 20),
              _buildDropdownFormField(
                value: selectedTo,
                hint: 'Select To Destination',
                items:
                    toDestinations.map<DropdownMenuItem<String>>((to) {
                      return DropdownMenuItem<String>(
                        value: to,
                        child: Text(to, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                onChanged: filterBusesByTo,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 20),
              _buildDropdownFormField(
                value: selectedBusId,
                hint: 'Select Bus',
                items:
                    filteredBuses.map<DropdownMenuItem<String>>((bus) {
                      return DropdownMenuItem<String>(
                        value: bus['id'] as String,
                        child: Text(
                          bus['busNumber'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => selectedBusId = value),
                icon: Icons.directions_bus_outlined,
              ),
              const SizedBox(height: 30),
              _buildActionButtons(),
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
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          hint,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.lightBlueAccent, size: 24),
          labelText: hint,
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        dropdownColor: Colors.blue.shade800.withValues(alpha: 0.7),
        items: items,
        onChanged: items.isNotEmpty ? onChanged : null, // Disable if no items
      ),
    );
  }

  Widget _buildReadOnlyTextField(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: TextEditingController(
          text: text,
        ), // Use controller for dynamic updates
        readOnly: true,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.lightBlueAccent, size: 24),
          labelText: 'Student Name',
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade800.withValues(alpha: 0.4),
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
                    label: Text(
                      editingAllocationId == null
                          ? 'Save Allocation'
                          : 'Update Allocation',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600.withValues(
                        alpha: 0.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade800.withValues(alpha: 0.4),
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
                    onPressed: _clearForm,
                    icon: const Icon(Icons.clear, color: Colors.white),
                    label: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600.withValues(
                        alpha: 0.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                Colors.blueGrey.shade300.withValues(alpha: 0.15),
                Colors.blueGrey.shade700.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(10, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
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
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) =>
                                  Colors.blue.shade800.withValues(alpha: 0.6),
                            ),
                        dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) =>
                              Colors.white.withValues(alpha: 0.05),
                        ),
                        columnSpacing: 25,
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        headingRowHeight: 70,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Student Name',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Bus Number',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'To',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                                  allocation['to'] ?? bus?['to'] ?? 'N/A';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        studentName,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
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
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        busNumber,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
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
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        to,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.lightBlueAccent,
                                          ),
                                          onPressed:
                                              () => editAllocation(allocation),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed:
                                              () => deleteAllocation(
                                                allocation['_id'],
                                              ),
                                        ),
                                      ],
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
