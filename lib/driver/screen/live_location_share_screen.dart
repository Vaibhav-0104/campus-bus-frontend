import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LiveLocationShareScreen extends StatefulWidget {
  const LiveLocationShareScreen({super.key});

  @override
  State<LiveLocationShareScreen> createState() => _LiveLocationShareScreenState();
}

class _LiveLocationShareScreenState extends State<LiveLocationShareScreen> with SingleTickerProviderStateMixin {
  LatLng? currentLocation;
  String currentAddress = "Fetching address...";
  StreamSubscription<Position>? positionStream;
  bool isSharing = false;
  bool _isBlinking = false; // State for the blinking indicator
  final MapController _mapController = MapController();

  // Animation controller for the blinking effect
  late AnimationController _blinkController;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true); // Repeats the animation, reversing at the end
    
    _checkPermissionAndFetch();
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
          content: Text(message),
          backgroundColor: color,
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

  // --- Geolocation Methods ---

  Future<void> _checkPermissionAndFetch() async {
    LocationPermission permission;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      _showSnackbar('Location services are disabled!', color: Colors.red.shade700);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackbar('Location permission denied!', color: Colors.red.shade700);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackbar('Location permission permanently denied!', color: Colors.red.shade700);
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _updateLocation(position);
    } catch (e) {
      print("Initial location error: $e");
    }
  }

  void _startSharing() {
    // Setting distanceFilter to 0 ensures we get updates for every movement,
    // which is the closest we can get to a 1-second interval using the stream,
    // as Geolocator relies on system events.
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, 
    );

    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      _updateLocation(position);
      // Terminal output (safe print)
      print("✅ Update: Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)} | Address: $currentAddress");
    }, onError: (e) {
      print("Location Stream Error: $e");
      _stopSharing();
      _showSnackbar("Location stream failed. Sharing stopped.", color: Colors.orange);
    });

    setState(() => isSharing = true);
    _startBlinkIndicator();
    _showSnackbar('Live location sharing started! 🟢', color: Colors.green);
  }

  void _stopSharing() {
    positionStream?.cancel();
    setState(() => isSharing = false);
    _stopBlinkIndicator();
    _showSnackbar('Stopped sharing location. 🛑', color: Colors.red);
  }

  Future<void> _updateLocation(Position position) async {
    if (!mounted) return;

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
    
    // Animate map to new location
    _mapController.moveAndRotate(
      currentLocation!,
      16.5,
      0,
    );

    // Reverse Geocoding
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      setState(() {
        // Constructing a robust address string
        String street = place.street ?? '';
        String locality = place.locality ?? place.subLocality ?? '';
        currentAddress = "$street, $locality, ${place.administrativeArea ?? ''}";
        currentAddress = currentAddress.replaceAll(RegExp(r',\s*,*'), ', ').trim();
        if (currentAddress.endsWith(',')) {
          currentAddress = currentAddress.substring(0, currentAddress.length - 1);
        }
      });
    } catch (e) {
      setState(() => currentAddress = "Unable to fetch address");
    }

    // Toggle the blinking effect on every update (if sharing)
    if (isSharing) {
       _startBlinkIndicator();
       // Use a short timer to briefly turn off the blink
       _blinkTimer?.cancel();
       _blinkTimer = Timer(const Duration(milliseconds: 150), () {
         if (mounted) setState(() => _isBlinking = false);
       });
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
            color: isSharing && _isBlinking
                ? Colors.redAccent.withOpacity(0.5 + _blinkController.value * 0.5)
                : Colors.grey.shade400,
            shape: BoxShape.circle,
            boxShadow: isSharing && _isBlinking
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
                      CircularProgressIndicator(color: Colors.deepPurple.shade700),
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
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      // FIX: Remove subdomains and add userAgent to comply with policy
                      userAgentPackageName: 'com.example.live_location_share', 
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation!,
                          width: 60,
                          height: 60,
                          child: Icon(
                            // FIX: Changed icon to Bus Icon
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

          // --- Bottom Info Card (Attractive UI) ---
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
                    value: currentLocation == null
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

  Widget _buildInfoRow({required IconData icon, required String title, required String value}) {
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