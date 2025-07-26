// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:ui'; // Required for ImageFilter for blur effects

// const String studentApiUrl = 'http://192.168.31.104:5000/api/students';

// class ManageStudentDetailsScreen extends StatefulWidget {
//   const ManageStudentDetailsScreen({super.key});

//   @override
//   State<ManageStudentDetailsScreen> createState() =>
//       _ManageStudentDetailsScreenState();
// }

// class _ManageStudentDetailsScreenState
//     extends State<ManageStudentDetailsScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _envNumberController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _departmentController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _parentContactController =
//       TextEditingController();

//   File? _selectedImage;
//   Uint8List? _selectedImageBytes;
//   String? _editingStudentId;
//   List<Map<String, dynamic>> _students = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchStudents();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _envNumberController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _departmentController.dispose();
//     _mobileController.dispose();
//     _parentContactController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchStudents() async {
//     try {
//       final response = await http.get(Uri.parse(studentApiUrl));
//       if (response.statusCode == 200) {
//         setState(() {
//           _students = List<Map<String, dynamic>>.from(
//             jsonDecode(response.body),
//           );
//         });
//       } else {
//         _showSnackBar('Failed to load students: ${response.statusCode}');
//       }
//     } catch (e) {
//       _showSnackBar('Error fetching students: $e');
//     }
//   }

//   Future<void> _pickImage() async {
//     final source = await _showImageSourceDialog();
//     if (source == null) return;

//     final ImagePicker picker = ImagePicker();
//     final XFile? pickedFile = await picker.pickImage(
//       source: source,
//       imageQuality: 80,
//     );

//     if (pickedFile != null) {
//       if (kIsWeb) {
//         final bytes = await pickedFile.readAsBytes();
//         setState(() {
//           _selectedImageBytes = bytes;
//           _selectedImage = null;
//         });
//       } else {
//         setState(() {
//           _selectedImage = File(pickedFile.path);
//           _selectedImageBytes = null;
//         });
//       }
//     }
//   }

