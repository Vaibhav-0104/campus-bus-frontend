import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ViewStudentDetailsScreen extends StatefulWidget {
  final String? driverId;

  const ViewStudentDetailsScreen({super.key, this.driverId});

  @override
  State<ViewStudentDetailsScreen> createState() =>
      _ViewStudentDetailsScreenState();
}

class _ViewStudentDetailsScreenState extends State<ViewStudentDetailsScreen> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _busNumber = 'N/A';
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _initializeDriverId();
  }

  Future<void> _initializeDriverId() async {
    if (widget.driverId == null || widget.driverId!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _driverId = prefs.getString('driverId') ?? '';
    } else {
      _driverId = widget.driverId;
    }

    print('Driver ID: $_driverId');

    if (_driverId == null || _driverId!.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid driver ID. Please log in again.';
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }
    _fetchStudentAllocations();
  }

  Future<void> _fetchStudentAllocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url =
          'https://campus-bus-backend.onrender.com/api/allocations/allocations/driver/$_driverId';
      print('Request URL: $url');
      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> allocations = json.decode(response.body);

        if (allocations.isEmpty) {
          setState(() {
            _errorMessage =
                'No students assigned to your bus. Contact the admin to assign students.';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _students =
              allocations.map((allocation) {
                final student = allocation['studentId'] ?? {};
                final bus = allocation['busId'] ?? {};
                _busNumber = bus['busNumber'] ?? 'N/A';
                return {
                  'id': student['envNumber'] ?? 'N/A',
                  'name': student['name'] ?? 'Unknown',
                  'email': student['email'] ?? 'N/A',
                };
              }).toList();
          _filteredStudents = List.from(_students);
          _isLoading = false;
        });
      } else {
        String errorMessage;
        switch (response.statusCode) {
          case 404:
            errorMessage =
                'No active bus assigned to you. Please contact the admin to assign a bus.';
            break;
          case 400:
            errorMessage = 'Invalid request. Please check your driver ID.';
            break;
          default:
            errorMessage =
                'Failed to load students (Status: ${response.statusCode})';
            try {
              final errorJson = json.decode(response.body);
              errorMessage = errorJson['message'] ?? errorMessage;
            } catch (_) {
              if (response.body.startsWith('<!DOCTYPE html>')) {
                errorMessage =
                    'Invalid server response. Please check the server configuration.';
              }
            }
        }
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error fetching student data: $error';
        _isLoading = false;
      });
      print('Error details: $error');
    }
  }

  void _filterStudents(String query) {
    final filtered =
        _students.where((student) {
          final nameLower = student['name'].toLowerCase();
          final idLower = student['id'].toLowerCase();
          final searchLower = query.toLowerCase();
          return nameLower.contains(searchLower) ||
              idLower.contains(searchLower);
        }).toList();

    setState(() {
      _filteredStudents = filtered;
    });
  }

  Future<void> _refreshData() async {
    if (_driverId == null || _driverId!.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid driver ID. Please log in again.';
      });
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    await _fetchStudentAllocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Students on Bus $_busNumber',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child:
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _errorMessage.isNotEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _errorMessage,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshData,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                            : _filteredStudents.isNotEmpty
                            ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  columnSpacing: 16,
                                  columns: const [
                                    DataColumn(label: Text('Student ID')),
                                    DataColumn(label: Text('Name')),
                                    DataColumn(label: Text('Email')),
                                  ],
                                  rows:
                                      _filteredStudents.map((student) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(student['id'])),
                                            DataCell(Text(student['name'])),
                                            DataCell(Text(student['email'])),
                                          ],
                                        );
                                      }).toList(),
                                ),
                              ),
                            )
                            : const Center(
                              child: Text(
                                'No students assigned to your bus. Contact the admin to assign students.',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: _filterStudents,
      decoration: InputDecoration(
        hintText: 'Search by Name or ID...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
