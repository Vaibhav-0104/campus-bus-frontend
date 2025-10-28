import 'package:flutter/material.dart';
import 'dart:ui'; // <-- ADDED FOR ImageFilter
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

  // ────── NEW COLORS (Same as other screens) ──────
  final Color bgStart = const Color(0xFF0A0E1A);
  final Color bgMid = const Color(0xFF0F172A);
  final Color bgEnd = const Color(0xFF1E293B);
  final Color glassBg = Colors.white.withAlpha(0x14);
  final Color glassBorder = Colors.white.withAlpha(0x26);
  final Color textSecondary = Colors.white70;
  final Color busYellow = const Color(0xFFFBBF24);

  @override
  void initState() {
    super.initState();
    _driversFuture = fetchDrivers();
  }

  // ────── API LOGIC UNCHANGED ──────
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus, color: busYellow, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Drivers Details',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.white.withAlpha(0x0D)),
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
            colors: [bgStart, bgMid, bgEnd],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Driver>>(
            future: _driversFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: busYellow),
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
                  return DriverDetailCard(
                    driver: drivers[index],
                    busYellow: busYellow, // <-- PASSED HERE
                    glassBg: glassBg,
                    glassBorder: glassBorder,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ────── MODELS UNCHANGED ──────
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

  Future<DriverLocationData> fetchLocationData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/driver-locations/status?driverId=$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DriverLocationData.fromJson(data);
      } else if (response.statusCode == 404) {
        print(
          'Location data not found (404) for driver $id. Returning default offline status.',
        );
        return DriverLocationData(
          shareStatus: false,
          address: 'Location data unavailable or driver is offline.',
        );
      } else {
        throw Exception('Failed to load location: ${response.statusCode}');
      }
    } catch (e) {
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

// ────── UI CARD (Fixed + Color Updated) ──────
class DriverDetailCard extends StatelessWidget {
  final Driver driver;
  final Color busYellow;
  final Color glassBg;
  final Color glassBorder;

  const DriverDetailCard({
    super.key,
    required this.driver,
    required this.busYellow,
    required this.glassBg,
    required this.glassBorder,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        driver.status == 'Active' ? Colors.greenAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: glassBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        driver.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
                const Divider(height: 20, thickness: 1, color: Colors.white24),
                _buildDetailRow(Icons.email, 'Email:', driver.email),
                _buildDetailRow(Icons.phone, 'Contact:', driver.contact),
                _buildDetailRow(Icons.badge, 'License:', driver.license),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () async {
                    final locationData = await driver.fetchLocationData();
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
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: busYellow,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.black87,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'View Driver Location',
                          style: TextStyle(
                            color: Colors.black87,
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
              color: busYellow.withOpacity(0.2),
            ),
            child: Icon(icon, size: 22, color: busYellow),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
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
