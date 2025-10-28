import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:campus_bus_management/config/api_config.dart';

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

  // ────── COLORS (Same as AllocateBusScreen) ──────
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
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/buses'));
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/drivers'),
      );
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
            Uri.parse('${ApiConfig.baseUrl}/buses'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(busDetails),
          );
          debugPrint(
            'Add bus response: ${response.statusCode} ${response.body}',
          );
          if (response.statusCode != 201) {
            throw Exception('Failed to add bus: ${response.body}');
          }
          _showSnackBar('Bus added successfully!', true);
        } else {
          String busId = _busList[_selectedBusIndex!]['_id'];
          final response = await http.put(
            Uri.parse('${ApiConfig.baseUrl}/buses/$busId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(busDetails),
          );
          debugPrint(
            'Update bus response: ${response.statusCode} ${response.body}',
          );
          if (response.statusCode != 200) {
            throw Exception('Failed to update bus: ${response.body}');
          }
          _showSnackBar('Bus updated successfully!', true);
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _confirmDialog(),
    );
    if (ok != true) return;

    try {
      String busId = _busList[index]['_id'];
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/buses/$busId'),
      );
      debugPrint(
        'Delete bus response: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete bus: ${response.body}');
      }
      _showSnackBar('Bus deleted successfully!', true);
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
    setState(() => _selectedBusIndex = null);
  }

  void _showSnackBar(String message, [bool success = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ────── GLASS CARD & INPUTS ──────
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: glassBorder, width: 1.2),
          ),
          child: child,
        ),
      ),
    );
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
          labelText: label,
          labelStyle: TextStyle(color: textSecondary),
          prefixIcon: Icon(icon, color: busYellow),
          filled: true,
          fillColor: glassBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: glassBorder, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: glassBorder, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: busYellow, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (inputType == TextInputType.number &&
              int.tryParse(value) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDriverDropdown() {
    final Set<String> assignedDriverIds =
        _busList
            .where((bus) => bus['status'] == 'Active')
            .map((bus) => bus['driverId']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();

    String? currentDriverId;
    if (_selectedBusIndex != null) {
      currentDriverId = _busList[_selectedBusIndex!]['driverId']?.toString();
    }

    final uniqueDrivers = <String, Map<String, dynamic>>{};
    for (var driver in _driverList) {
      final id = driver['_id']?.toString() ?? '';
      if (id.isNotEmpty && !uniqueDrivers.containsKey(id)) {
        final isAssignedToActiveBus = assignedDriverIds.contains(id);
        if (!isAssignedToActiveBus ||
            (currentDriverId != null && id == currentDriverId)) {
          uniqueDrivers[id] = driver;
        }
      }
    }

    if (_selectedDriverId != null &&
        !uniqueDrivers.containsKey(_selectedDriverId)) {
      _selectedDriverId = null;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: glassBg,
        border: Border.all(color: glassBorder, width: 1.2),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDriverId,
        hint: Text('Assign Driver', style: TextStyle(color: textSecondary)),
        style: const TextStyle(color: Colors.white),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        dropdownColor: bgMid,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person, color: busYellow, size: 24),
          labelText: 'Assign Driver',
          labelStyle: TextStyle(color: textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
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
        validator:
            (v) => v == null || v.isEmpty ? 'Please select a driver' : null,
        onChanged:
            uniqueDrivers.isNotEmpty
                ? (v) => setState(() => _selectedDriverId = v)
                : null,
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: glassBg,
        border: Border.all(color: glassBorder, width: 1.2),
      ),
      child: SwitchListTile(
        title: const Text(
          'Bus Status: Active',
          style: TextStyle(color: Colors.white),
        ),
        value: _isActive,
        onChanged: (v) => setState(() => _isActive = v),
        activeColor: busYellow,
        inactiveThumbColor: Colors.grey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addOrUpdateBus,
              icon: const Icon(Icons.save),
              label: Text(_selectedBusIndex == null ? 'Add Bus' : 'Update Bus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: busYellow,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _clearForm,
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: glassBg,
      title: const Text(
        'Confirm Deletion',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'Are you sure you want to delete this bus record?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete'),
        ),
      ],
    );
  }

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
            Icon(Icons.directions_bus, color: busYellow, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Manage Buses',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgMid, bgEnd],
          ),
        ),
        child: SafeArea(
          child:
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: busYellow))
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _glassCard(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Text(
                                  _selectedBusIndex == null
                                      ? "Add New Bus"
                                      : "Edit Bus Details",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  _busNumberController,
                                  'Bus Number',
                                  Icons.directions_bus,
                                ),
                                // From Field (Read-only)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: TextFormField(
                                    initialValue: 'Uka Tarsadia University',
                                    readOnly: true,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.location_on,
                                        color: busYellow,
                                      ),
                                      labelText: 'From',
                                      labelStyle: TextStyle(
                                        color: textSecondary,
                                      ),
                                      filled: true,
                                      fillColor: glassBg,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: glassBorder,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: glassBorder,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildTextField(
                                  _toController,
                                  'To',
                                  Icons.location_on,
                                ),
                                _buildTextField(
                                  _capacityController,
                                  'Capacity',
                                  Icons.people,
                                  TextInputType.number,
                                ),
                                const SizedBox(height: 8),
                                _buildDriverDropdown(),
                                const SizedBox(height: 8),
                                _buildStatusToggle(),
                                _buildActionButtons(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _glassCard(
                          child:
                              _busList.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'No bus details available!',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                  : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: WidgetStatePropertyAll(
                                        busYellow.withAlpha(0x33),
                                      ),
                                      dataRowColor:
                                          WidgetStateProperty.resolveWith(
                                            (states) =>
                                                Colors.white.withAlpha(0x0D),
                                          ),
                                      columnSpacing: 30,
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 60,
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
                                                    ? bus['driverId']['_id']
                                                        .toString()
                                                    : bus['driverId']
                                                        .toString();
                                            final driverName =
                                                bus['driverId'] is Map
                                                    ? bus['driverId']['name']
                                                    : _driverList.firstWhere(
                                                      (d) =>
                                                          d['_id']
                                                              ?.toString() ==
                                                          busDriverId,
                                                      orElse:
                                                          () => {
                                                            'name': 'Unknown',
                                                          },
                                                    )['name'];
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    bus['busNumber'] ?? '',
                                                    style: TextStyle(
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    bus['from'] ?? '',
                                                    style: TextStyle(
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    bus['to'] ?? '',
                                                    style: TextStyle(
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    (bus['capacity'] ?? 0)
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    driverName ?? 'Unknown',
                                                    style: TextStyle(
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: (bus['status'] ==
                                                                  'Active'
                                                              ? Colors.green
                                                              : Colors.red)
                                                          .withAlpha(0x99),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      bus['status'] ?? '',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.edit,
                                                          color: busYellow,
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                _editBus(index),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color:
                                                              Colors.redAccent,
                                                        ),
                                                        onPressed:
                                                            () => _deleteBus(
                                                              index,
                                                            ),
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
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
