import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

      final uri = Uri.parse(
        'http://192.168.31.104:5000/api/students/attendance',
      );
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
      appBar: AppBar(
        title: const Text(
          'Face Attendance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.indigo[800],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo[50]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      _cameraController == null ||
                              !_cameraController!.value.isInitialized
                          ? Container(
                            height: 300,
                            color: Colors.grey[300],
                            child: Center(
                              child: Text(
                                _message.isEmpty
                                    ? 'Loading Camera...'
                                    : _message,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                          : SizedBox(
                            height: 300,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(_cameraController!),
                                if (_isLoading)
                                  Container(
                                    color: Color.fromRGBO(
                                      0,
                                      0,
                                      0,
                                      0.5,
                                    ), // Updated to fix opacity
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed:
                    _isProcessing
                        ? _stopRecognition
                        : _startRealTimeRecognition,
                icon: Icon(
                  _isProcessing ? Icons.stop : Icons.camera_alt,
                  size: 24,
                ),
                label: Text(
                  _isProcessing ? 'Stop Recognition' : 'Start Recognition',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _message.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _message.isEmpty ? ' ' : _message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
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
