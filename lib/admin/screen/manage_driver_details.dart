import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiUrl = "https://campus-bus-backend.onrender.com/api/drivers";

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
        throw Exception("Failed to load drivers");
      }
    } catch (e) {
      print("Error fetching drivers: $e");
    }
  }

  Future<void> _addOrUpdateDriver() async {
    if (_formKey.currentState!.validate()) {
      final driverDetails = {
        'name': _nameController.text,
        'contact': _contactController.text,
        'license': _licenseController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'status': _isActive ? 'Active' : 'Inactive',
      };

      try {
        if (_editingIndex == null) {
          // Add driver
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(driverDetails),
          );
          if (response.statusCode != 201)
            throw Exception("Failed to add driver");
          _showSnackBar('Driver added successfully!');
        } else {
          // Update driver
          String driverId = _driverList[_editingIndex!]['_id'];
          final response = await http.put(
            Uri.parse("$apiUrl/$driverId"),
            headers: {"Content-Type": "application/json"},
            body: json.encode(driverDetails),
          );
          if (response.statusCode != 200)
            throw Exception("Failed to update driver");
          _showSnackBar('Driver updated successfully!');
          _editingIndex = null;
        }
        _fetchDrivers();
        _clearForm();
      } catch (e) {
        print("Error: $e");
        _showSnackBar('Failed to save driver');
      }
    }
  }

  Future<void> _deleteDriver(int index) async {
    try {
      String driverId = _driverList[index]['_id'];
      final response = await http.delete(Uri.parse("$apiUrl/$driverId"));
      if (response.statusCode != 200)
        throw Exception("Failed to delete driver");
      _showSnackBar('Driver deleted successfully!');
      _fetchDrivers();
    } catch (e) {
      print("Error deleting driver: $e");
      _showSnackBar('Failed to delete driver');
    }
  }

  void _editDriver(int index) {
    final driver = _driverList[index];
    setState(() {
      _nameController.text = driver['name'];
      _contactController.text = driver['contact'];
      _licenseController.text = driver['license'];
      _emailController.text = driver['email'];
      _passwordController.text = '';
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
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 243, 246),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(103, 58, 183, 1),
        title: const Text(
          'Manage Driver Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTransparentForm(),
              const SizedBox(height: 30),
              _buildDriverTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransparentForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
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
              'Password',
              Icons.lock,
              TextInputType.text,
              true,
            ),
            _buildStatusToggle(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverTable() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child:
            _driverList.isEmpty
                ? const Center(
                  child: Text(
                    'No driver details available!',
                    style: TextStyle(fontSize: 18),
                  ),
                )
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Full Name')),
                      DataColumn(label: Text('Contact')),
                      DataColumn(label: Text('License')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows:
                        _driverList.asMap().entries.map((entry) {
                          int index = entry.key;
                          var driver = entry.value;
                          return DataRow(
                            cells: [
                              DataCell(Text(driver['name'] ?? 'N/A')),
                              DataCell(Text(driver['contact'] ?? 'N/A')),
                              DataCell(Text(driver['license'] ?? 'N/A')),
                              DataCell(Text(driver['email'] ?? 'N/A')),
                              DataCell(Text(driver['status'] ?? 'N/A')),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.deepPurple,
                                      ),
                                      onPressed: () => _editDriver(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.deepPurple,
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
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _addOrUpdateDriver,
          child: Text(_editingIndex == null ? 'Add Driver' : 'Update Driver'),
        ),
        ElevatedButton(onPressed: _clearForm, child: const Text('Clear')),
      ],
    );
  }

  Widget _buildStatusToggle() {
    return SwitchListTile(
      title: const Text('Active'),
      value: _isActive,
      onChanged: (value) => setState(() => _isActive = value),
    );
  }
}
