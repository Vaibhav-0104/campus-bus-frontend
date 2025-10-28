import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/config/api_config.dart';
import 'package:campus_bus_management/admin/screen/live_driver_location.dart';

class ShowDriversScreen extends StatefulWidget {
  const ShowDriversScreen({super.key});

  @override
  State<ShowDriversScreen> createState() => _ShowDriversScreenState();
}

class _ShowDriversScreenState extends State<ShowDriversScreen> {
  Future<List<Driver>>? _driversFuture;

  @override
  void initState() {
    super.initState();
    _driversFuture = fetchDrivers();
  }

  Future<List<Driver>> fetchDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/drivers'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> driversJson = jsonDecode(response.body);
        return driversJson.map((json) => Driver.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load drivers. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching drivers: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Drivers Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade900.withOpacity(0.8),
                Colors.blue.shade700.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Driver>>(
            future: _driversFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      snapshot.error.toString().contains('Failed to load')
                          ? 'Failed to connect to server.'
                          : 'An unexpected error occurred.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No drivers found.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              final drivers = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(15.0),
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  return DriverDetailCard(driver: drivers[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class Driver {
  final String id;
  final String name;
  final String contact;
  final String license;
  final String email;
  final String status;

  Driver({
    required this.id,
    required this.name,
    required this.contact,
    required this.license,
    required this.email,
    required this.status,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id'] as String,
      name: json['name'] as String,
      contact: json['contact'] as String,
      license: json['license'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
    );
  }

  // --- MODIFIED METHOD ---
  Future<DriverLocationData> fetchLocationData() async {
    try {
      final response = await http.get(
        // Assuming the API path is correct, but handling 404 gracefully.
        Uri.parse('${ApiConfig.baseUrl}/driver-locations/status?driverId=$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DriverLocationData.fromJson(data);
      } else if (response.statusCode == 404) {
        // Handle 404 by returning default location data (not sharing/offline).
        print(
          'Location data not found (404) for driver $id. Returning default offline status.',
        );
        return DriverLocationData(
          shareStatus: false,
          address: 'Location data unavailable or driver is offline.',
        );
      } else {
        // Throw exception for other status codes (e.g., 500)
        throw Exception('Failed to load location: ${response.statusCode}');
      }
    } catch (e) {
      // Catch network errors, format issues, etc., and return default location data.
      print('Error fetching location for driver $id: $e');
      return DriverLocationData(
        shareStatus: false,
        address: 'Network or server error occurred.',
      );
    }
  }
}

class DriverLocationData {
  final bool shareStatus;
  final double? latitude;
  final double? longitude;
  final String address;

  DriverLocationData({
    required this.shareStatus,
    this.latitude,
    this.longitude,
    required this.address,
  });

  factory DriverLocationData.fromJson(Map<String, dynamic> json) {
    // Note: The original code casts latitude and longitude to double,
    // which may throw if the API returns int. A safer conversion is used here.
    return DriverLocationData(
      shareStatus: json['shareStatus'] ?? false,
      latitude:
          json['latitude'] != null
              ? (json['latitude'] as num).toDouble()
              : null,
      longitude:
          json['longitude'] != null
              ? (json['longitude'] as num).toDouble()
              : null,
      address: json['address'] as String? ?? '',
    );
  }
}

class DriverDetailCard extends StatelessWidget {
  final Driver driver;

  const DriverDetailCard({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        driver.status == 'Active' ? Colors.green.shade400 : Colors.red.shade400;

    return Card(
      elevation: 10,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    driver.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    driver.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1, color: Colors.grey),
            _buildDetailRow(Icons.email, 'Email:', driver.email),
            _buildDetailRow(Icons.phone, 'Contact:', driver.contact),
            _buildDetailRow(Icons.badge, 'License:', driver.license),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () async {
                final locationData = await driver.fetchLocationData();
                // Check if the context is still valid before performing navigation
                if (!context.mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => LiveDriverLocationPage(
                          driverId: driver.id,
                          initialLocationData: locationData,
                        ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'View Driver Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade100,
            ),
            child: Icon(icon, size: 22, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
