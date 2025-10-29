import 'dart:async';
import 'package:campus_bus_management/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

// Updated Purple Theme (Matches Dashboard)
class AppTheme {
  static const Color primary = Color(0xFF6A1B9A); // Deep Purple
  static const Color lightPurple = Color(0xFFCE93D8); // Light Purple Accent
  static const Color background = Color(0xFFF8F5FF); // Light Purple BG
  static const Color cardBg = Colors.white; // White Cards
  static const Color textPrimary = Color(0xFF4A148C); // Dark Purple Text
  static const Color textSecondary = Color(0xFF7E57C2);
  static const Color activeColor = Color(0xFF66BB6A); // Green
  static const Color inactiveColor = Color(0xFFFF5252); // Red

  static const double cardBorderRadius = 20.0;
  static const double blur = 12.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
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

  Future<void> _initializeDataAndStartFetch() async {
    await _loadDriverId();

    if (driverId == null) {
      setState(() => isLoading = false);
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
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _showInactiveDialog(),
        );
      }
    }
  }

  Future<void> _loadDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    driverId = prefs.getString('driverId');
    if (driverId == null) {
      setState(
        () => errorMessage = 'Driver ID not found. Please log in again.',
      );
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
          if (userLocation != null && driverLocation == null && !_isMapReady) {
            _mapController.move(userLocation!, 13.0);
          }
        });
      }
    } catch (e) {
      if (mounted) print('Error getting user location: $e');
    }
  }

  Future<void> _fetchLocationData({bool isInitial = false}) async {
    if (isInitial) setState(() => errorMessage = '');
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
                  _mapController.move(
                    driverLocation!,
                    _mapController.camera.zoom,
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
      } else if (mounted && isInitial) {
        setState(
          () => errorMessage = 'Failed to load data: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted && isInitial) setState(() => errorMessage = 'Error: $e');
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
      if (mounted) setState(() => distanceInKm = distance / 1000);
    } else {
      distanceInKm = null;
    }
  }

  void _startPeriodicFetch() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _fetchLocationData();
      if (mounted) setState(() => isBlinking = !isBlinking);
    });
  }

  void _showInactiveDialog() {
    if (!Navigator.of(context).canPop()) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            ),
            title: const Text(
              'Location Not Active',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Driver location sharing is currently inactive. Please check again later.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchLocationData(isInitial: true);
                },
                child: const Text(
                  'OK',
                  style: TextStyle(color: AppTheme.lightPurple),
                ),
              ),
            ],
          ),
    );
  }

  void _showDetailsDialog() {
    if (locationData == null || locationData!['shareStatus'] != true) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            ),
            title: const Text(
              'Driver Location Details',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.activeColor,
                      ),
                    ),
                  ),
                _buildDetailText(
                  'Share Status: ${locationData!['shareStatus'] ? 'Active' : 'Inactive'}',
                  color:
                      locationData!['shareStatus']
                          ? AppTheme.activeColor
                          : AppTheme.inactiveColor,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: AppTheme.lightPurple),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailText(
    String text, {
    Color color = const Color(0xFF7E57C2),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(text, style: TextStyle(color: color, fontSize: 14)),
    );
  }

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
                  if (driverLocation != null) {
                    _mapController.move(driverLocation!, 15.0);
                  } else if (userLocation != null) {
                    _mapController.move(userLocation!, 13.0);
                  }
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
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_pin_circle,
                          color: AppTheme.primary,
                          size: 48,
                        ),
                      ),
                    ),
                  if (driverLocation != null)
                    Marker(
                      point: driverLocation!,
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.directions_bus_filled,
                        color:
                            locationData!['shareStatus'] == true
                                ? AppTheme.activeColor
                                : AppTheme.inactiveColor,
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.alt_route, color: AppTheme.lightPurple, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Distance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${distanceInKm?.toStringAsFixed(2) ?? 'N/A'} km',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.activeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInactiveMessage() {
    return Container(
      color: AppTheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, color: AppTheme.inactiveColor, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Bus location sharing is inactive.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap the button below to check the status again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    _showInactiveMessage = false;
                    errorMessage = '';
                  });
                  _initializeDataAndStartFetch();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = locationData?['shareStatus'] == true;
    final Color liveColor =
        isActive
            ? (isBlinking ? AppTheme.activeColor : AppTheme.primary)
            : AppTheme.inactiveColor;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Live Bus Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
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
                                color: liveColor.withValues(alpha: 0.6),
                                blurRadius: isBlinking ? 8 : 4,
                                spreadRadius: isBlinking ? 4 : 2,
                              ),
                            ]
                            : null,
                  ),
                ),
                const SizedBox(width: 8),
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
                    CircularProgressIndicator(color: AppTheme.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading Live Bus Location...',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
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
                    style: TextStyle(
                      color: AppTheme.inactiveColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              : locationData != null && locationData!['shareStatus'] == true
              ? _buildMapContent()
              : _buildInactiveMessage(),
    );
  }
}
