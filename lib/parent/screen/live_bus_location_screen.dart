import 'dart:async';
import 'package:campus_bus_management/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

// New AppTheme class provided in the prompt
class AppTheme {
  static const Color primaryColor = Color(0xFF1E88E5); // Bright Blue
  static const Color backgroundColor = Color(0xFF0C1337); // Very Dark Blue
  static const Color accentColor = Color(0xFF80D8FF); // Light Cyan/Blue Accent
  static const Color cardBackground = Color(
    0xFF16204C,
  ); // Darker Blue for cards

  static const Color iconColor1 = Color(0xFF69F0AE); // Green for active status
  static const Color iconColor2 = Color(0xFFFFC107); // Amber
  static const Color iconColor3 = Color(0xFFFF5252); // Red
}

class LiveBusLocationScreen extends StatefulWidget {
  const LiveBusLocationScreen({super.key});

  @override
  State<LiveBusLocationScreen> createState() => _LiveBusLocationScreenState();
}

class _LiveBusLocationScreenState extends State<LiveBusLocationScreen> {
  Map<String, dynamic>? locationData;
  bool isLoading = true;
  String errorMessage = '';
  String? driverId;
  latlong.LatLng? userLocation;
  latlong.LatLng? driverLocation;
  bool _isMapReady = false;

  bool isBlinking = false;
  double? distanceInKm;

  final MapController _mapController = MapController();
  Timer? _timer;

  bool _showInactiveMessage = false;

  @override
  void initState() {
    super.initState();
    _initializeDataAndStartFetch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Core Initialization and Data Flow Logic (Unchanged) ---

  Future<void> _initializeDataAndStartFetch() async {
    await _loadDriverId();

    if (driverId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    await _getUserLocation();

    await _fetchLocationData(isInitial: true);

    if (mounted) {
      setState(() {
        isLoading = false;
        _showInactiveMessage = (locationData?['shareStatus'] == false);
      });

      if (locationData?['shareStatus'] == true) {
        _startPeriodicFetch();
      } else if (_showInactiveMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showInactiveDialog();
        });
      }
    }
  }

