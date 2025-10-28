import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:campus_bus_management/config/api_config.dart';

class ManageStudentFeesScreen extends StatefulWidget {
  const ManageStudentFeesScreen({super.key});

  @override
  ManageStudentFeesScreenState createState() => ManageStudentFeesScreenState();
}

class ManageStudentFeesScreenState extends State<ManageStudentFeesScreen> {
  final TextEditingController feeController = TextEditingController();
  final TextEditingController routeController = TextEditingController();
  String? selectedDepartment;
  String? selectedEnvNumber;
  String? selectedDuration;
  List<String> departments = [];
  List<String> envNumbers = [];
  final List<String> durations = ['1month', '6months', '1year'];
  bool isLoadingDepartments = true;
  bool isLoadingEnvNumbers = false;
  final logger = Logger();

  // ────── NEW COLORS (Same as other screens) ──────
  final Color bgStart = const Color(0xFF0A0E1A);
  final Color bgMid = const Color(0xFF0F172A);
  final Color bgEnd = const Color(0xFF1E293B);
  final Color glassBg = Colors.white.withAlpha(0x14);
  final Color glassBorder = Colors.white.withAlpha(0x26);
  final Color textSecondary = Colors.white70;
  final Color busYellow = const Color(0xFFFBBF24);

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  @override
  void dispose() {
    feeController.dispose();
    routeController.dispose();
    super.dispose();
  }

