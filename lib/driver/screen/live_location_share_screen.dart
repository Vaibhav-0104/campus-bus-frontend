import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_bus_management/config/api_config.dart';

class LiveLocationShareScreen extends StatefulWidget {
  final String driverId;
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
    _fetchSharingStatus();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontSize: 16)),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          'Failed to fetch sharing status',
          color: Colors.red.shade700,
        );
      }
    } catch (e) {
      _showSnackbar('Error fetching status: $e', color: Colors.red.shade700);
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
      _showSnackbar('Error starting sharing: $e', color: Colors.red.shade700);
    }

    if (isSharing) {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );

      positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async => await _updateLocation(position),
        onError: (e) {
          _stopSharing();
          _showSnackbar("Location stream failed.", color: Colors.orange);
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
      _showSnackbar('Error stopping sharing: $e', color: Colors.red.shade700);
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

        if (response.statusCode != 200) {
          final data = jsonDecode(response.body);
          _showSnackbar(
            data['message'] ?? 'Failed to update location',
            color: Colors.red.shade700,
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

  // --- Geolocation ---
  Future<void> _checkPermissionAndFetch() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      _showSnackbar('Location services disabled!', color: Colors.red.shade700);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackbar('Permission denied!', color: Colors.red.shade700);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackbar(
        'Permission permanently denied!',
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
      _showSnackbar('Error fetching location: $e', color: Colors.red.shade700);
    }
  }

  // --- UI ---
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 41, 41, 41),
        elevation: 0,
        title: const Text(
          "Live Bus Tracker",
          style: TextStyle(
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
        child: Stack(
          children: [
            currentLocation == null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.amber),
                      const SizedBox(height: 16),
                      Text(
                        currentAddress,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                )
                : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: currentLocation!,
                    initialZoom: 16.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation!,
                          width: 60,
                          height: 60,
                          child: Icon(
                            Icons.directions_bus,
                            color: Colors.amber.shade700,
                            size: 45,
                            shadows: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 6,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

            // Bottom Glass Card
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(
                              255,
                              40,
                              40,
                              40,
                            ).withOpacity(0.15),
                            const Color.fromARGB(
                              255,
                              39,
                              39,
                              39,
                            ).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color.fromARGB(
                            255,
                            39,
                            39,
                            39,
                          ).withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 25,
                            offset: const Offset(8, 8),
                          ),
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              35,
                              35,
                              35,
                            ).withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(-5, -5),
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
                              color: Colors.amber.shade300,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.location_on,
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
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.play_arrow,
                                  label: "Start Sharing",
                                  color: Colors.amber.shade600,
                                  onPressed: isSharing ? null : _startSharing,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.stop,
                                  label: "Stop",
                                  color: Colors.red.shade600,
                                  onPressed: isSharing ? _stopSharing : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black87),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey.shade600,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.6),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith((states) {
          return states.contains(MaterialState.pressed)
              ? color.withOpacity(0.8)
              : null;
        }),
      ),
    );
  }
}
