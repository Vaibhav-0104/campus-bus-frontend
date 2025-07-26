import 'package:flutter/material.dart';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageStudentFeesScreen extends StatefulWidget {
  const ManageStudentFeesScreen({super.key});

  @override
  ManageStudentFeesScreenState createState() => ManageStudentFeesScreenState();
}

class ManageStudentFeesScreenState extends State<ManageStudentFeesScreen> {
  final TextEditingController envNumberController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final TextEditingController routeController = TextEditingController();

  static const String routeApiUrl =
      "http://192.168.31.104:5000/api/students/route-by-env";

  @override
  void initState() {
    super.initState();
    envNumberController.addListener(_fetchRoute);
  }

  @override
  void dispose() {
    envNumberController.removeListener(_fetchRoute);
    envNumberController.dispose();
    feeController.dispose();
    routeController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoute() async {
    final envNumber = envNumberController.text.trim();
    if (envNumber.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse('$routeApiUrl/$envNumber'));
        print(
          'Route API Response: ${response.statusCode} ${response.body}',
        ); // Debug log
        if (mounted) {
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final route = data['route'] as String? ?? '';
            setState(() {
              routeController.text = route;
            });
          } else {
            setState(() {
              routeController.text = '';
            });
            if (mounted) {
              final errorMsg =
                  jsonDecode(response.body)['error'] ?? "Route not found";
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$errorMsg for envNumber: $envNumber")),
              );
            }
          }
        }
      } catch (e) {
        print('Error fetching route: $e'); // Debug log
        if (mounted) {
          setState(() {
            routeController.text = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error fetching route!")),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() {
          routeController.text = '';
        });
      }
    }
  }

  Future<void> _setFees() async {
    if (envNumberController.text.isEmpty ||
        feeController.text.isEmpty ||
        routeController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required!")),
        );
      }
      return;
    }

    double? feeAmount = double.tryParse(feeController.text);
    if (feeAmount == null || feeAmount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid fee amount!")),
        );
      }
      return;
    }

    final response = await http.post(
      Uri.parse("http://192.168.31.104:5000/api/fees/set-fee"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "envNumber": envNumberController.text,
        "feeAmount": feeAmount,
        "route": routeController.text,
      }),
    );

    if (mounted) {
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fee updated successfully!")),
        );
        envNumberController.clear();
        feeController.clear();
        routeController.clear();
      } else {
        final errorMsg =
            jsonDecode(response.body)['error'] ?? "Failed to update fee";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Extends the body behind the AppBar for full background effect
      appBar: AppBar(
        title: const Text(
          "Manage Fees",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800.withOpacity(
          0.3,
        ), // Liquid glass app bar
        centerTitle: true,
        elevation: 0, // Remove default shadow
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // White back button
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ), // Blur effect for app bar
            child: Container(
              color:
                  Colors
                      .transparent, // Transparent to show the blurred content behind
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ], // Blue themed gradient background
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top:
                AppBar().preferredSize.height +
                MediaQuery.of(context).padding.top +
                20, // Adjust top padding
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
          ),
          child: Center(
            // Center the card
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                25,
              ), // Rounded corners for liquid glass card
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 20.0,
                  sigmaY: 20.0,
                ), // Stronger blur for the card
                child: Container(
                  // Constrain width for larger screens
                  padding: const EdgeInsets.all(
                    25,
                  ), // Increased padding inside the card
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.shade300.withOpacity(0.15),
                        Colors.blueGrey.shade700.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ), // More visible border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3), // Stronger shadow
                        blurRadius: 30, // Increased blur
                        spreadRadius: 5, // Increased spread
                        offset: const Offset(10, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(
                          0.15,
                        ), // Inner light glow
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(-8, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize:
                        MainAxisSize.min, // Make column take minimum space
                    children: [
                      Text(
                        "Set Student Bus Fees",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 5, color: Colors.black54),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField(
                        envNumberController,
                        "Enrollment Number",
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 20), // Increased spacing
                      _buildTextField(
                        routeController,
                        "Route (Auto-filled)",
                        Icons.directions,
                        readOnly: true,
                      ),
                      const SizedBox(height: 20), // Increased spacing
                      _buildTextField(
                        feeController,
                        "Fee Amount (INR)",
                        Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 30), // Increased spacing
                      _buildActionButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
      ), // White text input
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: Colors.lightBlueAccent,
          size: 28,
        ), // Blue icon
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 18,
        ), // White label
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08), // Subtle translucent fill
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners for input
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.lightBlueAccent,
            width: 2.5,
          ), // Stronger blue focus border
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade800.withOpacity(
              0.4,
            ), // Shadow for the button
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: ElevatedButton(
            onPressed: _setFees,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600.withOpacity(
                0.5,
              ), // Transparent blue background
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ), // Subtle white border
              ),
              elevation:
                  0, // Remove default elevation as we're adding our own shadow
            ),
            child: const Text(
              "Set Fees",
              style: TextStyle(
                fontSize: 22, // Larger font size for button text
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(blurRadius: 5, color: Colors.black54),
                ], // Text shadow
              ),
            ),
          ),
        ),
      ),
    );
  }
}