  Future<void> _loadDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    driverId = prefs.getString('driverId');
    if (driverId == null) {
      setState(() {
        errorMessage = 'Driver ID not found. Please log in again.';
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          userLocation = latlong.LatLng(position.latitude, position.longitude);
          if (userLocation != null) {
            // Only move map if user location is the initial center
            if (driverLocation == null && !_isMapReady) {
              _mapController.move(userLocation!, 13.0);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error getting user location: $e');
      }
    }
  }

  Future<void> _fetchLocationData({bool isInitial = false}) async {
    if (isInitial) {
      // Clear error message only for initial load
      setState(() {
        errorMessage = '';
      });
    }

    if (driverId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/driver-locations/status?driverId=$driverId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            locationData = data;
            if (locationData!['shareStatus'] == true) {
              driverLocation = latlong.LatLng(
                locationData!['latitude'],
                locationData!['longitude'],
              );
              _calculateDistance();
              _showInactiveMessage = false;
              if (_isMapReady && driverLocation != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Center on driver location on update
                  _mapController.move(
                    driverLocation!,
                    _mapController.camera.zoom,
                    offset: const Offset(0, 0),
                  );
                });
              }
            } else {
              driverLocation = null;
              if (!isInitial) {
                _timer?.cancel();
                _showInactiveMessage = true;
                _showInactiveDialog();
              }
            }
          });
        }
      } else {
        if (mounted && isInitial) {
          setState(() {
            errorMessage = 'Failed to load data: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted && isInitial) {
        setState(() {
          errorMessage = 'Error: $e';
        });
      }
    }
  }

  void _calculateDistance() {
    if (userLocation != null && driverLocation != null) {
      final distance = Geolocator.distanceBetween(
        userLocation!.latitude,
        userLocation!.longitude,
        driverLocation!.latitude,
        driverLocation!.longitude,
      );
      if (mounted) {
        setState(() {
          distanceInKm = distance / 1000;
        });
      }
    } else {
      distanceInKm = null;
    }
  }

  void _startPeriodicFetch() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _fetchLocationData();
      if (mounted) {
        setState(() {
          isBlinking = !isBlinking;
        });
      }
    });
  }

  void _showInactiveDialog() {
    if (!Navigator.of(context).canPop()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground, // Apply dark background
            title: Text(
              'Location Not Active',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
            content: const Text(
              'Driver location sharing is currently inactive. Please check again later.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchLocationData(isInitial: true);
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: AppTheme.accentColor),
                ),
              ),
            ],
          ),
    );
  }

  void _showDetailsDialog() {
    if (locationData != null && locationData!['shareStatus'] == true) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: AppTheme.cardBackground, // Apply dark background
              title: Text(
                'Driver Location Details',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailText('Latitude: ${locationData!['latitude']}'),
                  _buildDetailText('Longitude: ${locationData!['longitude']}'),
                  _buildDetailText(
                    'Address: ${locationData!['address'] ?? 'N/A'}',
                  ),
                  if (distanceInKm != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Distance: ${distanceInKm!.toStringAsFixed(2)} km',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.iconColor1, // Highlight distance
                        ),
                      ),
                    ),
                  _buildDetailText(
                    'Share Status: ${locationData!['shareStatus'] ? 'Active' : 'Inactive'}',
                    color:
                        locationData!['shareStatus']
                            ? AppTheme.iconColor1
                            : AppTheme.iconColor3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(color: AppTheme.accentColor),
                  ),
                ),
              ],
            ),
      );
    }
  }

  // Helper for consistent detail text style
  Widget _buildDetailText(String text, {Color color = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(text, style: TextStyle(color: color, fontSize: 14)),
    );
  }

  // --- UI Build Methods ---

  Widget _buildMapContent() {
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                  // If driver location is available, center on it after map is ready
                  if (driverLocation != null) {
                    _mapController.move(
                      driverLocation!,
                      15.0,
                    ); // Slightly higher zoom for detail
                  } else if (userLocation != null) {
                    _mapController.move(userLocation!, 13.0);
                  }
                });
              },
              // Initial center uses driver, then user, then default (0,0)
              initialCenter:
                  driverLocation ?? userLocation ?? latlong.LatLng(0, 0),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                // Dark mode tiles might be better for a dark theme, but standard OSM is used here
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  // User Location Marker (Blue)
                  if (userLocation != null)
                    Marker(
                      point: userLocation!,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_pin_circle,
                          color: AppTheme.primaryColor,
                          size: 48,
                        ),
                      ),
                    ),
                  // Driver/Bus Location Marker (Accent Color - Green/Red)
                  if (driverLocation != null)
                    Marker(
                      point: driverLocation!,
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.directions_bus_filled,
                        color:
                            locationData!['shareStatus'] == true
                                ? AppTheme
                                    .iconColor1 // Green for active bus
                                : AppTheme
                                    .iconColor3, // Red for inactive bus (shouldn't be shown if inactive)
                        size: 48,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        _buildDistanceCard(),
      ],
    );
  }

  Widget _buildDistanceCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GestureDetector(
        onTap: _showDetailsDialog,
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: AppTheme.cardBackground, // Dark Card Background
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.alt_route,
                      color: AppTheme.accentColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Distance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${distanceInKm?.toStringAsFixed(2) ?? 'N/A'} km',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.iconColor1, // Green for distance
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInactiveMessage() {
    return Container(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, color: AppTheme.iconColor3, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Bus location sharing is inactive.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap the button below to check the status again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    _showInactiveMessage = false;
                    errorMessage = ''; // Clear previous error if any
                  });
                  _initializeDataAndStartFetch();
                },
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text(
                  'Check Status Again',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor, // Light accent color
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    // Green for ACTIVE, Red for INACTIVE/Error
    final bool isActive = locationData?['shareStatus'] == true;
    final Color liveColor =
        isActive
            ? (isBlinking
                ? AppTheme.iconColor1
                : AppTheme
                    .primaryColor) // Blink between light green and bright blue
            : AppTheme.iconColor3; // Red for inactive

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, // Dark Background
      appBar: AppBar(
        title: const Text(
          'Live Bus Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.cardBackground, // Darker App Bar
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                // Blinking Indicator
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: liveColor,
                    shape: BoxShape.circle,
                    boxShadow:
                        isActive
                            ? [
                              BoxShadow(
                                color: liveColor.withOpacity(0.6),
                                blurRadius:
                                    isBlinking
                                        ? 8
                                        : 4, // More subtle blink effect
                                spreadRadius: isBlinking ? 4 : 2,
                              ),
                            ]
                            : null,
                  ),
                ),
                const SizedBox(width: 8),
                // 'LIVE' Text
                Text(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: liveColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Live Bus Location...',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              )
              : errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Connection Error: $errorMessage',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.iconColor3, fontSize: 16),
                  ),
                ),
              )
              : locationData != null && locationData!['shareStatus'] == true
              ? _buildMapContent()
              : _buildInactiveMessage(),
    );
  }
}
