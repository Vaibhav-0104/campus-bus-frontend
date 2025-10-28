import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:campus_bus_management/config/api_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

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
  PlatformFile? _selectedLicenseFile;
  String? _currentLicenseDocument;

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
    _fetchDrivers();
    _requestPermissions();
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

  Future<void> _requestPermissions() async {
    if (!kIsWeb) {
      var storageStatus = await Permission.storage.request();
      var mediaStatus = await Permission.photos.request();

      if (storageStatus.isDenied || mediaStatus.isDenied) {
        _showSnackBar("Storage permission denied. Cannot access files.");
      } else if (storageStatus.isPermanentlyDenied ||
          mediaStatus.isPermanentlyDenied) {
        _showSnackBar(
          "Storage permission permanently denied. Please enable in settings.",
        );
        await openAppSettings();
      }
    }
  }

  Future<void> _fetchDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/drivers'),
      );
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

  Future<void> _pickLicensePdf() async {
    try {
      debugPrint("Opening file picker...");
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowCompression: true,
      );
      if (result != null && result.files.isNotEmpty) {
        if (result.files.first.size > 5 * 1024 * 1024) {
          _showSnackBar("Selected file is too large (max 5MB)");
          return;
        }
        debugPrint("File selected: ${result.files.first.name}");
        setState(() {
          _selectedLicenseFile = result.files.first;
        });
      } else {
        debugPrint("No file selected");
        _showSnackBar("No PDF selected");
      }
    } catch (e) {
      debugPrint("Error opening file picker: $e");
      _showSnackBar("Failed to open file picker: $e");
    }
  }

  Future<void> _addOrUpdateDriver() async {
    if (_formKey.currentState!.validate()) {
      if (_editingIndex == null && _selectedLicenseFile == null) {
        _showSnackBar("Please upload a license PDF");
        return;
      }

      try {
        String driverId =
            _editingIndex != null ? _driverList[_editingIndex!]['_id'] : '';
        var uri = Uri.parse(
          _editingIndex == null
              ? '${ApiConfig.baseUrl}/drivers'
              : '${ApiConfig.baseUrl}/drivers/$driverId',
        );
        var request = http.MultipartRequest(
          _editingIndex == null ? 'POST' : 'PUT',
          uri,
        );

        request.fields['name'] = _nameController.text;
        request.fields['contact'] = _contactController.text;
        request.fields['license'] = _licenseController.text;
        request.fields['email'] = _emailController.text;
        request.fields['status'] = _isActive ? 'Active' : 'Inactive';

        if (_passwordController.text.isNotEmpty) {
          request.fields['password'] = _passwordController.text;
        }

        if (_selectedLicenseFile != null) {
          debugPrint("Uploading file: ${_selectedLicenseFile!.name}");
          if (kIsWeb) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'licenseDocument',
                _selectedLicenseFile!.bytes!,
                filename: _selectedLicenseFile!.name,
              ),
            );
          } else {
            request.files.add(
              await http.MultipartFile.fromPath(
                'licenseDocument',
                _selectedLicenseFile!.path!,
              ),
            );
          }
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == (_editingIndex == null ? 201 : 200)) {
          _showSnackBar(
            _editingIndex == null
                ? 'Driver added successfully!'
                : 'Driver updated successfully!',
            isSuccess: true,
          );
          await _fetchDrivers();
          _clearForm();
          setState(() {
            _editingIndex = null;
            _currentLicenseDocument = null;
            _selectedLicenseFile = null;
          });
        } else {
          throw Exception(
            "Failed to save driver: ${jsonDecode(response.body)['message'] ?? response.body}",
          );
        }
      } catch (e) {
        debugPrint("Error: $e");
        _showSnackBar(
          'Failed to save driver: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _deleteDriver(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _confirmDialog(),
    );
    if (ok != true) return;

    try {
      String driverId = _driverList[index]['_id'];
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/drivers/$driverId'),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to delete driver: ${jsonDecode(response.body)['message'] ?? response.body}",
        );
      }
      _showSnackBar('Driver deleted successfully!', isSuccess: true);
      await _fetchDrivers();
    } catch (e) {
      debugPrint("Error deleting driver: $e");
      _showSnackBar(
        'Failed to delete driver: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _editDriver(int index) {
    final driver = _driverList[index];
    setState(() {
      _nameController.text = driver['name'] ?? '';
      _contactController.text = driver['contact'] ?? '';
      _licenseController.text = driver['license'] ?? '';
      _emailController.text = driver['email'] ?? '';
      _passwordController.text = '';
      _isActive = driver['status'] == 'Active';
      _currentLicenseDocument = driver['licenseDocument'];
      _selectedLicenseFile = null;
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
    _selectedLicenseFile = null;
    _currentLicenseDocument = null;
    setState(() => _editingIndex = null);
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
          if (label == 'Password' &&
              _editingIndex != null &&
              (value == null || value.isEmpty))
            return null;
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (label == 'Email') {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value))
              return 'Please enter a valid email (e.g., example@domain.com)';
          }
          if (label == 'Contact Number' && value.length < 10)
            return 'Contact number must be at least 10 digits';
          if (label == 'License Number') {
            final licenseRegex = RegExp(r'^[A-Z0-9]{6,15}$');
            if (!licenseRegex.hasMatch(value))
              return 'License number must be 6-15 alphanumeric characters';
          }
          if (label == 'Password' && value.length < 6)
            return 'Password must be at least 6 characters long';
          return null;
        },
      ),
    );
  }

  Widget _buildLicenseDocumentField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'License Document (PDF only${_editingIndex == null ? '' : ', Optional'})',
            style: TextStyle(color: textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (_editingIndex != null && _currentLicenseDocument != null)
            GestureDetector(
              onTap: () async {
                final pdfUrl = '${ApiConfig.baseUrl}$_currentLicenseDocument';
                if (await canLaunchUrl(Uri.parse(pdfUrl))) {
                  await launchUrl(
                    Uri.parse(pdfUrl),
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  _showSnackBar('Could not launch PDF');
                }
              },
              child: Text(
                'View Current PDF',
                style: TextStyle(
                  color: busYellow,
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                ),
              ),
            ),
          if (_editingIndex != null && _currentLicenseDocument != null)
            const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: glassBg,
              border: Border.all(color: glassBorder, width: 1.2),
            ),
            child: ListTile(
              leading: Icon(Icons.upload_file, color: busYellow),
              title: Text(
                _selectedLicenseFile != null
                    ? _selectedLicenseFile!.name
                    : 'Select PDF',
                style: TextStyle(color: textSecondary),
              ),
              onTap: _pickLicensePdf,
            ),
          ),
        ],
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
          'Driver Status: Active',
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
              onPressed: _addOrUpdateDriver,
              icon: const Icon(Icons.save),
              label: Text(
                _editingIndex == null ? 'Add Driver' : 'Update Driver',
              ),
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
        'Are you sure you want to delete this driver record?',
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
            Icon(Icons.person, color: busYellow, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Manage Drivers',
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
          child: SingleChildScrollView(
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
                          _editingIndex == null
                              ? "Add New Driver"
                              : "Edit Driver Details",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          _nameController,
                          'Full Name',
                          Icons.person,
                        ),
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
                          _editingIndex == null
                              ? 'Password'
                              : 'Password (Optional)',
                          Icons.lock,
                          TextInputType.text,
                          true,
                        ),
                        const SizedBox(height: 8),
                        _buildLicenseDocumentField(),
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
                      _driverList.isEmpty
                          ? const Center(
                            child: Text(
                              'No driver details available!',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                          : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStatePropertyAll(
                                busYellow.withAlpha(0x33),
                              ),
                              dataRowColor: WidgetStateProperty.resolveWith(
                                (states) => Colors.white.withAlpha(0x0D),
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
                                    'License Document',
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
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            driver['contact'] ?? 'N/A',
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            driver['license'] ?? 'N/A',
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            driver['email'] ?? 'N/A',
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (driver['status'] ==
                                                          'Active'
                                                      ? Colors.green
                                                      : Colors.red)
                                                  .withAlpha(0x99),
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                          driver['licenseDocument'] != null
                                              ? GestureDetector(
                                                onTap: () async {
                                                  final pdfUrl =
                                                      '${ApiConfig.baseUrl}${driver['licenseDocument']}';
                                                  if (await canLaunchUrl(
                                                    Uri.parse(pdfUrl),
                                                  )) {
                                                    await launchUrl(
                                                      Uri.parse(pdfUrl),
                                                      mode:
                                                          LaunchMode
                                                              .externalApplication,
                                                    );
                                                  } else {
                                                    _showSnackBar(
                                                      'Could not launch PDF',
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  'View PDF',
                                                  style: TextStyle(
                                                    color: busYellow,
                                                    decoration:
                                                        TextDecoration
                                                            .underline,
                                                  ),
                                                ),
                                              )
                                              : Text(
                                                'N/A',
                                                style: TextStyle(
                                                  color: textSecondary,
                                                ),
                                              ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: busYellow,
                                                ),
                                                onPressed:
                                                    () => _editDriver(index),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed:
                                                    () => _deleteDriver(index),
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
