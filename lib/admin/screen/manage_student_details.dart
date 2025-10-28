import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:campus_bus_management/config/api_config.dart';

class ManageStudentDetailsScreen extends StatefulWidget {
  const ManageStudentDetailsScreen({super.key});

  @override
  State<ManageStudentDetailsScreen> createState() =>
      _ManageStudentDetailsScreenState();
}

class _ManageStudentDetailsScreenState
    extends State<ManageStudentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _envNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();
  final TextEditingController _parentContactController =
      TextEditingController();

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _editingStudentId;
  List<Map<String, dynamic>> _students = [];

  // ────── COLORS (Same as other screens) ──────
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
    _fetchStudents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _envNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    _mobileController.dispose();
    _parentEmailController.dispose();
    _parentContactController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/students'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(
            jsonDecode(response.body),
          );
        });
      } else {
        _showSnackBar('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error fetching students: $e');
    }
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImage = null;
        });
      } else {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _selectedImageBytes = null;
        });
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: glassBg,
            title: const Text(
              'Select Image Source',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera, color: busYellow),
                  title: const Text(
                    'Camera',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: busYellow),
                  title: const Text(
                    'Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final uri =
        _editingStudentId == null
            ? Uri.parse('${ApiConfig.baseUrl}/students')
            : Uri.parse('${ApiConfig.baseUrl}/students/$_editingStudentId');

    final request = http.MultipartRequest(
      _editingStudentId == null ? 'POST' : 'PUT',
      uri,
    );

    if (_selectedImage != null && !kIsWeb) {
      request.files.add(
        await http.MultipartFile.fromPath('image', _selectedImage!.path),
      );
    } else if (_selectedImageBytes != null && kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _selectedImageBytes!,
          filename: 'image.jpg',
        ),
      );
    }

    request.fields.addAll({
      'name': _nameController.text.trim(),
      'envNumber': _envNumberController.text.trim(),
      'email': _emailController.text.trim(),
      if (_editingStudentId == null ||
          _passwordController.text.trim().isNotEmpty)
        'password': _passwordController.text.trim(),
      'department': _departmentController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'parentEmail': _parentEmailController.text.trim(),
      'parentContact': _parentContactController.text.trim(),
    });

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar(
          'Student ${_editingStudentId == null ? 'added' : 'updated'} successfully!',
          isSuccess: true,
        );
        _clearForm();
        _fetchStudents();
      } else {
        _showSnackBar('Failed to save: $responseBody');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _clearForm() {
    setState(() {
      _editingStudentId = null;
      _nameController.clear();
      _envNumberController.clear();
      _emailController.clear();
      _passwordController.clear();
      _departmentController.clear();
      _mobileController.clear();
      _parentEmailController.clear();
      _parentContactController.clear();
      _selectedImage = null;
      _selectedImageBytes = null;
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

  void _editStudent(Map<String, dynamic> student) {
    setState(() {
      _editingStudentId = student['_id'];
      _nameController.text = student['name'] ?? '';
      _envNumberController.text = student['envNumber'] ?? '';
      _emailController.text = student['email'] ?? '';
      _passwordController.text = '';
      _departmentController.text = student['department'] ?? '';
      _mobileController.text = student['mobile'] ?? '';
      _parentEmailController.text = student['parentEmail'] ?? '';
      _parentContactController.text = student['parentContact'] ?? '';
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _deleteStudent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: glassBg,
            title: const Text(
              'Confirm Deletion',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this student?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/students/$id'),
      );
      if (response.statusCode == 200) {
        _showSnackBar('Student deleted successfully!', isSuccess: true);
        _fetchStudents();
      } else {
        _showSnackBar('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
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
    IconData icon, {
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
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
        validator:
            validator ?? (v) => v!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildImagePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Image${_editingStudentId == null ? '' : ' (Optional)'}',
          style: TextStyle(color: textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: glassBorder, width: 1.2),
            ),
            child: Center(
              child:
                  _selectedImage == null && _selectedImageBytes == null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload, color: busYellow, size: 40),
                          Text(
                            'Upload Image',
                            style: TextStyle(color: textSecondary),
                          ),
                        ],
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child:
                            kIsWeb
                                ? Image.memory(
                                  _selectedImageBytes!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                                : Image.file(
                                  _selectedImage!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                      ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please upload a clear face image for recognition',
          style: TextStyle(fontSize: 12, color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveStudent,
              icon: const Icon(Icons.save),
              label: Text(
                _editingStudentId == null ? 'Add Student' : 'Update Student',
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
            Icon(Icons.school, color: busYellow, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Manage Students',
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
            // Fixed: Was SingleChildBulkScrollView
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _glassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _editingStudentId == null
                              ? 'Add New Student'
                              : 'Edit Student Details',
                          textAlign: TextAlign.center,
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
                          _envNumberController,
                          'Enrollment Number',
                          Icons.badge,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        _buildTextField(
                          _emailController,
                          'Email',
                          Icons.email,
                          validator: _emailValidator,
                        ),
                        _buildTextField(
                          _passwordController,
                          _editingStudentId == null
                              ? 'Password'
                              : 'Password (Optional)',
                          Icons.lock,
                          obscureText: true,
                          validator: (v) {
                            if (_editingStudentId == null &&
                                (v == null || v.isEmpty))
                              return 'Required';
                            if (v != null && v.isNotEmpty && v.length < 6)
                              return 'Min 6 chars';
                            return null;
                          },
                        ),
                        _buildTextField(
                          _departmentController,
                          'Department',
                          Icons.school,
                        ),
                        _buildTextField(
                          _mobileController,
                          'Mobile Number',
                          Icons.phone,
                          validator: _phoneValidator,
                        ),
                        _buildTextField(
                          _parentEmailController,
                          'Parent Email',
                          Icons.email,
                          validator: _emailValidator,
                        ),
                        _buildTextField(
                          _parentContactController,
                          'Parent Contact',
                          Icons.phone,
                          validator: _phoneValidator,
                        ),
                        const SizedBox(height: 8),
                        _buildImagePickerField(),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _glassCard(
                  child:
                      _students.isEmpty
                          ? const Center(
                            child: Text(
                              'No students available!',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                          : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStatePropertyAll(
                                busYellow.withAlpha(0x33),
                              ),
                              dataRowColor: WidgetStatePropertyAll(
                                Colors.white.withAlpha(0x0D),
                              ),
                              columnSpacing: 25,
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 60,
                              headingRowHeight: 70,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Name',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Env No.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Email',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Dept',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Mobile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Parent Email',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Parent Contact',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Actions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows:
                                  _students.map((s) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            s['name'] ?? '',
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            s['envNumber'] ?? '',
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            s['email'] ?? '',
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            s['department'] ?? '',
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            s['mobile'] ?? '',
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            s['parentEmail'] ?? '',
                                            style: TextStyle(
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            s['parentContact'] ?? '',
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
                                                    () => _editStudent(s),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed:
                                                    () => _deleteStudent(
                                                      s['_id'],
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

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalid email';
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return '10 digits only';
    return null;
  }
}
