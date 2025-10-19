import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/config/api_config.dart'; // Import your API config

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
        Uri.parse('${ApiConfig.baseUrl}/drivers'), // Use the /drivers endpoint
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
      appBar: AppBar(
        title: const Text('All Drivers Details'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade700],
          ),
        ),
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
                    'Error: ${snapshot.error.toString().contains('Failed to load') ? 'Failed to connect to server or load data.' : 'An unexpected error occurred.'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No drivers found.',
                  style: TextStyle(color: Colors.white70, fontSize: 20),
                ),
              );
            }

            final drivers = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                return DriverDetailCard(driver: drivers[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

// Data Model
class Driver {
  final String id;
  final String name;
  final String contact;
  final String license;
  final String email;
  final String password; // Note: In a real app, never send password to client!
  final String status;
  final String? licenseDocument;

  Driver({
    required this.id,
    required this.name,
    required this.contact,
    required this.license,
    required this.email,
    required this.password,
    required this.status,
    this.licenseDocument,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id'] as String,
      name: json['name'] as String,
      contact: json['contact'] as String,
      license: json['license'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      status: json['status'] as String,
      licenseDocument: json['licenseDocument'] as String?,
    );
  }
}

// UI Card Component
class DriverDetailCard extends StatelessWidget {
  final Driver driver;

  const DriverDetailCard({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    // Determine status color
    final statusColor =
        driver.status == 'Active' ? Colors.greenAccent : Colors.redAccent;

    // Determine if license document path exists and use a placeholder image URL for the demonstration
    final isDocumentAvailable =
        driver.licenseDocument != null && driver.licenseDocument!.isNotEmpty;
    // Replace the following with your actual document URL if you decide to display the document
    const String dummyDocumentPlaceholderUrl =
        'https://picsum.photos/400/200?random=1';

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.95), // Slightly transparent white card
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Name & Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    driver.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
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
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    driver.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1.5, color: Colors.black12),

            // Driver Details
            _buildDetailRow(Icons.email, 'Email:', driver.email),
            _buildDetailRow(Icons.phone, 'Contact:', driver.contact),
            _buildDetailRow(Icons.badge, 'License No:', driver.license),

            const SizedBox(height: 15),

            // License Document/Screenshot (using a placeholder for now)
            Text(
              'License Document:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade100,
              ),
              child:
                  isDocumentAvailable
                      ? Center(
                        child: Text(
                          'Document Path: ${driver.licenseDocument}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.description,
                              size: 40,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'No Document Uploaded',
                              style: TextStyle(color: Colors.grey.shade600),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.blue.shade600),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// This is where the file path image is referred to
// ```
