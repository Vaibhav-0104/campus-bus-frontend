import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:campus_bus_management/config/api_config.dart';
import 'package:campus_bus_management/admin/screen/show_drivers_details.dart' show DriverLocationData;

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
          // Print admin and driver locations on update
          debugPrint('Admin Location: Lat=${_deviceLocation?.latitude}, Lon=${_deviceLocation?.longitude}');
          debugPrint('Driver Location: Lat=${_locationData?.latitude}, Lon=${_locationData?.longitude}');
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

  @override
  Widget build(BuildContext context) {
    if (_locationData?.shareStatus == false) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Location Not Active',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final distance = _calculateDistance();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Location',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 97, 104, 114).withAlpha(204),
                Colors.blue.shade700.withAlpha(153),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                    color: Colors.white,
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
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _locationData?.shareStatus == true &&
              (_locationData?.latitude == null ||
                  _locationData?.longitude == null ||
                  _deviceLocation == null)
          ? Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 15),
                      const Text(
                        'Fetching a Driver Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _locationData?.latitude != null &&
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
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white.withAlpha(242),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: const Color.fromARGB(255, 240, 248, 255), // Light cyan background
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                          
                            children: [
                              const Icon(
                                Icons.directions_bus,
                                color: Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                ': ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _locationData?.address ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.teal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.directions, color: Colors.blue, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                'Remaining Distance: ${distance.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}