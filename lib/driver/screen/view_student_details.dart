import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:campus_bus_management/config/api_config.dart';

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

    if (_driverId == null || _driverId!.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid driver ID. Please log in again.';
        _isLoading = false;
      });
      return;
    }
    _fetchStudentAllocations();
  }

  Future<void> _fetchStudentAllocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _students = [];
      _filteredStudents = [];
    });

    try {
      final url =
          '${ApiConfig.baseUrl}/allocations/allocations/driver/$_driverId';
      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> allocations = json.decode(response.body);

        setState(() {
          if (allocations.isEmpty) {
            _errorMessage =
                'No students assigned to your bus. Contact the admin to assign students.';
            _busNumber = 'N/A';
          } else {
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
      return;
    }
    await _fetchStudentAllocations();
  }

  // Reusable Glass Card (Same as Dashboard)
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
        title: Text(
          'Students on Bus $_busNumber',
          style: const TextStyle(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amber),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.amber,
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.amber,
                              ),
                            )
                            : _errorMessage.isNotEmpty
                            ? _buildErrorCard()
                            : _filteredStudents.isNotEmpty
                            ? ListView.builder(
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildStudentCard(student),
                                );
                              },
                            )
                            : _buildEmptyCard(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return _glassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          hintText: 'Search by Name or ID...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 18,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.amber, size: 28),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
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

  Widget _buildErrorCard() {
    return Center(
      child: _glassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, color: Colors.black87),
              label: const Text(
                "Retry",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 10,
                shadowColor: Colors.black.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Center(
      child: _glassCard(
        padding: const EdgeInsets.all(24),
        child: Text(
          _searchController.text.isEmpty
              ? 'No students assigned to your bus. Contact the admin to assign students.'
              : 'No students found matching "${_searchController.text}".',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return _glassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.amber.shade700,
            child: Text(
              student['name'][0].toUpperCase(),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.amber, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      student['name'] ?? 'Unknown',
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
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.perm_identity,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: ${student['id'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.email, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Email: ${student['email'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
