import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui'; // Required for ImageFilter for blur effects

const String apiUrl = "http://192.168.31.104:5000/api/drivers";

class ManageBusDriverDetailsScreen extends StatefulWidget {
  const ManageBusDriverDetailsScreen({super.key});

  @override
  State<ManageBusDriverDetailsScreen> createState() =>
      _ManageBusDriverDetailsScreenState();
}

class _ManageBusDriverDetailsScreenState
    extends State<ManageBusDriverDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isActive = true;
  int? _editingIndex;
  List<Map<String, dynamic>> _driverList = [];

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _licenseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchDrivers() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _driverList = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
        });
      } else {
        _showSnackBar("Failed to load drivers: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching drivers: $e");
      _showSnackBar("Error fetching drivers: $e");
    }
  }

  Future<void> _addOrUpdateDriver() async {
    if (_formKey.currentState!.validate()) {
      final driverDetails = {
        'name': _nameController.text,
        'contact': _contactController.text,
        'license': _licenseController.text,
        'email': _emailController.text,
        'status': _isActive ? 'Active' : 'Inactive',
      };

      // Only include password if provided
      if (_passwordController.text.isNotEmpty) {
        driverDetails['password'] = _passwordController.text;
      }

      try {
        http.Response response;
        String message;

        if (_editingIndex == null) {
          // Add driver
          response = await http.post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(driverDetails),
          );
          if (response.statusCode != 201) {
            throw Exception(
              "Failed to add driver: ${jsonDecode(response.body)['message'] ?? response.body}",
            );
          }
          message = 'Driver added successfully!';
        } else {
          // Update driver
          String driverId = _driverList[_editingIndex!]['_id'];
          response = await http.put(
            Uri.parse("$apiUrl/$driverId"),
            headers: {"Content-Type": "application/json"},
            body: json.encode(driverDetails),
          );
          if (response.statusCode != 200) {
            throw Exception(
              "Failed to update driver: ${jsonDecode(response.body)['message'] ?? response.body}",
            );
          }
          message = 'Driver updated successfully!';
          _editingIndex = null;
        }
        await _fetchDrivers();
        _clearForm();
        _showSnackBar(message, isSuccess: true);
      } catch (e) {
        debugPrint("Error: $e");
        _showSnackBar(
          'Failed to save driver: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _deleteDriver(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.blue.shade800.withValues(alpha: 0.8),
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this driver record?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  String driverId = _driverList[index]['_id'];
                  final response = await http.delete(
                    Uri.parse("$apiUrl/$driverId"),
                    headers: {"Content-Type": "application/json"},
                  );
                  if (response.statusCode != 200) {
                    throw Exception(
                      "Failed to delete driver: ${jsonDecode(response.body)['message'] ?? response.body}",
                    );
                  }
                  _showSnackBar(
                    'Driver deleted successfully!',
                    isSuccess: true,
                  );
                  await _fetchDrivers();
                } catch (e) {
                  debugPrint("Error deleting driver: $e");
                  _showSnackBar(
                    'Failed to delete driver: ${e.toString().replaceFirst('Exception: ', '')}',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editDriver(int index) {
    final driver = _driverList[index];
    setState(() {
      _nameController.text = driver['name'] ?? '';
      _contactController.text = driver['contact'] ?? '';
      _licenseController.text = driver['license'] ?? '';
      _emailController.text = driver['email'] ?? '';
      _passwordController.text = ''; // Keep empty to indicate no change
      _isActive = driver['status'] == 'Active';
      _editingIndex = index;
    });
  }

  void _clearForm() {
    _nameController.clear();
    _contactController.clear();
    _licenseController.clear();
    _emailController.clear();
    _passwordController.clear();
    _isActive = true;
    setState(() {
      _editingIndex = null;
    });
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType inputType = TextInputType.text,
    bool obscureText = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.lightBlueAccent, size: 24),
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
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
          // Allow empty password during updates
          if (label == 'Password' &&
              _editingIndex != null &&
              (value == null || value.isEmpty)) {
            return null;
          }
          // Required fields check
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          // Email validation
          if (label == 'Email') {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return 'Please enter a valid email (e.g., example@domain.com)';
            }
          }
          // Contact number validation
          if (label == 'Contact Number' && value.length < 10) {
            return 'Contact number must be at least 10 digits';
          }
          // License number validation
          if (label == 'License Number') {
            final licenseRegex = RegExp(r'^[A-Z0-9]{6,15}$');
            if (!licenseRegex.hasMatch(value)) {
              return 'License number must be 6-15 alphanumeric characters';
            }
          }
          // Password length validation (for new drivers or when provided)
          if (label == 'Password' && value.length < 6) {
            return 'Password must be at least 6 characters long';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade800.withValues(alpha: 0.4),
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
                    onPressed: _addOrUpdateDriver,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600.withValues(
                        alpha: 0.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _editingIndex == null ? 'Add Driver' : 'Update Driver',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade800.withValues(alpha: 0.4),
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
                    onPressed: _clearForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600.withValues(
                        alpha: 0.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.blue.shade300.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: SwitchListTile(
              title: const Text(
                'Driver Status: Active',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: Colors.lightBlueAccent,
              inactiveTrackColor: Colors.grey.shade700.withValues(alpha: 0.5),
              activeTrackColor: Colors.lightBlueAccent.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Manage Driver Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800.withValues(alpha: 0.3),
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
                AppBar().preferredSize.height +
                MediaQuery.of(context).padding.top +
                16,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
          ),
          child: Column(
            children: [
              _buildFormCard(),
              const SizedBox(height: 30),
              _buildDriverTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueGrey.shade300.withValues(alpha: 0.15),
                Colors.blueGrey.shade700.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(10, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(-8, -8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  _editingIndex == null
                      ? "Add New Driver"
                      : "Edit Driver Details",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildTextField(_nameController, 'Full Name', Icons.person),
                _buildTextField(
                  _contactController,
                  'Contact Number',
                  Icons.phone,
                  TextInputType.phone,
                ),
                _buildTextField(
                  _licenseController,
                  'License Number',
                  Icons.credit_card,
                ),
                _buildTextField(
                  _emailController,
                  'Email',
                  Icons.email,
                  TextInputType.emailAddress,
                ),
                _buildTextField(
                  _passwordController,
                  _editingIndex == null ? 'Password' : 'Password (Optional)',
                  Icons.lock,
                  TextInputType.text,
                  true,
                ),
                _buildStatusToggle(),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueGrey.shade300.withValues(alpha: 0.15),
                Colors.blueGrey.shade700.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(10, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(-8, -8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                _driverList.isEmpty
                    ? const Center(
                      child: Text(
                        'No driver details available!',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) =>
                                  Colors.blue.shade800.withValues(alpha: 0.6),
                            ),
                        dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) =>
                              Colors.white.withValues(alpha: 0.05),
                        ),
                        columnSpacing: 30,
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        headingRowHeight: 70,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Full Name',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Contact',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'License',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                        rows:
                            _driverList.asMap().entries.map((entry) {
                              int index = entry.key;
                              var driver = entry.value;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      driver['name'] ?? 'N/A',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      driver['contact'] ?? 'N/A',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      driver['license'] ?? 'N/A',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      driver['email'] ?? 'N/A',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (driver['status'] == 'Active'
                                                ? Colors.green
                                                : Colors.red)
                                            .withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        driver['status'] ?? 'N/A',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.lightBlueAccent,
                                          ),
                                          onPressed: () => _editDriver(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () => _deleteDriver(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
