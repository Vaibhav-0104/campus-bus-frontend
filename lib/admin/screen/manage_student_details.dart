import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

const String studentApiUrl =
    'https://campus-bus-backend.onrender.com/api/students';

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
  final TextEditingController _parentContactController =
      TextEditingController();

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _editingStudentId;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await http.get(Uri.parse(studentApiUrl));
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

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

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
          (context) => AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
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
            ? Uri.parse(studentApiUrl)
            : Uri.parse('$studentApiUrl/$_editingStudentId');

    final request = http.MultipartRequest(
      _editingStudentId == null ? 'POST' : 'PUT',
      uri,
    );

    // Add image if selected
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

    // Add form fields
    request.fields['name'] = _nameController.text.trim();
    request.fields['envNumber'] = _envNumberController.text.trim();
    request.fields['email'] = _emailController.text.trim();
    request.fields['password'] = _passwordController.text.trim();
    request.fields['department'] = _departmentController.text.trim();
    request.fields['mobile'] = _mobileController.text.trim();
    request.fields['parentContact'] = _parentContactController.text.trim();

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
        _showSnackBar('Failed to save student: $responseBody');
      }
    } catch (e) {
      _showSnackBar('Error saving student: $e');
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
      _passwordController.text = student['password'] ?? '';
      _departmentController.text = student['department'] ?? '';
      _mobileController.text = student['mobile'] ?? '';
      _parentContactController.text = student['parentContact'] ?? '';
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  Future<void> _deleteStudent(String id) async {
    try {
      final response = await http.delete(Uri.parse('$studentApiUrl/$id'));
      if (response.statusCode == 200) {
        _showSnackBar('Student deleted successfully!', isSuccess: true);
        _fetchStudents();
      } else {
        _showSnackBar('Failed to delete student: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error deleting student: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[800],
        title: const Text(
          'Manage Student Details',
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
              _buildFormCard(),
              const SizedBox(height: 30),
              _buildStudentTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.indigo[800]!, width: 2),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'Full Name'),
              _buildTextField(_envNumberController, 'Env Number'),
              _buildTextField(
                _emailController,
                'Email',
                validator: _emailValidator,
              ),
              _buildTextField(
                _passwordController,
                'Password',
                obscureText: true,
              ),
              _buildTextField(_departmentController, 'Department'),
              _buildTextField(
                _mobileController,
                'Mobile Number',
                validator: _phoneValidator,
              ),
              _buildTextField(
                _parentContactController,
                'Parent Contact',
                validator: _phoneValidator,
              ),
              _buildImagePicker(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _saveStudent,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[700],
            foregroundColor: Colors.white,
          ),
          child: Text(
            _editingStudentId == null ? 'Add Student' : 'Update Student',
          ),
        ),
        ElevatedButton(
          onPressed: _clearForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[400],
            foregroundColor: Colors.black,
          ),
          child: const Text('Clear'),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
            validator ??
            (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Select Image'),
            ),
            const SizedBox(width: 10),
            if (_selectedImage != null && !kIsWeb)
              Image.file(
                _selectedImage!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            if (_selectedImageBytes != null && kIsWeb)
              Image.memory(
                _selectedImageBytes!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Please upload a clear face image for recognition',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStudentTable() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child:
            _students.isEmpty
                ? const Center(
                  child: Text(
                    'No student details available!',
                    style: TextStyle(fontSize: 18),
                  ),
                )
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Env Number')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Department')),
                      DataColumn(label: Text('Mobile')),
                      DataColumn(label: Text('Parent Contact')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows:
                        _students.map((student) {
                          return DataRow(
                            cells: [
                              DataCell(Text(student['name'] ?? '')),
                              DataCell(Text(student['envNumber'] ?? '')),
                              DataCell(Text(student['email'] ?? '')),
                              DataCell(Text(student['department'] ?? '')),
                              DataCell(Text(student['mobile'] ?? '')),
                              DataCell(Text(student['parentContact'] ?? '')),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.indigo[700],
                                      ),
                                      onPressed: () => _editStudent(student),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.indigo[700],
                                      ),
                                      onPressed:
                                          () => _deleteStudent(student['_id']),
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

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }
}
