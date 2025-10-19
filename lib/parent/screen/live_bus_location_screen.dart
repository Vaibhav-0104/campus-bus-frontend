import 'dart:async';
import 'package:campus_bus_management/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
// NOTE: geocoding import is not strictly needed for the functionality
// import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

class LiveBusLocationScreen extends StatefulWidget {
  const LiveBusLocationScreen({super.key});

  @override
  State<LiveBusLocationScreen> createState() => _LiveBusLocationScreenState();
}

class _LiveBusLocationScreenState extends State<LiveBusLocationScreen> {
  Map<String, dynamic>? locationData;
  // Use 'isLoading' for the initial fetch state (CircularProgressIndicator)
  bool isLoading = true;
  String errorMessage = '';
  String? driverId;
  latlong.LatLng? userLocation;
  latlong.LatLng? driverLocation;
  bool _isMapReady = false;

  // 'isFetching' is now purely for the blinking indicator state
  bool isBlinking = false;
  double? distanceInKm;

  final MapController _mapController = MapController();
  Timer? _timer;

  // Track if we need to show the inactive dialog
  bool _showInactiveMessage = false;

  @override
  void initState() {
    super.initState();
    // Start the combined process
    _initializeDataAndStartFetch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Core Initialization and Data Flow Logic ---

  Future<void> _initializeDataAndStartFetch() async {
    await _loadDriverId();

    if (driverId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Await user location, but allow execution to continue if it fails/is denied
    await _getUserLocation();

    // First, perform the initial data fetch and update UI
    await _fetchLocationData(isInitial: true);

    // After the initial fetch is complete
    if (mounted) {
      setState(() {
        isLoading = false;
        // Set the flag to show inactive message/dialog if status is false
        _showInactiveMessage = (locationData?['shareStatus'] == false);
      });

      // If active, start periodic fetching
      if (locationData?['shareStatus'] == true) {
        _startPeriodicFetch();
      } else if (_showInactiveMessage) {
        // If inactive, show the dialog right away after the build frame completes
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
          // Only attempt to move the map if location is valid
          if (userLocation != null) {
            _mapController.move(userLocation!, 13.0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error getting user location: $e');
      }
    }
  }

  // Combine original fetchLocationData with a flag for initial load
  Future<void> _fetchLocationData({bool isInitial = false}) async {
    if (!isInitial) {
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
              // When driver is active, ensure inactive message is hidden and map is centered
              _showInactiveMessage = false;
              if (_isMapReady && driverLocation != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mapController.move(
                    driverLocation!,
                    _mapController.camera.zoom, // keep same zoom
                    offset: const Offset(0, 0),
                  );
                });
              }
            } else {
              driverLocation = null;
              // If status becomes inactive, stop periodic fetch and show dialog
              if (!isInitial) {
                _timer?.cancel();
                _showInactiveMessage = true;
                _showInactiveDialog();
              }
            }
          });
        }
      } else {
        if (mounted) {
          // Only show error on initial load or if not an expected 200 status during live update
          if (isInitial) {
            setState(() {
              errorMessage = 'Failed to load data: ${response.statusCode}';
            });
          }
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
          distanceInKm = distance / 1000; // Convert meters to kilometers
        });
      }
    } else {
      distanceInKm = null;
    }
  }

  void _startPeriodicFetch() {
    // Stop any existing timer first
    _timer?.cancel();

    // Start a new timer for both fetching data and blinking the indicator
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _fetchLocationData(); // isInitial: false by default
      if (mounted) {
        setState(() {
          isBlinking = !isBlinking; // Toggles the blinking state
        });
      }
    });
  }

  void _showInactiveDialog() {
    // Only show if the dialog is not already open
    if (!Navigator.of(context).canPop()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Not Active'),
            content: const Text(
              'Driver location sharing is currently inactive.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Allow re-fetch attempt on button press
                  _fetchLocationData(isInitial: true);
                },
                child: const Text('OK'),
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
              title: const Text('Driver Location Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latitude: ${locationData!['latitude']}'),
                  Text('Longitude: ${locationData!['longitude']}'),
                  Text('Address: ${locationData!['address'] ?? 'N/A'}'),
                  if (distanceInKm != null)
                    Text(
                      'Distance: ${distanceInKm!.toStringAsFixed(2)} km',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  Text(
                    'Share Status: ${locationData!['shareStatus'] ? 'Active' : 'Inactive'}',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    }
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
                });
              },
              initialCenter:
                  driverLocation ?? userLocation ?? latlong.LatLng(0, 0),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  if (userLocation != null)
                    Marker(
                      point: userLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  if (driverLocation != null)
                    Marker(
                      point: driverLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.red,
                        size: 40,
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
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _showDetailsDialog,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: Colors.purple[100],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Distance: ${distanceInKm?.toStringAsFixed(2) ?? 'N/A'} km',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, color: Colors.grey, size: 80),
          const SizedBox(height: 20),
          const Text(
            'Bus location sharing is inactive.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Attempt to re-fetch to check status again
              setState(() {
                isLoading = true; // Show loading indicator again
                _showInactiveMessage = false;
              });
              _initializeDataAndStartFetch();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Check Status Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    // Determine the color for the blinking indicator
    final liveColor =
        (locationData?['shareStatus'] == true && isBlinking)
            ? Colors
                .white // Blink white on purple appbar
            : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Bus Location',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
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
                        liveColor == Colors.white
                            ? [
                              BoxShadow(
                                color: liveColor.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 2,
                              ),
                            ]
                            : null,
                  ),
                ),
                const SizedBox(width: 6),
                // 'LIVE' Text
                Text(
                  'LIVE',
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
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.purple),
                    SizedBox(height: 16),
                    Text(
                      'Loading Live Bus Location...',
                      style: TextStyle(fontSize: 16, color: Colors.purple),
                    ),
                  ],
                ),
              )
              : errorMessage.isNotEmpty
              ? Center(
                child: Text(
                  'Error: $errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
              : locationData != null && locationData!['shareStatus'] == true
              ? _buildMapContent()
              : _buildInactiveMessage(),
    );
  }
}
