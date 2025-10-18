import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:logger/logger.dart';
import 'package:campus_bus_management/config/api_config.dart'; // ✅ Import centralized URL

class AllocateBusScreen extends StatefulWidget {
  const AllocateBusScreen({super.key});

  @override
  State<AllocateBusScreen> createState() => _AllocateBusScreenState();
}

class _AllocateBusScreenState extends State<AllocateBusScreen> {
  final logger = Logger();
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> buses = [];
  List<Map<String, dynamic>> allocations = [];
  List<String> toDestinations = [];
  List<String> departments = [];
  List<Map<String, dynamic>> filteredStudents = [];
  String? selectedStudentId;
  String studentName = '';
  String? selectedTo;
  String? selectedBusId;
  String? selectedSeatNumber;
  String? editingAllocationId;
  String? selectedDepartment;
  List<Map<String, dynamic>> filteredBuses = [];
  List<String> availableSeats = [];
  List<String> allocatedSeats = [];
  bool isLoadingStudents = true;
  bool isLoadingSeats = false;

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
        Uri.parse('${ApiConfig.baseUrl}/students'), // ✅ Updated URL
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
                'department': student['department'] ?? 'Unknown',
              },
            ),
          );
          departments =
              students
                  .map((student) => student['department'] as String)
                  .where((dept) => dept.isNotEmpty && dept != 'Unknown')
                  .toSet()
                  .toList();
          filteredStudents = students;
          isLoadingStudents = false;
        });
      } else {
        _showSnackBar('Failed to load students: ${response.statusCode}');
        setState(() => isLoadingStudents = false);
      }
    } catch (e) {
      _showSnackBar('Error fetching students: $e');
      setState(() => isLoadingStudents = false);
    }
  }

  Future<void> fetchBuses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/buses'), // ✅ Updated URL
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
                'capacity': bus['capacity'] ?? 0,
                'allocatedSeats': List<String>.from(
                  (bus['allocatedSeats'] ?? []).map((seat) => seat.toString()),
                ),
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
      _showSnackBar('Error fetching buses: $e');
    }
  }

  Future<void> fetchAllocations() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/allocations/allocations',
        ), // ✅ Updated URL
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
      _showSnackBar('Error fetching allocations: $e');
    }
  }

  Future<void> fetchAvailableSeats(String busId) async {
    try {
      setState(() => isLoadingSeats = true);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId'), // ✅ Updated URL
      );
      if (response.statusCode == 200) {
        final bus = json.decode(response.body);
        logger.d('Backend response for bus $busId: $bus');
        final capacity = bus['capacity'] as int;
        final allocated = List<String>.from(
          (bus['allocatedSeats'] ?? []).map((seat) => seat.toString()),
        );
        final allSeats = List.generate(capacity, (i) => (i + 1).toString());
        setState(() {
          allocatedSeats = allocated;
          availableSeats =
              allSeats.where((seat) => !allocated.contains(seat)).toList();
          if (availableSeats.isEmpty) {
            _showSnackBar('No seats available for this bus');
          }
          isLoadingSeats = false;
          logger.d(
            'Fetched seats for bus $busId: Allocated=$allocatedSeats, Available=$availableSeats',
          );
        });
        final busIndex = buses.indexWhere((b) => b['id'] == busId);
        if (busIndex != -1) {
          setState(() {
            buses[busIndex]['allocatedSeats'] = allocated;
          });
        }
        _updateAllocatedSeatsFromAllocations();
      } else {
        _showSnackBar('Failed to load bus details: ${response.statusCode}');
        setState(() => isLoadingSeats = false);
      }
    } catch (e) {
      _showSnackBar('Error fetching available seats: $e');
      setState(() => isLoadingSeats = false);
    }
  }

  void _updateAllocatedSeatsFromAllocations() {
    if (selectedBusId == null) return;
    final busAllocations =
        allocations
            .where((alloc) => alloc['busId']?['_id'] == selectedBusId)
            .map((alloc) => alloc['seatNumber']?.toString())
            .where((seat) => seat != null)
            .cast<String>()
            .toList();
    setState(() {
      allocatedSeats =
          [
            ...allocatedSeats,
            ...busAllocations.where((seat) => !allocatedSeats.contains(seat)),
          ].toSet().toList();
      final capacity =
          buses.firstWhere(
                (b) => b['id'] == selectedBusId,
                orElse: () => {'capacity': 0},
              )['capacity']
              as int;
      availableSeats =
          List.generate(
            capacity,
            (i) => (i + 1).toString(),
          ).where((seat) => !allocatedSeats.contains(seat)).toList();
      logger.d('Updated allocated seats from allocations: $allocatedSeats');
    });
  }

  Future<void> allocateBus() async {
    if (selectedDepartment != null &&
        selectedStudentId != null &&
        selectedBusId != null &&
        selectedTo != null &&
        selectedSeatNumber != null) {
      await fetchAvailableSeats(selectedBusId!);
      if (!availableSeats.contains(selectedSeatNumber)) {
        _showSnackBar('Selected seat is no longer available');
        return;
      }

      final existingAllocation = allocations.firstWhere(
        (alloc) =>
            alloc['studentId']?['_id'] == selectedStudentId &&
            alloc['busId']?['_id'] == selectedBusId &&
            alloc['_id'] != editingAllocationId,
        orElse: () => {},
      );
      if (existingAllocation.isNotEmpty) {
        _showSnackBar('This student already has a seat allocated in this bus');
        return;
      }

      try {
        final allocationData = {
          'studentId': selectedStudentId,
          'busId': selectedBusId,
          'to': selectedTo,
          'seatNumber': selectedSeatNumber,
        };
        http.Response response;
        String message;

        if (editingAllocationId == null) {
          response = await http.post(
            Uri.parse(
              '${ApiConfig.baseUrl}/allocations/allocate',
            ), // ✅ Updated URL
            headers: {'Content-Type': 'application/json'},
            body: json.encode(allocationData),
          );
          message = 'Bus and seat allocated successfully!';
        } else {
          response = await http.put(
            Uri.parse(
              '${ApiConfig.baseUrl}/allocations/$editingAllocationId',
            ), // ✅ Updated URL
            headers: {'Content-Type': 'application/json'},
            body: json.encode(allocationData),
          );
          message = 'Bus and seat allocation updated successfully!';
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          await fetchAllocations();
          await fetchBuses();
          await fetchAvailableSeats(selectedBusId!);
          _showSnackBar(message, isSuccess: true);
          _clearForm();
        } else {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Unknown error';
          _showSnackBar(
            'Failed to ${editingAllocationId == null ? 'allocate' : 'update'} bus: $errorMessage',
          );
        }
      } catch (e) {
        _showSnackBar(
          'Error ${editingAllocationId == null ? 'allocating' : 'updating'} bus: $e',
        );
      }
    } else {
      _showSnackBar(
        'Please select Department, Student, To, Bus, and Seat Number',
      );
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
          actions: [
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
                      '${ApiConfig.baseUrl}/allocations/$allocationId',
                    ), // ✅ Updated URL
                    headers: {'Content-Type': 'application/json'},
                  );
                  if (response.statusCode == 200) {
                    await fetchAllocations();
                    await fetchBuses();
                    if (selectedBusId != null) {
                      await fetchAvailableSeats(selectedBusId!);
                    }
                    _showSnackBar(
                      'Bus allocation deleted successfully!',
                      isSuccess: true,
                    );
                  } else {
                    final errorData = jsonDecode(response.body);
                    final errorMessage =
                        errorData['message'] ?? 'Unknown error';
                    _showSnackBar('Failed to delete allocation: $errorMessage');
                  }
                } catch (e) {
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
      selectedDepartment = allocation['studentId']?['department'] ?? '';
      selectedTo = allocation['to'] ?? allocation['busId']?['to'] ?? '';
      selectedBusId = allocation['busId']?['_id'] ?? '';
      selectedSeatNumber = allocation['seatNumber']?.toString() ?? '';
      filterBusesByTo(selectedTo);
      filterStudentsByDepartment(selectedDepartment);
      if (selectedBusId != null) {
        fetchAvailableSeats(selectedBusId!);
      }
    });
  }

  void filterBusesByTo(String? to) {
    setState(() {
      selectedTo = to;
      selectedBusId = null;
      selectedSeatNumber = null;
      availableSeats = [];
      allocatedSeats = [];
      if (to != null && to.isNotEmpty) {
        filteredBuses = buses.where((bus) => bus['to'] == to).toList();
      } else {
        filteredBuses = [];
      }
    });
  }

  void filterStudentsByDepartment(String? department) {
    setState(() {
      selectedDepartment = department;
      selectedStudentId = null;
      studentName = '';
      if (department != null && department.isNotEmpty) {
        filteredStudents =
            students
                .where((student) => student['department'] == department)
                .toList();
      } else {
        filteredStudents = students;
      }
    });
  }

  void _clearForm() {
    setState(() {
      selectedStudentId = null;
      studentName = '';
      selectedDepartment = null;
      selectedTo = null;
      selectedBusId = null;
      selectedSeatNumber = null;
      editingAllocationId = null;
      filteredBuses = [];
      filteredStudents = students;
      availableSeats = [];
      allocatedSeats = [];
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

  Future<void> _showSeatingDialog() async {
    if (selectedBusId == null) return;

    final bus = buses.firstWhere(
      (b) => b['id'] == selectedBusId,
      orElse: () => {'busNumber': 'Unknown', 'capacity': 0},
    );
    final busNumber = bus['busNumber'] as String;
    String? localSelectedSeat = selectedSeatNumber;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.9,
                      maxHeight: constraints.maxHeight * 0.7,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueGrey.shade300.withValues(
                                  alpha: 0.15,
                                ),
                                Colors.blueGrey.shade700.withValues(
                                  alpha: 0.15,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Select a Seat for Bus $busNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 3,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Flexible(
                                child: SingleChildScrollView(
                                  child:
                                      isLoadingSeats
                                          ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                          : availableSeats.isEmpty &&
                                              !isLoadingSeats
                                          ? const Center(
                                            child: Text(
                                              'No seats available for this bus',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16,
                                              ),
                                            ),
                                          )
                                          : _buildSeatingTable(
                                            localSelectedSeat:
                                                localSelectedSeat,
                                            onSeatSelected: (seat) {
                                              setDialogState(() {
                                                localSelectedSeat = seat;
                                              });
                                            },
                                          ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(dialogContext).pop(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade600
                                            .withValues(alpha: 0.5),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 15,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          side: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          localSelectedSeat != null
                                              ? () {
                                                setState(() {
                                                  selectedSeatNumber =
                                                      localSelectedSeat;
                                                });
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop();
                                              }
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600
                                            .withValues(alpha: 0.5),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 15,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          side: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Confirm',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
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
                    value: selectedDepartment,
                    hint: 'Select Department',
                    items:
                        departments.map<DropdownMenuItem<String>>((dept) {
                          return DropdownMenuItem<String>(
                            value: dept,
                            child: Text(
                              dept,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                    onChanged: filterStudentsByDepartment,
                    icon: Icons.school_outlined,
                  ),
              const SizedBox(height: 20),
              _buildDropdownFormField(
                value: selectedStudentId,
                hint: 'Select Enrollment Number',
                items:
                    filteredStudents.map<DropdownMenuItem<String>>((student) {
                      return DropdownMenuItem<String>(
                        value: student['id'] as String,
                        child: Text(
                          student['envNumber'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStudentId = value;
                    final selectedStudent = filteredStudents.firstWhere(
                      (s) => s['id'] == value,
                      orElse: () => {'name': 'Unknown'},
                    );
                    studentName = selectedStudent['name'] as String;
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
                onChanged: (value) async {
                  setState(() {
                    selectedBusId = value;
                    selectedSeatNumber = null;
                    if (value != null) {
                      availableSeats = [];
                      allocatedSeats = [];
                    }
                  });
                  if (value != null) {
                    await fetchAvailableSeats(value);
                    if (mounted) {
                      await _showSeatingDialog();
                    }
                  }
                },
                icon: Icons.directions_bus_outlined,
              ),
              const SizedBox(height: 20),
              _buildReadOnlyTextField(
                selectedSeatNumber?.isEmpty ?? true
                    ? 'No Seat Selected'
                    : 'Seat $selectedSeatNumber Selected',
                Icons.event_seat,
                onTap: () async {
                  if (selectedBusId == null) {
                    _showSnackBar('Please select a bus first');
                    return;
                  }
                  await fetchAvailableSeats(selectedBusId!);
                  if (mounted) {
                    await _showSeatingDialog();
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.blue, 'Available'),
                  const SizedBox(width: 10),
                  _buildLegendItem(Colors.redAccent, 'Allocated'),
                  const SizedBox(width: 10),
                  _buildLegendItem(Colors.green, 'Selected'),
                ],
              ),
              const SizedBox(height: 30),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatingTable({
    required String? localSelectedSeat,
    required Function(String?) onSeatSelected,
  }) {
    if (selectedBusId == null) {
      return const Text(
        'Please select a bus to view seating arrangement',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      );
    }

    final bus = buses.firstWhere(
      (b) => b['id'] == selectedBusId,
      orElse: () => {'capacity': 0, 'allocatedSeats': []},
    );
    final capacity = bus['capacity'] as int;
    if (capacity == 0) {
      return const Text(
        'Invalid bus capacity',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      );
    }

    const columns = 5; // 2 seats + aisle + 2 seats
    final seatsPerRow = 4; // 2 seats left + 2 seats right
    final rows = (capacity / seatsPerRow).ceil();
    final seatNumbers = List.generate(capacity, (i) => (i + 1).toString());

    logger.d(
      'Building seating table for bus $selectedBusId: Allocated seats=$allocatedSeats',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select a Seat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: rows * columns,
          itemBuilder: (context, index) {
            final row = index ~/ columns;
            final col = index % columns;

            if (col == 2) {
              return Center(
                child: Text(
                  'Aisle',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              );
            }

            final seatCol = col < 2 ? col : col - 1;
            final seatIndex = (row * seatsPerRow) + seatCol;

            if (seatIndex >= capacity) {
              return const SizedBox();
            }

            final seatNumber = seatNumbers[seatIndex];
            final isAllocated = allocatedSeats.contains(seatNumber);
            final isSelected = localSelectedSeat == seatNumber;

            logger.d(
              'Seat $seatNumber: isAllocated=$isAllocated, isSelected=$isSelected',
            );

            return GestureDetector(
              onTap:
                  isAllocated
                      ? null
                      : () {
                        onSeatSelected(seatNumber);
                        logger.d('Selected seat: $seatNumber');
                      },
              child: Tooltip(
                message: isAllocated ? 'Seat Allocated' : 'Seat Available',
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isAllocated
                            ? Colors.redAccent.withValues(alpha: 0.9)
                            : isSelected
                            ? Colors.green.withValues(alpha: 0.9)
                            : Colors.blue.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isSelected
                              ? Colors.yellowAccent
                              : Colors.white.withValues(alpha: 0.4),
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      seatNumber,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
        onChanged: items.isNotEmpty ? onChanged : null,
      ),
    );
  }

  Widget _buildReadOnlyTextField(
    String text,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: TextEditingController(text: text),
        readOnly: true,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.lightBlueAccent, size: 24),
          labelText: icon == Icons.person ? 'Student Name' : 'Selected Seat',
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
                              'Seat Number',
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
                              final seatNumber =
                                  allocation['seatNumber']?.toString() ?? 'N/A';
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
                                        seatNumber,
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