  // ────── API LOGIC UNCHANGED ──────
  Future<void> _fetchDepartments() async {
    try {
      setState(() {
        isLoadingDepartments = true;
      });
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/fees/departments'),
      );
      logger.d(
        'Departments API Response: ${response.statusCode} ${response.body}',
      );
      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> fetchedDepartments = data['departments'] ?? [];
          setState(() {
            departments = fetchedDepartments.cast<String>();
            isLoadingDepartments = false;
          });
        } else {
          setState(() {
            departments = [];
            isLoadingDepartments = false;
          });
          final errorMsg =
              jsonDecode(response.body)['error'] ?? "No departments found";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      }
    } catch (e) {
      logger.e('Error fetching departments: $e');
      if (mounted) {
        setState(() {
          departments = [];
          isLoadingDepartments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error fetching departments!")),
        );
      }
    }
  }

  Future<void> _fetchEnvNumbers(String department) async {
    try {
      setState(() {
        isLoadingEnvNumbers = true;
      });
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/fees/env-numbers/$department'),
      );
      logger.d(
        'Env Numbers API Response: ${response.statusCode} ${response.body}',
      );
      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> fetchedEnvNums = data['envNumbers'] ?? [];
          setState(() {
            envNumbers = fetchedEnvNums.cast<String>();
            selectedEnvNumber = envNumbers.isNotEmpty ? envNumbers[0] : null;
            isLoadingEnvNumbers = false;
          });
          if (selectedEnvNumber != null) {
            _fetchRoute(selectedEnvNumber!);
          } else {
            setState(() {
              routeController.text = '';
            });
          }
        } else {
          setState(() {
            envNumbers = [];
            selectedEnvNumber = null;
            routeController.text = '';
            isLoadingEnvNumbers = false;
          });
          final errorMsg =
              jsonDecode(response.body)['error'] ?? "No students found";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$errorMsg for department: $department")),
          );
        }
      }
    } catch (e) {
      logger.e('Error fetching env numbers: $e');
      if (mounted) {
        setState(() {
          envNumbers = [];
          selectedEnvNumber = null;
          routeController.text = '';
          isLoadingEnvNumbers = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error fetching enrollment numbers!")),
        );
      }
    }
  }

  Future<void> _fetchRoute(String envNumber) async {
    if (envNumber.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/students/route-by-env/$envNumber'),
        );
        logger.d('Route API Response: ${response.statusCode} ${response.body}');
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
            final errorMsg =
                jsonDecode(response.body)['error'] ?? "Route not found";
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$errorMsg for envNumber: $envNumber")),
            );
          }
        }
      } catch (e) {
        logger.e('Error fetching route: $e');
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
    if (selectedDepartment == null ||
        selectedEnvNumber == null ||
        selectedDuration == null ||
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

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fees/set-fee'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "envNumber": selectedEnvNumber,
          "feeAmount": feeAmount,
          "route": routeController.text,
          "duration": selectedDuration,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fee set successfully!")),
          );
          setState(() {
            selectedDepartment = null;
            selectedEnvNumber = null;
            selectedDuration = null;
            envNumbers = [];
            feeController.clear();
            routeController.clear();
          });
        } else {
          final errorMsg =
              jsonDecode(response.body)['error'] ?? "Failed to set fee";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      }
    } catch (e) {
      logger.e('Error setting fees: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error setting fees!")));
      }
    }
  }

  // ────── NEW GLASS CARD UI ──────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments, color: busYellow, size: 28),
            const SizedBox(width: 8),
            const Text(
              "Manage Fees",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.white.withAlpha(0x0D)),
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
            colors: [bgStart, bgMid, bgEnd],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
            left: 16,
            right: 16,
            bottom: 20,
          ),
          child: _glassCard(),
        ),
      ),
    );
  }

  Widget _glassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: glassBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Manage Student Fees",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              _buildDepartmentDropdown(),
              const SizedBox(height: 20),
              _buildEnvNumberDropdown(),
              const SizedBox(height: 20),
              _buildDurationDropdown(),
              const SizedBox(height: 20),
              _buildTextField(
                feeController,
                "Fee Amount",
                Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                routeController,
                "Route",
                Icons.directions_bus,
                readOnly: true,
              ),
              const SizedBox(height: 30),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ────── UI WIDGETS (Only Color/Style Changed) ──────
  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedDepartment,
      onChanged:
          isLoadingDepartments
              ? null
              : (value) {
                setState(() {
                  selectedDepartment = value;
                  selectedEnvNumber = null;
                  selectedDuration = null;
                  envNumbers = [];
                  routeController.text = '';
                });
                if (value != null) _fetchEnvNumbers(value);
              },
      items:
          departments
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
      decoration: _inputDecoration(
        "Department",
        Icons.school,
        isLoadingDepartments,
      ),
      dropdownColor: bgMid,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      icon: Icon(Icons.arrow_drop_down, color: busYellow),
      validator: (v) => v == null ? 'Please select a department' : null,
    );
  }

  Widget _buildEnvNumberDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedEnvNumber,
      onChanged:
          isLoadingEnvNumbers
              ? null
              : (value) {
                setState(() => selectedEnvNumber = value);
                if (value != null)
                  _fetchRoute(value);
                else
                  routeController.text = '';
              },
      items:
          envNumbers
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
      decoration: _inputDecoration(
        "Enrollment Number",
        Icons.person_outline,
        isLoadingEnvNumbers,
      ),
      dropdownColor: bgMid,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      icon: Icon(Icons.arrow_drop_down, color: busYellow),
      validator: (v) => v == null ? 'Please select an enrollment number' : null,
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedDuration,
      onChanged: (value) => setState(() => selectedDuration = value),
      items:
          durations
              .map(
                (d) => DropdownMenuItem(
                  value: d,
                  child: Text(
                    d.replaceAll('month', ' Month').replaceAll('year', ' Year'),
                  ),
                ),
              )
              .toList(),
      decoration: _inputDecoration("Fee Duration", Icons.calendar_today, false),
      dropdownColor: bgMid,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      icon: Icon(Icons.arrow_drop_down, color: busYellow),
      validator: (v) => v == null ? 'Please select a duration' : null,
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
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: _inputDecoration(
        label,
        icon,
        false,
      ).copyWith(filled: true, fillColor: glassBg),
      validator: (v) => v!.isEmpty ? 'Please enter $label' : null,
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    bool isLoading,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textSecondary, fontSize: 18),
      prefixIcon:
          isLoading
              ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: busYellow,
                ),
              )
              : Icon(icon, color: busYellow, size: 28),
      filled: true,
      fillColor: glassBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: glassBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: glassBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: busYellow, width: 2.5),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: busYellow.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _setFees,
        style: ElevatedButton.styleFrom(
          backgroundColor: busYellow,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          "Set Fees",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
