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
          final List<dynamic> fetchedEnvNumbers = data['envNumbers'] ?? [];
          setState(() {
            envNumbers = fetchedEnvNumbers.cast<String>();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Manage Fees",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800.withOpacity(0.3),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
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
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top:
                MediaQuery.of(context).padding.top +
                AppBar().preferredSize.height +
                16,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                padding: const EdgeInsets.all(25),
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
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(10, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(-8, -8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Manage Student Fees",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
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
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: Colors.blue.shade900,
          elevation: 0,
          textStyle: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      child: DropdownButtonFormField<String>(
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
                  if (value != null) {
                    _fetchEnvNumbers(value);
                  }
                },
        items:
            departments.map((department) {
              return DropdownMenuItem<String>(
                value: department,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.shade300.withOpacity(0.15),
                        Colors.blueGrey.shade700.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    department,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              );
            }).toList(),
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          prefixIcon:
              isLoadingDepartments
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.lightBlueAccent,
                      ),
                    ),
                  )
                  : const Icon(
                    Icons.school,
                    color: Colors.lightBlueAccent,
                    size: 28,
                  ),
          labelText: "Department",
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
          ),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
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
            ),
          ),
        ),
        dropdownColor: Colors.blue.shade900,
        menuMaxHeight: 300,
        validator:
            (value) => value == null ? 'Please select a department' : null,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        icon: const Icon(Icons.arrow_drop_down, color: Colors.lightBlueAccent),
        itemHeight: 48,
      ),
    );
  }

  Widget _buildEnvNumberDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: Colors.blue.shade900,
          elevation: 0,
          textStyle: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedEnvNumber,
        onChanged:
            isLoadingEnvNumbers
                ? null
                : (value) {
                  setState(() {
                    selectedEnvNumber = value;
                  });
                  if (value != null) {
                    _fetchRoute(value);
                  } else {
                    setState(() {
                      routeController.text = '';
                    });
                  }
                },
        items:
            envNumbers.map((envNumber) {
              return DropdownMenuItem<String>(
                value: envNumber,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.shade300.withOpacity(0.15),
                        Colors.blueGrey.shade700.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    envNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              );
            }).toList(),
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          prefixIcon:
              isLoadingEnvNumbers
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.lightBlueAccent,
                      ),
                    ),
                  )
                  : const Icon(
                    Icons.person_outline,
                    color: Colors.lightBlueAccent,
                    size: 28,
                  ),
          labelText: "Enrollment Number",
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
          ),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
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
            ),
          ),
        ),
        dropdownColor: Colors.blue.shade900,
        menuMaxHeight: 300,
        validator:
            (value) =>
                value == null ? 'Please select an enrollment number' : null,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        icon: const Icon(Icons.arrow_drop_down, color: Colors.lightBlueAccent),
        itemHeight: 48,
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: Colors.blue.shade900,
          elevation: 0,
          textStyle: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedDuration,
        onChanged: (value) {
          setState(() {
            selectedDuration = value;
          });
        },
        items:
            durations.map((duration) {
              return DropdownMenuItem<String>(
                value: duration,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.shade300.withOpacity(0.15),
                        Colors.blueGrey.shade700.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    duration
                        .replaceAll('month', ' Month')
                        .replaceAll('year', ' Year'),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              );
            }).toList(),
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.calendar_today,
            color: Colors.lightBlueAccent,
            size: 28,
          ),
          labelText: "Fee Duration",
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
          ),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
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
            ),
          ),
        ),
        dropdownColor: Colors.blue.shade900,
        menuMaxHeight: 300,
        validator: (value) => value == null ? 'Please select a duration' : null,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        icon: const Icon(Icons.arrow_drop_down, color: Colors.lightBlueAccent),
        itemHeight: 48,
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
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.lightBlueAccent, size: 28),
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 18,
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
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
          ),
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
            color: Colors.blue.shade800.withOpacity(0.4),
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
              backgroundColor: Colors.blue.shade600.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Set Fees",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
