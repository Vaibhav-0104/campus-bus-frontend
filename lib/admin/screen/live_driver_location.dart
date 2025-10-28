import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:campus_bus_management/config/api_config.dart';
import 'package:campus_bus_management/admin/screen/show_drivers_details.dart'
    show DriverLocationData;

class LiveDriverLocationPage extends StatefulWidget {
  final String driverId;
  final DriverLocationData initialLocationData;

  const LiveDriverLocationPage({
    super.key,
    required this.driverId,
    required this.initialLocationData,
  });

  @override
  State<LiveDriverLocationPage> createState() => _LiveDriverLocationPageState();
}

class _LiveDriverLocationPageState extends State<LiveDriverLocationPage> {
  // ────── COLORS (Same as AllocateBusScreen) ──────
  final Color bgStart = const Color(0xFF0A0E1A);
  final Color bgMid = const Color(0xFF0F172A);
  final Color bgEnd = const Color(0xFF1E293B);
  final Color glassBg = Colors.white.withAlpha(0x14);
  final Color glassBorder = Colors.white.withAlpha(0x26);
  final Color textSecondary = Colors.white70;
  final Color busYellow = const Color(0xFFFBBF24);

  late Timer _timer;
  DriverLocationData? _locationData;
  LatLng? _deviceLocation;
  bool _isLive = false;
  bool _isDataRefreshed = false;

  @override
  void initState() {
    super.initState();
    _locationData = widget.initialLocationData;
    _fetchDeviceLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchDeviceLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      if (mounted) {
        setState(() {
          _deviceLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error fetching device location: $e');
    }
  }

  Future<DriverLocationData> fetchLocationData() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/driver-locations/status?driverId=${widget.driverId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isDataRefreshed = true;
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _isDataRefreshed = false;
              });
            }
          });
        }
        return DriverLocationData.fromJson(data);
      } else {
        throw Exception('Failed to load location: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
      rethrow;
    }
  }

  void _startLocationUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final newLocationData = await fetchLocationData();
        if (mounted) {
          setState(() {
            _locationData = newLocationData;
            _isLive = newLocationData.shareStatus;
          });
        }
      } catch (e) {
        debugPrint('Error updating location: $e');
      }
    });
  }

  double _calculateDistance() {
    if (_deviceLocation != null &&
        _locationData?.latitude != null &&
        _locationData?.longitude != null) {
      final distance = const Distance().as(
        LengthUnit.Kilometer,
        _deviceLocation!,
        LatLng(_locationData!.latitude!, _locationData!.longitude!),
      );
      return distance;
    }
    return 0.0;
  }

  // ────── GLASS CARD (Same as AllocateBusScreen) ──────
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glassBorder, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_locationData?.shareStatus == false) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgStart, bgMid, bgEnd],
            ),
          ),
          child: Center(
            child: _glassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 60,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Location Not Active',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: busYellow,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Back', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final distance = _calculateDistance();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 34, 34, 34),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Driver Location',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.white.withAlpha(0x0D)),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: busYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  opacity: _isDataRefreshed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgMid, bgEnd],
          ),
        ),
        child:
            _locationData?.shareStatus == true &&
                    (_locationData?.latitude == null ||
                        _locationData?.longitude == null ||
                        _deviceLocation == null)
                ? Center(
                  child: _glassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: busYellow),
                        const SizedBox(height: 16),
                        const Text(
                          'Fetching Driver Location...',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                )
                : Column(
                  children: [
                    Expanded(
                      child:
                          _locationData?.latitude != null &&
                                  _locationData?.longitude != null &&
                                  _deviceLocation != null
                              ? FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    _locationData!.latitude!,
                                    _locationData!.longitude!,
                                  ),
                                  initialZoom: 13.0,
                                  minZoom: 10.0,
                                  maxZoom: 18.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    subdomains: const ['a', 'b', 'c'],
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _deviceLocation!,
                                        child: const Icon(
                                          Icons.home,
                                          color: Colors.blue,
                                          size: 40,
                                        ),
                                      ),
                                      Marker(
                                        point: LatLng(
                                          _locationData!.latitude!,
                                          _locationData!.longitude!,
                                        ),
                                        child: const Icon(
                                          Icons.directions_bus,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                              : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                    ),
                    // ────── BOTTOM INFO CARD (GLASS STYLE) ──────
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: _glassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.directions_bus,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  ': ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _locationData?.address ?? 'N/A',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.directions,
                                  color: busYellow,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Distance: ${distance.toStringAsFixed(2)} km',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
}
