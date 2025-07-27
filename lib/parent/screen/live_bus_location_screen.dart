import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui';

/// Configuration class for bus-related constants
class BusConfig {
  static const String screenTitle = 'Live Bus Location';
  static const String headerTitle = 'Bus Tracking';
  static const LatLng busLocation = LatLng(
    37.7749,
    -122.4194,
  ); // Mock location (San Francisco)
  static const String busNumber = 'GJ-123';
  static const String busRoute = 'School to Downtown';
  static const int initialEtaMinutes = 15;
  static const int etaUpdateIntervalSeconds = 10;
  static const int minEtaMinutes = 5;
  static const int maxEtaMinutes = 15;
}

/// Theme-related constants
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(0xFF0D47A1); // Colors.blue[900]
  static const Color accentColor = Colors.lightBlueAccent;
  static const Color successColor = Colors.green;
  static const Color pendingColor = Colors.orange;
  static const Color absentColor = Colors.redAccent;
  static const Color cardBackground = Color(
    0xFF1E2A44,
  ); // Darker blue for cards
  static const double cardBorderRadius = 20.0;
  static const double blurSigma = 10.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double elevation = 8.0;
  static const double iconSize = 28.0;
}

/// Reusable bus details card widget
class BusDetailsCard extends StatelessWidget {
  final String busNumber;
  final String busRoute;
  final int etaMinutes;

  const BusDetailsCard({
    super.key,
    required this.busNumber,
    required this.busRoute,
    required this.etaMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing / 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(4, 4),
            blurRadius: AppTheme.blurSigma,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            offset: const Offset(-4, -4),
            blurRadius: AppTheme.blurSigma,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.blurSigma,
            sigmaY: AppTheme.blurSigma,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26), // 0.1 * 255 = 26
              border: Border.all(
                color: Colors.white.withAlpha(76), // 0.3 * 255 = 76
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bus Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing),
                Text(
                  'Bus Number: $busNumber',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Route: $busRoute',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(204),
                    fontSize: 16,
                  ),
                ),
                Text(
                  'ETA: $etaMinutes minutes',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(204),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LiveBusLocationScreen extends StatefulWidget {
  const LiveBusLocationScreen({super.key});

  @override
  State<LiveBusLocationScreen> createState() => _LiveBusLocationScreenState();
}

class _LiveBusLocationScreenState extends State<LiveBusLocationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Timer? _etaTimer;
  int _etaMinutes = BusConfig.initialEtaMinutes;
  bool _isMapLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate ETA updates periodically
    _etaTimer = Timer.periodic(
      const Duration(seconds: BusConfig.etaUpdateIntervalSeconds),
      (timer) {
        if (mounted) {
          setState(() {
            _etaMinutes = (_etaMinutes - 1).clamp(
              BusConfig.minEtaMinutes,
              BusConfig.maxEtaMinutes,
            );
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    super.dispose();
  }

  /// Handles map creation and error handling
  void _onMapCreated(GoogleMapController controller) {
    try {
      _controller.complete(controller);
      if (mounted) {
        setState(() {
          _isMapLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMapLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing map: $e'),
            backgroundColor: AppTheme.absentColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          BusConfig.screenTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundColor.withAlpha(
          76,
        ), // 0.3 * 255 = 76
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppTheme.blurSigma,
              sigmaY: AppTheme.blurSigma,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: AppTheme.iconSize,
            ),
            onPressed: () {
              setState(() {
                _isMapLoading = true;
                _etaMinutes = BusConfig.initialEtaMinutes;
              });
              _controller.future.then((controller) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    const CameraPosition(
                      target: BusConfig.busLocation,
                      zoom: 14.0,
                    ),
                  ),
                );
              });
            },
            tooltip: 'Refresh Map',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.backgroundColor, // Solid deep blue background
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.cardPadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.backgroundColor, Colors.blue[600]!],
                    ),
                    borderRadius: BorderRadius.circular(
                      AppTheme.cardBorderRadius,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(4, 4),
                        blurRadius: AppTheme.blurSigma,
                      ),
                    ],
                  ),
                  child: Text(
                    BusConfig.headerTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              // Map Section
              Expanded(
                child:
                    _isMapLoading
                        ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.cardPadding),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(
                                AppTheme.cardBorderRadius,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(4, 4),
                                  blurRadius: AppTheme.blurSigma,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.05),
                                  offset: const Offset(-4, -4),
                                  blurRadius: AppTheme.blurSigma,
                                ),
                              ],
                            ),
                            child: CircularProgressIndicator(
                              color: AppTheme.accentColor,
                            ),
                          ),
                        )
                        : GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: BusConfig.busLocation,
                            zoom: 14.0,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('bus'),
                              position: BusConfig.busLocation,
                              infoWindow: InfoWindow(
                                title: 'Bus ${BusConfig.busNumber}',
                              ),
                            ),
                          },
                          onMapCreated: _onMapCreated,
                        ),
              ),
              // Bus Details Section
              Padding(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing),
                      BusDetailsCard(
                        busNumber: BusConfig.busNumber,
                        busRoute: BusConfig.busRoute,
                        etaMinutes: _etaMinutes,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
