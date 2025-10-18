import 'dart:async';
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:campus_bus_management/config/api_config.dart'; // Import centralized URL

class FaceAttendanceScreen extends StatefulWidget {
  const FaceAttendanceScreen({super.key});

  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  String _message = '';
  bool _isLoading = false;
  bool _isProcessing = false;
  Timer? _frameTimer;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameras();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopRecognition();
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameras();
    }
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _message = '❌ No cameras available!';
        });
        return;
      }

      // Select the front-facing camera
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      if (frontCamera == null) {
        setState(() {
          _message = '❌ No front camera available!';
        });
        return;
      }

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _message = '';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Camera initialization failed: $e';
      });
    }
  }

  Future<void> _startRealTimeRecognition() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      _showSnackBar('Camera is not ready!');
      return;
    }

    setState(() {
      _isProcessing = true;
      _message = '🔄 Starting real-time face recognition...';
    });

    _frameTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) async {
      if (!_isProcessing || !mounted) {
        timer.cancel();
        return;
      }
      await _captureAndSendFrame();
    });
  }

  Future<void> _captureAndSendFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      setState(() {
        _isLoading = true;
      });

      // Use centralized baseUrl from ApiConfig
      final uri = Uri.parse('${ApiConfig.baseUrl}/students/attendance');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes('image', bytes, filename: 'frame.jpg'),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        _showSnackBar(
          '✅ Attendance marked for ${jsonResponse['student']}!',
          isSuccess: true,
        );
        _stopRecognition();
      } else {
        final jsonResponse = json.decode(responseBody);
        _showSnackBar('❌ ${jsonResponse['message'] ?? 'Face not recognized'}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('❌ Error: $e');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 16)),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _stopRecognition() {
    _frameTimer?.cancel();
    _frameTimer = null;
    setState(() {
      _isProcessing = false;
      _message = '';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopRecognition();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Extend body behind app bar for full gradient
      appBar: AppBar(
        title: const Text(
          'Face Attendance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(
          0.3,
        ), // Liquid glass app bar
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade500,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top + 70,
              ), // Spacing below app bar
              AspectRatio(
                // Enforce square aspect ratio for the camera view
                aspectRatio: 1.0,
                child: ClipRRect(
                  // Clip for liquid glass effect
                  borderRadius: BorderRadius.circular(
                    25,
                  ), // Increased rounded corners
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 18.0,
                      sigmaY: 18.0,
                    ), // Stronger blur effect
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(
                              0.18,
                            ), // Slightly more opaque
                            Colors.purple.shade200.withOpacity(
                              0.18,
                            ), // Slightly more opaque
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ), // More prominent border
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.3,
                            ), // Darker shadow for depth
                            blurRadius: 30, // Increased blur radius
                            spreadRadius: 4, // Increased spread radius
                            offset: const Offset(
                              10,
                              10,
                            ), // More pronounced offset
                          ),
                          BoxShadow(
                            // Inner light shadow for a subtle glow
                            color: Colors.white.withOpacity(
                              0.15,
                            ), // Brighter inner glow
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(-8, -8), // Top-left inner glow
                          ),
                        ],
                      ),
                      child: Center(
                        // Center content within the card
                        child:
                            _cameraController == null ||
                                    !_cameraController!.value.isInitialized
                                ? Text(
                                  _message.isEmpty
                                      ? 'Loading Camera...'
                                      : _message,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(
                                      0.9,
                                    ), // Brighter text
                                    fontSize: 20, // Larger font size
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 6,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                )
                                : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CameraPreview(_cameraController!),
                                    if (_isLoading)
                                      Container(
                                        color: Colors.black.withOpacity(
                                          0.6,
                                        ), // Darker overlay
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30), // Increased spacing
              ElevatedButton.icon(
                onPressed:
                    _isProcessing
                        ? _stopRecognition
                        : _startRealTimeRecognition,
                icon: Icon(
                  _isProcessing ? Icons.stop : Icons.camera_alt,
                  size: 28, // Larger icon
                ),
                label: Text(
                  _isProcessing ? 'Stop Recognition' : 'Start Recognition',
                  style: const TextStyle(
                    fontSize: 20, // Larger font size for button text
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.transparent, // Transparent background for button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                  ), // Increased vertical padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      18,
                    ), // Even more rounded
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ), // More prominent border
                  ),
                  elevation: 10, // More elevation for button
                  shadowColor: Colors.black.withOpacity(
                    0.6,
                  ), // Darker shadow color
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.purple.shade900.withOpacity(
                        0.4,
                      ); // Pressed state overlay
                    }
                    return Colors.deepPurple.shade700.withOpacity(
                      0.2,
                    ); // Default overlay
                  }),
                  // Custom background color as a gradient
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey.withOpacity(0.6);
                    }
                    return Colors.deepPurple.shade800.withOpacity(
                      0.6,
                    ); // Semi-transparent purple
                  }),
                ),
              ),
              const SizedBox(height: 20), // Increased spacing
              AnimatedOpacity(
                opacity: _message.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: ClipRRect(
                  // Clip for liquid glass effect
                  borderRadius: BorderRadius.circular(
                    18,
                  ), // Matched button radius
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 12.0,
                      sigmaY: 12.0,
                    ), // Stronger blur
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.blue.shade100.withOpacity(0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(6, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20), // Increased padding
                      child: Text(
                        _message.isEmpty ? ' ' : _message,
                        style: TextStyle(
                          fontSize: 18, // Larger font
                          color: Colors.white.withOpacity(
                            0.95,
                          ), // Brighter text
                          height: 1.5,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
