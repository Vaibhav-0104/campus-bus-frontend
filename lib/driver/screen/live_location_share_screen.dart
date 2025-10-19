import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/config/api_config.dart'; // Import centralized API config

class LiveLocationShareScreen extends StatefulWidget {
  final String driverId; // Required to identify the driver
  const LiveLocationShareScreen({super.key, required this.driverId});

  @override
  State<LiveLocationShareScreen> createState() =>
      _LiveLocationShareScreenState();
}

class _LiveLocationShareScreenState extends State<LiveLocationShareScreen>
    with SingleTickerProviderStateMixin {
  LatLng? currentLocation;
  String currentAddress = "Fetching address...";
  StreamSubscription<Position>? positionStream;
  bool isSharing = false;
  bool _isBlinking = false;
  final MapController _mapController = MapController();
  late AnimationController _blinkController;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _checkPermissionAndFetch();
    _fetchSharingStatus(); // Fetch initial sharing status
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _blinkController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  // --- Utility Methods ---

  void _showSnackbar(String message, {Color color = Colors.black87}) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  void _startBlinkIndicator() {
    if (!_isBlinking) {
      setState(() => _isBlinking = true);
    }
  }

  void _stopBlinkIndicator() {
    if (_isBlinking) {
      setState(() => _isBlinking = false);
    }
  }

  // --- Backend API Calls ---

  Future<void> _fetchSharingStatus() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/driver-locations/status?driverId=${widget.driverId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      print('Status Endpoint Response Status: ${response.statusCode}');
      print('Status Endpoint Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isSharing = data['shareStatus'] ?? false;
        });
        _showSnackbar(
          isSharing ? 'Location sharing = on' : 'Location sharing = off',
          color: isSharing ? Colors.green : Colors.grey,
        );
        if (isSharing) {
          _startBlinkIndicator();
        } else {
          _stopBlinkIndicator();
        }
      } else {
        _showSnackbar(
          'Failed to fetch sharing status: ${response.statusCode}',
          color: Colors.red.shade700,
        );
      }
    } catch (e) {
      print('Error fetching sharing status: $e');
      _showSnackbar(
        'Error fetching sharing status: $e',
        color: Colors.red.shade700,
      );
    }
  }

  Future<void> _startSharing() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/driver-locations/start-sharing'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': widget.driverId,
          'latitude': currentLocation?.latitude,
          'longitude': currentLocation?.longitude,
          'address': currentAddress,
        }),
      );

      print('Start Sharing Response Status: ${response.statusCode}');
      print('Start Sharing Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => isSharing = data['shareStatus'] ?? true);
        _showSnackbar('Location sharing = on', color: Colors.green);
        _startBlinkIndicator();
      } else {
        final data = jsonDecode(response.body);
        _showSnackbar(
          data['message'] ?? 'Failed to start sharing',
          color: Colors.red.shade700,
        );
      }
    } catch (e) {
      print('Error starting location sharing: $e');
      _showSnackbar(
        'Error starting location sharing: $e',
        color: Colors.red.shade700,
      );
    }

    if (isSharing) {
      // Start location stream
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );

      positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          await _updateLocation(position);
        },
        onError: (e) {
          print("Location Stream Error: $e");
          _stopSharing();
          _showSnackbar(
            "Location stream failed. Sharing stopped.",
            color: Colors.orange,
          );
        },
      );
    }
  }

  Future<void> _stopSharing() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/driver-locations/stop-sharing'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driverId': widget.driverId}),
      );

      print('Stop Sharing Response Status: ${response.statusCode}');
      print('Stop Sharing Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => isSharing = data['shareStatus'] ?? false);
        _showSnackbar('Location sharing = off', color: Colors.red);
        _stopBlinkIndicator();
        positionStream?.cancel();
      } else {
        final data = jsonDecode(response.body);
        _showSnackbar(
          data['message'] ?? 'Failed to stop sharing',
          color: Colors.red.shade700,
        );
      }
    } catch (e) {
      print('Error stopping location sharing: $e');
      _showSnackbar(
        'Error stopping location sharing: $e',
        color: Colors.red.shade700,
      );
    }
  }

  Future<void> _updateLocation(Position position) async {
    if (!mounted) return;

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController.moveAndRotate(currentLocation!, 16.5, 0);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks.first;
      setState(() {
        String street = place.street ?? '';
        String locality = place.locality ?? place.subLocality ?? '';
        currentAddress =
            "$street, $locality, ${place.administrativeArea ?? ''}";
        currentAddress =
            currentAddress.replaceAll(RegExp(r',\s*,*'), ', ').trim();
        if (currentAddress.endsWith(',')) {
          currentAddress = currentAddress.substring(
            0,
            currentAddress.length - 1,
          );
        }
      });

      // Send location update to backend
      if (isSharing) {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/driver-locations/update-location'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'driverId': widget.driverId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'address': currentAddress,
          }),
        );

        print('Update Location Response Status: ${response.statusCode}');
        print('Update Location Response Body: ${response.body}');

        if (response.statusCode != 200) {
          final data = jsonDecode(response.body);
          _showSnackbar(
            data['message'] ?? 'Failed to update location',
            color: Colors.red.shade700,
          );
        } else {
          print(
            "✅ Update: Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)} | Address: $currentAddress",
          );
        }
      }
    } catch (e) {
      setState(() => currentAddress = "Unable to fetch address");
    }

    if (isSharing) {
      _startBlinkIndicator();
      _blinkTimer?.cancel();
      _blinkTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _isBlinking = false);
      });
    }
  }

  // --- Geolocation Methods ---

  Future<void> _checkPermissionAndFetch() async {
    LocationPermission permission;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      _showSnackbar(
        'Location services are disabled!',
        color: Colors.red.shade700,
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackbar(
          'Location permission denied!',
          color: Colors.red.shade700,
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackbar(
        'Location permission permanently denied!',
        color: Colors.red.shade700,
      );
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _updateLocation(position);
    } catch (e) {
      print("Initial location error: $e");
      _showSnackbar(
        'Error fetching initial location: $e',
        color: Colors.red.shade700,
      );
    }
  }

  // --- UI Builder Methods ---

  Widget _buildBlinkingIndicator() {
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color:
                isSharing && _isBlinking
                    ? Colors.redAccent.withOpacity(
                      0.5 + _blinkController.value * 0.5,
                    )
                    : Colors.grey.shade400,
            shape: BoxShape.circle,
            boxShadow:
                isSharing && _isBlinking
                    ? [
                      BoxShadow(
                        color: Colors.white,
                        blurRadius: 5.0 * _blinkController.value,
                        spreadRadius: 3.0 * _blinkController.value,
                      ),
                    ]
                    : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🚌 Live Bus Tracker"),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Row(
              children: [
                Text(
                  isSharing ? "LIVE" : "IDLE",
                  style: TextStyle(
                    color: isSharing ? Colors.greenAccent : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                _buildBlinkingIndicator(),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          currentLocation == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.deepPurple.shade700,
                    ),
                    const SizedBox(height: 10),
                    Text(currentAddress),
                  ],
                ),
              )
              : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentLocation!,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.example.live_location_share',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation!,
                        width: 60,
                        height: 60,
                        child: Icon(
                          Icons.directions_bus,
                          color: Colors.yellow.shade800,
                          size: 45,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Bus Location",
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.deepPurpleAccent),
                  _buildInfoRow(
                    icon: Icons.map,
                    title: "Address",
                    value: currentAddress,
                  ),
                  _buildInfoRow(
                    icon: Icons.alt_route,
                    title: "Coordinates",
                    value:
                        currentLocation == null
                            ? "N/A"
                            : "${currentLocation!.latitude.toStringAsFixed(6)}, ${currentLocation!.longitude.toStringAsFixed(6)}",
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.play_arrow,
                        label: "Start Sharing",
                        color: Colors.green.shade600,
                        onPressed: isSharing ? null : _startSharing,
                      ),
                      _buildActionButton(
                        icon: Icons.stop,
                        label: "Stop",
                        color: Colors.red.shade600,
                        onPressed: isSharing ? _stopSharing : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$title:",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed != null ? color : Colors.grey.shade400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
          ),
        ),
      ),
    );
  }
}
