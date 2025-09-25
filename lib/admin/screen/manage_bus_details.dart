import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui'; // Required for ImageFilter for blur effects

const String busApiUrl = "http://172.20.10.9:5000/api/buses";
const String driverApiUrl = "http://172.20.10.9:5000/api/drivers";

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
            json.decode(response.body).map((bus) {
              final driverId = bus['driverId'];
              if (driverId is Map && driverId['_id'] != null) {
                bus['driverId'] = driverId['_id'].toString();
              } else if (driverId is String) {
                bus['driverId'] = driverId;
              }
              return bus;
            }),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
            'Are you sure you want to delete this bus record?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  String busId = _busList[index]['_id'];
                  final response = await http.delete(
                    Uri.parse('$busApiUrl/$busId'),
                  );
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
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
    setState(() {
      _selectedBusIndex = null;
    });
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
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.lightBlueAccent, size: 24),
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.3),
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
      ),
    );
  }

  Widget _buildDriverDropdown() {
    // Compute assigned driver IDs from active buses only
    final Set<String> assignedDriverIds =
        _busList
            .where(
              (bus) => bus['status'] == 'Active',
            ) // Only consider active buses
            .map((bus) => bus['driverId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();

    String? currentDriverId;
    if (_selectedBusIndex != null) {
      currentDriverId = _busList[_selectedBusIndex!]['driverId']?.toString();
    }

    // Unique drivers map
    final uniqueDrivers = <String, Map<String, dynamic>>{};
    for (var driver in _driverList) {
      final id = driver['_id']?.toString() ?? '';
      if (id.isNotEmpty && !uniqueDrivers.containsKey(id)) {
        // Include driver if unassigned, assigned to an inactive bus, or the current bus's driver
        final isAssignedToActiveBus = assignedDriverIds.contains(id);
        if (!isAssignedToActiveBus ||
            (currentDriverId != null && id == currentDriverId)) {
          uniqueDrivers[id] = driver;
        }
      } else if (id.isEmpty) {
        debugPrint('Invalid driver: $driver');
      }
    }

    if (_selectedDriverId != null &&
        !uniqueDrivers.containsKey(_selectedDriverId)) {
      debugPrint(
        'Invalid _selectedDriverId: $_selectedDriverId, resetting to null',
      );
      _selectedDriverId = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.blue.shade800.withOpacity(0.7),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Assign Driver',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          prefixIcon: const Icon(
            Icons.person,
            color: Colors.lightBlueAccent,
            size: 24,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.3),
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
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text(
                      'No drivers available',
                      style: TextStyle(color: Colors.white70),
                    ),
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
                  Colors.white.withOpacity(0.08),
                  Colors.blue.shade300.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: SwitchListTile(
              title: const Text(
                'Bus Status: Active',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: Colors.lightBlueAccent,
              inactiveTrackColor: Colors.grey.shade700.withOpacity(0.5),
              activeTrackColor: Colors.lightBlueAccent.withOpacity(0.5),
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
                    onPressed: _addOrUpdateBus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedBusIndex == null ? 'Add Bus' : 'Update Bus',
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
                    color: Colors.grey.shade800.withOpacity(0.4),
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
                      backgroundColor: Colors.grey.shade600.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Manage Bus Details',
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
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : SingleChildScrollView(
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
                      _buildBusTable(),
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  _selectedBusIndex == null
                      ? "Add New Bus"
                      : "Edit Bus Details",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  _busNumberController,
                  'Bus Number',
                  Icons.directions_bus,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    initialValue: 'Uka Tarsadia University',
                    readOnly: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Colors.lightBlueAccent,
                        size: 24,
                      ),
                      labelText: 'From',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
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
                  ),
                ),
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
      ),
    );
  }

  Widget _buildBusTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                _busList.isEmpty
                    ? const Center(
                      child: Text(
                        'No bus details available!',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) =>
                                  Colors.blue.shade800.withOpacity(0.6),
                            ),
                        dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) =>
                              Colors.white.withOpacity(0.05),
                        ),
                        columnSpacing: 30,
                        dataRowHeight: 60,
                        headingRowHeight: 70,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Bus Number',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'From',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'To',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Capacity',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Driver',
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
                            _busList.asMap().entries.map((entry) {
                              int index = entry.key;
                              var bus = entry.value;
                              final busDriverId =
                                  bus['driverId'] is Map
                                      ? bus['driverId']['_id'].toString()
                                      : bus['driverId'].toString();
                              final driverName =
                                  bus['driverId'] is Map
                                      ? bus['driverId']['name']
                                      : _driverList.firstWhere(
                                        (d) =>
                                            d['_id']?.toString() == busDriverId,
                                        orElse: () => {'name': 'Unknown'},
                                      )['name'];
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      bus['busNumber'] ?? '',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      bus['from'] ?? '',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      bus['to'] ?? '',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      (bus['capacity'] ?? 0).toString(),
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      driverName ?? 'Unknown',
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
                                        color: (bus['status'] == 'Active'
                                                ? Colors.green
                                                : Colors.red)
                                            .withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        bus['status'] ?? '',
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
                                          onPressed: () => _editBus(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
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
        ),
      ),
    );
  }
}
