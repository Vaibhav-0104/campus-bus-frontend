import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String busApiUrl = "https://campus-bus-backend.onrender.com/api/buses";
const String driverApiUrl =
    "https://campus-bus-backend.onrender.com/api/drivers";

class ManageBusDetailsScreen extends StatefulWidget {
  const ManageBusDetailsScreen({super.key});

  @override
  State<ManageBusDetailsScreen> createState() => _ManageBusDetailsScreenState();
}

class _ManageBusDetailsScreenState extends State<ManageBusDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  String? _selectedDriverId;
  bool _isActive = true;
  int? _selectedBusIndex;

  List<Map<String, dynamic>> _busList = [];
  List<Map<String, dynamic>> _driverList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _toController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);
      await Future.wait([_fetchBuses(), _fetchDrivers()]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBuses() async {
    try {
      final response = await http.get(Uri.parse(busApiUrl));
      debugPrint('Bus API response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          _busList = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
          debugPrint('Bus list loaded: ${_busList.length} buses');
        });
      } else {
        _showSnackBar('Failed to load buses: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching buses: $e');
      _showSnackBar('Failed to load buses');
    }
  }

  Future<void> _fetchDrivers() async {
    try {
      final response = await http.get(Uri.parse(driverApiUrl));
      debugPrint(
        'Driver API response: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> drivers = json.decode(response.body);
        setState(() {
          _driverList =
              drivers.asMap().entries.map((entry) {
                final driver = entry.value as Map<String, dynamic>;
                if (driver['_id'] == null || driver['_id'].toString().isEmpty) {
                  debugPrint(
                    'Driver with missing _id at index ${entry.key}: $driver',
                  );
                }
                return driver;
              }).toList();
          debugPrint('Driver list loaded: ${_driverList.length} drivers');
        });
      } else {
        _showSnackBar('Failed to load drivers: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
      _showSnackBar('Failed to load drivers');
    }
  }

  Future<void> _addOrUpdateBus() async {
    if (_formKey.currentState!.validate()) {
      final busDetails = {
        'busNumber': _busNumberController.text,
        'from': 'Uka Tarsadia University',
        'to': _toController.text,
        'capacity': int.parse(_capacityController.text),
        'driverId': _selectedDriverId ?? '',
        'status': _isActive ? 'Active' : 'Inactive',
      };

      try {
        if (_selectedBusIndex == null) {
          final response = await http.post(
            Uri.parse(busApiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(busDetails),
          );
          debugPrint(
            'Add bus response: ${response.statusCode} ${response.body}',
          );
          if (response.statusCode != 201) {
            throw Exception('Failed to add bus: ${response.body}');
          }
          _showSnackBar('Bus added successfully!');
        } else {
          String busId = _busList[_selectedBusIndex!]['_id'];
          final response = await http.put(
            Uri.parse('$busApiUrl/$busId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(busDetails),
          );
          debugPrint(
            'Update bus response: ${response.statusCode} ${response.body}',
          );
          if (response.statusCode != 200) {
            throw Exception('Failed to update bus: ${response.body}');
          }
          _showSnackBar('Bus updated successfully!');
          _selectedBusIndex = null;
        }
        _fetchBuses();
        _clearForm();
      } catch (e) {
        debugPrint('Error saving bus: $e');
        _showSnackBar(
          'Failed to save bus: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _deleteBus(int index) async {
    try {
      String busId = _busList[index]['_id'];
      final response = await http.delete(Uri.parse('$busApiUrl/$busId'));
      debugPrint(
        'Delete bus response: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete bus: ${response.body}');
      }
      _showSnackBar('Bus deleted successfully!');
      _fetchBuses();
    } catch (e) {
      debugPrint('Error deleting bus: $e');
      _showSnackBar('Failed to delete bus: $e');
    }
  }

  void _editBus(int index) {
    final bus = _busList[index];
    setState(() {
      _busNumberController.text = bus['busNumber'] ?? '';
      _toController.text = bus['to'] ?? '';
      _capacityController.text = (bus['capacity'] ?? 0).toString();
      _selectedDriverId = bus['driverId']?.toString();
      _isActive = bus['status'] == 'Active';
      _selectedBusIndex = index;
      debugPrint(
        'Editing bus with driverId: $_selectedDriverId, bus: ${bus['busNumber']}',
      );
    });
  }

  void _clearForm() {
    _busNumberController.clear();
    _toController.clear();
    _capacityController.clear();
    _selectedDriverId = null;
    _isActive = true;
    setState(() {});
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    TextInputType inputType = TextInputType.text,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
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

  Widget _buildDriverDropdown() {
    final uniqueDrivers = <String, Map<String, dynamic>>{};
    for (var driver in _driverList) {
      final id = driver['_id']?.toString();
      if (id != null && id.isNotEmpty && !uniqueDrivers.containsKey(id)) {
        uniqueDrivers[id] = driver;
      } else {
        debugPrint('Invalid or duplicate driver: $driver');
      }
    }

    if (_selectedDriverId != null &&
        !uniqueDrivers.containsKey(_selectedDriverId)) {
      debugPrint(
        'Invalid _selectedDriverId: $_selectedDriverId, resetting to null',
      );
      _selectedDriverId = null;
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Assign Driver',
        prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 202, 205, 205),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 202, 205, 205),
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
      value: _selectedDriverId,
      items:
          uniqueDrivers.isNotEmpty
              ? uniqueDrivers.values.map((driver) {
                final id = driver['_id']?.toString() ?? '';
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(driver['name'] ?? 'Unknown'),
                );
              }).toList()
              : [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text('No drivers available'),
                  enabled: false,
                ),
              ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a driver';
        }
        return null;
      },
      onChanged:
          uniqueDrivers.isNotEmpty
              ? (value) => setState(() {
                _selectedDriverId = value;
                debugPrint('Selected driverId: $value');
              })
              : null,
    );
  }

  Widget _buildStatusToggle() {
    return SwitchListTile(
      title: const Text('Active'),
      value: _isActive,
      onChanged: (value) => setState(() => _isActive = value),
      activeColor: Colors.deepPurple,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _addOrUpdateBus,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.deepPurple,
            backgroundColor: Colors.white,
          ),
          child: Text(_selectedBusIndex == null ? 'Add Bus' : 'Update Bus'),
        ),
        ElevatedButton(
          onPressed: _clearForm,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.deepPurple,
            backgroundColor: Colors.white,
          ),
          child: const Text('Clear'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 251, 252, 253),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Manage Bus Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFormCard(),
                      const SizedBox(height: 30),
                      _buildBusTable(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                _busNumberController,
                'Bus Number',
                Icons.directions_bus,
              ),
              TextFormField(
                initialValue: 'Uka Tarsadia University',
                readOnly: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on, color: Colors.deepPurple),
                  labelText: 'From',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 8),
              _buildTextField(_toController, 'To', Icons.location_on),
              _buildTextField(
                _capacityController,
                'Capacity',
                Icons.people,
                TextInputType.number,
              ),
              _buildDriverDropdown(),
              _buildStatusToggle(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusTable() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child:
            _busList.isEmpty
                ? const Center(
                  child: Text(
                    'No bus details available!',
                    style: TextStyle(fontSize: 18),
                  ),
                )
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Bus Number')),
                      DataColumn(label: Text('From')),
                      DataColumn(label: Text('To')),
                      DataColumn(label: Text('Capacity')),
                      DataColumn(label: Text('Driver')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows:
                        _busList.asMap().entries.map((entry) {
                          int index = entry.key;
                          var bus = entry.value;
                          final busDriverId = bus['driverId']?.toString();
                          final driver = _driverList.firstWhere(
                            (d) => d['_id']?.toString() == busDriverId,
                            orElse: () {
                              debugPrint(
                                'No driver found for bus driverId: $busDriverId, bus: ${bus['busNumber']}',
                              );
                              return {'name': 'Unknown'};
                            },
                          );
                          return DataRow(
                            cells: [
                              DataCell(Text(bus['busNumber'] ?? '')),
                              DataCell(Text(bus['from'] ?? '')),
                              DataCell(Text(bus['to'] ?? '')),
                              DataCell(Text((bus['capacity'] ?? 0).toString())),
                              DataCell(Text(driver['name'] ?? 'Unknown')),
                              DataCell(Text(bus['status'] ?? '')),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.deepPurple,
                                      ),
                                      onPressed: () => _editBus(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.deepPurple,
                                      ),
                                      onPressed: () => _deleteBus(index),
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
}