//   Future<ImageSource?> _showImageSourceDialog() async {
//     return showDialog<ImageSource>(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             backgroundColor: Colors.blue.shade800.withOpacity(
//               0.8,
//             ), // Liquid glass dialog background
//             title: const Text(
//               'Select Image Source',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
//               ),
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 ListTile(
//                   leading: Icon(Icons.camera, color: Colors.lightBlueAccent),
//                   title: const Text(
//                     'Camera',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   onTap: () => Navigator.of(context).pop(ImageSource.camera),
//                 ),
//                 ListTile(
//                   leading: Icon(
//                     Icons.photo_library,
//                     color: Colors.lightBlueAccent,
//                   ),
//                   title: const Text(
//                     'Gallery',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   onTap: () => Navigator.of(context).pop(ImageSource.gallery),
//                 ),
//               ],
//             ),
//           ),
//     );
//   }

//   Future<void> _saveStudent() async {
//     if (!_formKey.currentState!.validate()) return;

//     final uri =
//         _editingStudentId == null
//             ? Uri.parse(studentApiUrl)
//             : Uri.parse('$studentApiUrl/$_editingStudentId');

//     final request = http.MultipartRequest(
//       _editingStudentId == null ? 'POST' : 'PUT',
//       uri,
//     );

//     // Add image if selected
//     if (_selectedImage != null && !kIsWeb) {
//       request.files.add(
//         await http.MultipartFile.fromPath('image', _selectedImage!.path),
//       );
//     } else if (_selectedImageBytes != null && kIsWeb) {
//       request.files.add(
//         http.MultipartFile.fromBytes(
//           'image',
//           _selectedImageBytes!,
//           filename: 'image.jpg',
//         ),
//       );
//     }

//     // Add form fields
//     request.fields['name'] = _nameController.text.trim();
//     request.fields['envNumber'] = _envNumberController.text.trim();
//     request.fields['email'] = _emailController.text.trim();
//     request.fields['password'] = _passwordController.text.trim();
//     request.fields['department'] = _departmentController.text.trim();
//     request.fields['mobile'] = _mobileController.text.trim();
//     request.fields['parentContact'] = _parentContactController.text.trim();

//     try {
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//       if (response.statusCode == 201 || response.statusCode == 200) {
//         _showSnackBar(
//           'Student ${_editingStudentId == null ? 'added' : 'updated'} successfully!',
//           isSuccess: true,
//         );
//         _clearForm();
//         _fetchStudents();
//       } else {
//         _showSnackBar('Failed to save student: $responseBody');
//       }
//     } catch (e) {
//       _showSnackBar('Error saving student: $e');
//     }
//   }

//   void _clearForm() {
//     setState(() {
//       _editingStudentId = null;
//       _nameController.clear();
//       _envNumberController.clear();
//       _emailController.clear();
//       _passwordController.clear();
//       _departmentController.clear();
//       _mobileController.clear();
//       _parentContactController.clear();
//       _selectedImage = null;
//       _selectedImageBytes = null;
//     });
//   }

//   void _showSnackBar(String message, {bool isSuccess = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isSuccess ? Colors.green : Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _editStudent(Map<String, dynamic> student) {
//     setState(() {
//       _editingStudentId = student['_id'];
//       _nameController.text = student['name'] ?? '';
//       _envNumberController.text = student['envNumber'] ?? '';
//       _emailController.text = student['email'] ?? '';
//       _passwordController.text = ''; // Do not pre-fill password for security
//       _departmentController.text = student['department'] ?? '';
//       _mobileController.text = student['mobile'] ?? '';
//       _parentContactController.text = student['parentContact'] ?? '';
//       _selectedImage = null;
//       _selectedImageBytes = null;
//       // You might want to load the existing image if it's available from the backend
//       // and display it, but sending it back to the server on update is complex
//       // without re-selecting it or having a direct image URL.
//     });
//   }

//   Future<void> _deleteStudent(String id) async {
//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           backgroundColor: Colors.blue.shade800.withOpacity(0.8),
//           title: const Text(
//             'Confirm Deletion',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
//             ),
//           ),
//           content: const Text(
//             'Are you sure you want to delete this student record?',
//             style: TextStyle(color: Colors.white70, fontSize: 16),
//           ),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () => Navigator.of(dialogContext).pop(),
//               child: Text(
//                 'Cancel',
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.8),
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.of(dialogContext).pop(); // Dismiss dialog
//                 try {
//                   final response = await http.delete(
//                     Uri.parse('$studentApiUrl/$id'),
//                   );
//                   if (response.statusCode == 200) {
//                     _showSnackBar(
//                       'Student deleted successfully!',
//                       isSuccess: true,
//                     );
//                     _fetchStudents();
//                   } else {
//                     _showSnackBar(
//                       'Failed to delete student: ${response.statusCode}',
//                     );
//                   }
//                 } catch (e) {
//                   _showSnackBar('Error deleting student: $e');
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.redAccent,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 10,
//                 ),
//               ),
//               child: const Text(
//                 'Delete',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar:
//           true, // Extend body behind app bar for full gradient
//       appBar: AppBar(
//         title: const Text(
//           'Manage Student Details',
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         backgroundColor: Colors.blue.shade800.withOpacity(
//           0.3,
//         ), // Liquid glass app bar
//         centerTitle: true,
//         elevation: 0, // Remove default shadow
//         iconTheme: const IconThemeData(
//           color: Colors.white,
//         ), // White back button
//         flexibleSpace: ClipRect(
//           child: BackdropFilter(
//             filter: ImageFilter.blur(
//               sigmaX: 10,
//               sigmaY: 10,
//             ), // Blur effect for app bar
//             child: Container(
//               color:
//                   Colors
//                       .transparent, // Transparent to show blurred content behind
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Colors.blue.shade900,
//               Colors.blue.shade700,
//               Colors.blue.shade500,
//             ], // Blue themed gradient background
//             stops: const [0.0, 0.5, 1.0],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: EdgeInsets.only(
//             top:
//                 AppBar().preferredSize.height +
//                 MediaQuery.of(context).padding.top +
//                 16,
//             left: 16.0,
//             right: 16.0,
//             bottom: 16.0,
//           ),
//           child: Column(
//             children: [
//               _buildFormCard(),
//               const SizedBox(height: 30),
//               _buildStudentTable(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFormCard() {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(
//         25,
//       ), // Rounded corners for liquid glass card
//       child: BackdropFilter(
//         filter: ImageFilter.blur(
//           sigmaX: 20.0,
//           sigmaY: 20.0,
//         ), // Stronger blur for the card
//         child: Container(
//           padding: const EdgeInsets.all(
//             25,
//           ), // Increased padding inside the card
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.blueGrey.shade300.withOpacity(0.15),
//                 Colors.blueGrey.shade700.withOpacity(0.15),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(25),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.3),
//             ), // More visible border
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3), // Stronger shadow
//                 blurRadius: 30, // Increased blur
//                 spreadRadius: 5, // Increased spread
//                 offset: const Offset(10, 10),
//               ),
//               BoxShadow(
//                 color: Colors.white.withOpacity(0.15), // Inner light glow
//                 blurRadius: 15,
//                 spreadRadius: 2,
//                 offset: const Offset(-8, -8),
//               ),
//             ],
//           ),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 Text(
//                   _editingStudentId == null
//                       ? "Add New Student"
//                       : "Edit Student Details",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 _buildTextField(_nameController, 'Full Name', Icons.person),
//                 _buildTextField(
//                   _envNumberController,
//                   'Enrollment Number',
//                   Icons.format_list_numbered,
//                 ),
//                 _buildTextField(
//                   _emailController,
//                   'Email',
//                   Icons.email,
//                   validator: _emailValidator,
//                 ),
//                 _buildTextField(
//                   _passwordController,
//                   'Password',
//                   Icons.lock,
//                   obscureText: true,
//                 ),
//                 _buildTextField(
//                   _departmentController,
//                   'Department',
//                   Icons.school,
//                 ),
//                 _buildTextField(
//                   _mobileController,
//                   'Mobile Number',
//                   Icons.phone,
//                   keyboardType: TextInputType.phone,
//                   validator: _phoneValidator,
//                 ),
//                 _buildTextField(
//                   _parentContactController,
//                   'Parent Contact',
//                   Icons.contacts,
//                   keyboardType: TextInputType.phone,
//                   validator: _phoneValidator,
//                 ),
//                 const SizedBox(height: 10),
//                 _buildImagePicker(),
//                 const SizedBox(height: 20),
//                 _buildActionButtons(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         Expanded(
//           child: Container(
//             margin: const EdgeInsets.symmetric(horizontal: 5),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(30),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.blue.shade800.withOpacity(0.4),
//                   blurRadius: 20,
//                   spreadRadius: 2,
//                   offset: const Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(30),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
//                 child: ElevatedButton(
//                   onPressed: _saveStudent,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue.shade600.withOpacity(0.5),
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                       side: BorderSide(
//                         color: Colors.white.withOpacity(0.3),
//                         width: 1.5,
//                       ),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: Text(
//                     _editingStudentId == null
//                         ? 'Add Student'
//                         : 'Update Student',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         Expanded(
//           child: Container(
//             margin: const EdgeInsets.symmetric(horizontal: 5),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(30),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.shade800.withOpacity(0.4),
//                   blurRadius: 20,
//                   spreadRadius: 2,
//                   offset: const Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(30),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
//                 child: ElevatedButton(
//                   onPressed: _clearForm,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey.shade600.withOpacity(0.5),
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                       side: BorderSide(
//                         color: Colors.white.withOpacity(0.3),
//                         width: 1.5,
//                       ),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: const Text(
//                     'Clear',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField(
//     TextEditingController controller,
//     String label,
//     IconData icon, { // Added IconData parameter
//     bool obscureText = false,
//     TextInputType keyboardType = TextInputType.text, // Added keyboardType
//     String? Function(String?)? validator,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: TextFormField(
//         controller: controller,
//         obscureText: obscureText,
//         keyboardType: keyboardType, // Apply keyboardType
//         style: const TextStyle(color: Colors.white, fontSize: 16),
//         decoration: InputDecoration(
//           prefixIcon: Icon(
//             icon,
//             color: Colors.lightBlueAccent,
//             size: 24,
//           ), // Use icon
//           labelText: label,
//           labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
//           filled: true,
//           fillColor: Colors.white.withOpacity(0.08),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: BorderSide(
//               color: Colors.white.withOpacity(0.3),
//               width: 1.5,
//             ),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: const BorderSide(
//               color: Colors.lightBlueAccent,
//               width: 2.5,
//             ),
//           ),
//         ),
//         validator:
//             validator ??
//             (value) => value!.isEmpty ? 'Please enter $label' : null,
//       ),
//     );
//   }

//   Widget _buildImagePicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(15),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.blue.shade800.withOpacity(0.4),
//                 blurRadius: 15,
//                 spreadRadius: 1,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(15),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
//               child: ElevatedButton.icon(
//                 onPressed: _pickImage,
//                 icon: const Icon(Icons.image, color: Colors.white),
//                 label: const Text(
//                   'Select Image',
//                   style: TextStyle(color: Colors.white, fontSize: 16),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue.shade600.withOpacity(
//                     0.5,
//                   ), // Match button style
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 15,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                     side: BorderSide(
//                       color: Colors.white.withOpacity(0.3),
//                       width: 1.5,
//                     ),
//                   ),
//                   elevation: 0,
//                 ),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         if (_selectedImage != null || _selectedImageBytes != null)
//           ClipRRect(
//             borderRadius: BorderRadius.circular(15),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(15),
//                   border: Border.all(color: Colors.white.withOpacity(0.2)),
//                 ),
//                 padding: const EdgeInsets.all(5),
//                 child:
//                     kIsWeb
//                         ? Image.memory(
//                           _selectedImageBytes!,
//                           width: 100,
//                           height: 100,
//                           fit: BoxFit.cover,
//                         )
//                         : Image.file(
//                           _selectedImage!,
//                           width: 100,
//                           height: 100,
//                           fit: BoxFit.cover,
//                         ),
//               ),
//             ),
//           ),
//         const SizedBox(height: 8),
//         Text(
//           'Please upload a clear face image for recognition',
//           style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
//         ),
//       ],
//     );
//   }

//   Widget _buildStudentTable() {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(25),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.blueGrey.shade300.withOpacity(0.15),
//                 Colors.blueGrey.shade700.withOpacity(0.15),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(25),
//             border: Border.all(color: Colors.white.withOpacity(0.3)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3),
//                 blurRadius: 30,
//                 spreadRadius: 5,
//                 offset: const Offset(10, 10),
//               ),
//               BoxShadow(
//                 color: Colors.white.withOpacity(0.15),
//                 blurRadius: 15,
//                 spreadRadius: 2,
//                 offset: const Offset(-8, -8),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child:
//                 _students.isEmpty
//                     ? const Center(
//                       child: Text(
//                         'No student details available!',
//                         style: TextStyle(fontSize: 18, color: Colors.white70),
//                       ),
//                     )
//                     : SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: DataTable(
//                         headingRowColor:
//                             MaterialStateProperty.resolveWith<Color?>(
//                               (Set<MaterialState> states) =>
//                                   Colors.blue.shade800.withOpacity(0.6),
//                             ),
//                         dataRowColor: MaterialStateProperty.resolveWith<Color?>(
//                           (Set<MaterialState> states) =>
//                               Colors.white.withOpacity(0.05),
//                         ),
//                         columnSpacing: 25,
//                         dataRowHeight: 60,
//                         headingRowHeight: 70,
//                         columns: const [
//                           DataColumn(
//                             label: Text(
//                               'Name',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ),
//                           DataColumn(
//                             label: Text(
//                               'Env Number',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ),
//                           DataColumn(
//                             label: Text(
//                               'Email',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ),
//                           DataColumn(
//                             label: Text(
//                               'Department',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ),
//                           DataColumn(
//                             label: Text(
//                               'Mobile',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ),
//                           DataColumn(
//                             label: Text(
//                               'Parent Contact',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ),
//                           DataColumn(
//                             label: Text(
//                               'Actions',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ),
//                         ],
//                         rows:
//                             _students.map((student) {
//                               return DataRow(
//                                 cells: [
//                                   DataCell(
//                                     Text(
//                                       student['name'] ?? '',
//                                       style: TextStyle(color: Colors.white70),
//                                     ),
//                                   ),
//                                   DataCell(
//                                     Text(
//                                       student['envNumber'] ?? '',
//                                       style: TextStyle(color: Colors.white70),
//                                     ),
//                                   ),
//                                   DataCell(
//                                     Text(
//                                       student['email'] ?? '',
//                                       style: TextStyle(color: Colors.white70),
//                                     ),
//                                   ),
//                                   DataCell(
//                                     Text(
//                                       student['department'] ?? '',
//                                       style: TextStyle(color: Colors.white70),
//                                     ),
//                                   ),
//                                   DataCell(
//                                     Text(
//                                       student['mobile'] ?? '',
//                                       style: TextStyle(color: Colors.white70),
//                                     ),
//                                   ),
//                                   DataCell(
//                                     Text(
//                                       student['parentContact'] ?? '',
//                                       style: TextStyle(color: Colors.white70),
//                                     ),
//                                   ),
//                                   DataCell(
//                                     Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         IconButton(
//                                           icon: const Icon(
//                                             Icons.edit,
//                                             color: Colors.lightBlueAccent,
//                                           ),
//                                           onPressed:
//                                               () => _editStudent(student),
//                                         ),
//                                         IconButton(
//                                           icon: const Icon(
//                                             Icons.delete,
//                                             color: Colors.redAccent,
//                                           ),
//                                           onPressed:
//                                               () => _deleteStudent(
//                                                 student['_id'],
//                                               ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             }).toList(),
//                       ),
//                     ),
//           ),
//         ),
//       ),
//     );
//   }

//   String? _emailValidator(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Please enter email';
//     }
//     final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
//     if (!emailRegex.hasMatch(value)) {
//       return 'Please enter a valid email';
//     }
//     return null;
//   }

//   String? _phoneValidator(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Please enter phone number';
//     }
//     final phoneRegex = RegExp(r'^\d{10}$');
//     if (!phoneRegex.hasMatch(value)) {
//       return 'Please enter a valid 10-digit phone number';
//     }
//     return null;
//   }
// }

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:ui'; // Required for ImageFilter for blur effects

const String studentApiUrl = 'http://192.168.31.104:5000/api/students';

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.blue.shade800.withOpacity(
              0.8,
            ), // Liquid glass dialog background
            title: const Text(
              'Select Image Source',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera, color: Colors.lightBlueAccent),
                  title: const Text(
                    'Camera',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: Colors.lightBlueAccent,
                  ),
                  title: const Text(
                    'Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
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
    if (_editingStudentId == null ||
        _passwordController.text.trim().isNotEmpty) {
      request.fields['password'] = _passwordController.text.trim();
    }
    request.fields['department'] = _departmentController.text.trim();
    request.fields['mobile'] = _mobileController.text.trim();
    request.fields['parentEmail'] = _parentEmailController.text.trim();
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
      _passwordController.text = ''; // Do not pre-fill password for security
      _departmentController.text = student['department'] ?? '';
      _mobileController.text = student['mobile'] ?? '';
      _parentEmailController.text = student['parentEmail'] ?? '';
      _parentContactController.text = student['parentContact'] ?? '';
      _selectedImage = null;
      _selectedImageBytes = null;
      // You might want to load the existing image if it's available from the backend
      // and display it, but sending it back to the server on update is complex
      // without re-selecting it or having a direct image URL.
    });
  }

  Future<void> _deleteStudent(String id) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.blue.shade800.withOpacity(0.8),
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this student record?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                try {
                  final response = await http.delete(
                    Uri.parse('$studentApiUrl/$id'),
                  );
                  if (response.statusCode == 200) {
                    _showSnackBar(
                      'Student deleted successfully!',
                      isSuccess: true,
                    );
                    _fetchStudents();
                  } else {
                    _showSnackBar(
                      'Failed to delete student: ${response.statusCode}',
                    );
                  }
                } catch (e) {
                  _showSnackBar('Error deleting student: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Extend body behind app bar for full gradient
      appBar: AppBar(
        title: const Text(
          'Manage Student Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800.withOpacity(
          0.3,
        ), // Liquid glass app bar
        centerTitle: true,
        elevation: 0, // Remove default shadow
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // White back button
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ), // Blur effect for app bar
            child: Container(
              color:
                  Colors
                      .transparent, // Transparent to show blurred content behind
            ),
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
            ], // Blue themed gradient background
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
              _buildStudentTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        25,
      ), // Rounded corners for liquid glass card
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20.0,
          sigmaY: 20.0,
        ), // Stronger blur for the card
        child: Container(
          padding: const EdgeInsets.all(
            25,
          ), // Increased padding inside the card
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
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ), // More visible border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3), // Stronger shadow
                blurRadius: 30, // Increased blur
                spreadRadius: 5, // Increased spread
                offset: const Offset(10, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.15), // Inner light glow
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
                  _editingStudentId == null
                      ? "Add New Student"
                      : "Edit Student Details",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(_nameController, 'Full Name', Icons.person),
                _buildTextField(
                  _envNumberController,
                  'Enrollment Number',
                  Icons.format_list_numbered,
                ),
                _buildTextField(
                  _emailController,
                  'Email',
                  Icons.email,
                  validator: _emailValidator,
                ),
                _buildTextField(
                  _passwordController,
                  'Password',
                  Icons.lock,
                  obscureText: true,
                  validator: (value) {
                    if (_editingStudentId == null &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter password';
                    }
                    return null; // Do not validate password if editing and left blank
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
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                ),
                _buildTextField(
                  _parentEmailController,
                  'Parent Email',
                  Icons.email_outlined,
                  validator: _emailValidator,
                ),
                _buildTextField(
                  _parentContactController,
                  'Parent Contact',
                  Icons.contacts,
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                ),
                const SizedBox(height: 10),
                _buildImagePicker(),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
                  onPressed: _saveStudent,
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
                    _editingStudentId == null
                        ? 'Add Student'
                        : 'Update Student',
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
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, { // Added IconData parameter
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text, // Added keyboardType
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType, // Apply keyboardType
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.lightBlueAccent,
            size: 24,
          ), // Use icon
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade800.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image, color: Colors.white),
                label: const Text(
                  'Select Image',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600.withOpacity(
                    0.5,
                  ), // Match button style
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedImage != null || _selectedImageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.all(5),
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
        const SizedBox(height: 8),
        Text(
          'Please upload a clear face image for recognition',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildStudentTable() {
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
                _students.isEmpty
                    ? const Center(
                      child: Text(
                        'No student details available!',
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
                        columnSpacing: 25,
                        dataRowHeight: 60,
                        headingRowHeight: 70,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Name',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Env Number',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Department',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Mobile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Parent Email',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Parent Contact',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                        rows:
                            _students.map((student) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      student['name'] ?? '',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      student['envNumber'] ?? '',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      student['email'] ?? '',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      student['department'] ?? '',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      student['mobile'] ?? '',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      student['parentEmail'] ?? '',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      student['parentContact'] ?? '',
                                      style: TextStyle(color: Colors.white70),
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
                                          onPressed:
                                              () => _editStudent(student),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed:
                                              () => _deleteStudent(
                                                student['_id'],
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
