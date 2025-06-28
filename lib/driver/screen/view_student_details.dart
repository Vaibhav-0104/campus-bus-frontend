import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // Required for ImageFilter for blur effects

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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDriverId();
    _searchController.addListener(() {
      _filterStudents(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeDriverId() async {
    if (widget.driverId == null || widget.driverId!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _driverId = prefs.getString('driverIdr') ?? '';
    } else {
      _driverId = widget.driverId;
    }

    print('Driver ID: $_driverId');

    if (_driverId == null || _driverId!.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid driver ID. Please log in again.';
        _isLoading = false;
      });
      // Consider navigating to login or showing a persistent message
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   Navigator.pushReplacementNamed(context, '/login');
      // });
      return;
    }
    _fetchStudentAllocations();
  }

  Future<void> _fetchStudentAllocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _students = []; // Clear previous data
      _filteredStudents = []; // Clear previous data
    });

    try {
      final url =
          'http://172.20.10.9:5000/api/allocations/allocations/driver/$_driverId';
      print('Request URL: $url');
      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> allocations = json.decode(response.body);

        setState(() {
          if (allocations.isEmpty) {
            _errorMessage =
                'No students assigned to your bus. Contact the admin to assign students.';
            _busNumber = 'N/A'; // Reset bus number if no allocations
          } else {
            _students =
                allocations.map((allocation) {
                  final student = allocation['studentId'] ?? {};
                  final bus = allocation['busId'] ?? {};
                  _busNumber =
                      bus['busNumber'] ??
                      'N/A'; // Update bus number from the first allocation
                  return {
                    'id': student['envNumber'] ?? 'N/A',
                    'name': student['name'] ?? 'Unknown',
                    'email': student['email'] ?? 'N/A',
                  };
                }).toList();
            _filteredStudents = List.from(
              _students,
            ); // Initially show all students
          }
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
        _errorMessage =
            'Error fetching student data: $error. Please check your network connection.';
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
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   Navigator.pushReplacementNamed(context, '/login'); // Uncomment if you want to force re-login
      // });
      return;
    }
    await _fetchStudentAllocations();
  }

  // Helper method to build a liquid glass card for consistent styling
  Widget _buildLiquidGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        25,
      ), // Rounded corners for liquid glass card
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20.0,
          sigmaY: 20.0,
        ), // Stronger blur for the card
        child: Container(
          padding:
              padding ??
              const EdgeInsets.all(
                25,
              ), // Increased padding inside the card, made optional
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(
                  0.1,
                ), // More transparent white for lighter glass
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ), // Thinner border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3), // Stronger shadow
                blurRadius: 30, // Increased blur
                spreadRadius: 5, // Increased spread
                offset: const Offset(10, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.15), // Inner light glow
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
      extendBodyBehindAppBar:
          true, // Extend body behind app bar for full gradient
      appBar: AppBar(
        title: Text(
          'Students on Bus $_busNumber',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(
          0.4,
        ), // Liquid glass app bar
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // White back button
        elevation: 0, // Remove default shadow
        centerTitle: true,
        flexibleSpace: ClipRect(
          // Clip to make the blur effect contained within the AppBar area
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ), // Blur effect for app bar
            child: Container(
              color:
                  Colors
                      .transparent, // Transparent to show blurred content behind
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ), // White refresh icon
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
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
            ], // Deep Purple themed gradient background
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top:
                AppBar().preferredSize.height +
                MediaQuery.of(context).padding.top +
                16,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
          ),
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : _errorMessage.isNotEmpty
                          ? Center(
                            child: _buildLiquidGlassCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.redAccent.shade100,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors
                                          .deepPurple
                                          .shade400
                                          .withOpacity(0.6),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : _filteredStudents.isNotEmpty
                          ? ListView.builder(
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildStudentCard(student),
                              );
                            },
                          )
                          : Center(
                            child: _buildLiquidGlassCard(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                _searchController.text.isEmpty
                                    ? 'No students assigned to your bus. Contact the admin to assign students.'
                                    : 'No students found matching "${_searchController.text}".',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return _buildLiquidGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          hintText: 'Search by Name or ID...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 18,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.8),
            size: 28,
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
                      _filterStudents('');
                    },
                  )
                  : null,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return _buildLiquidGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple.shade400,
            radius: 30,
            child: Text(
              student['name'][0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      student['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.perm_identity, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ID: ${student['id'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      // Use Flexible to prevent overflow for long emails
                      child: Text(
                        'Email: ${student['email'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                        overflow:
                            TextOverflow.ellipsis, // Add ellipsis for overflow
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Optionally, add an arrow or other indicator if cards are tappable
          // Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 20),
        ],
      ),
    );
  }
}
