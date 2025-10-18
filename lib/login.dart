// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import './admin/screen/dashboard.dart';
// import './driver/screen/driver_dashboard_screen.dart';
// import './student/screen/dashboard.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _isObscure = true;
//   bool _isLoading = false;
//   String? _selectedUserType;
//   bool _isAdmin = false;

//   final Map<String, String> _loginUrls = {
//     'Admin': 'http://192.168.31.104:5000/api/admin/auth/login',
//     'Driver': 'http://192.168.31.104:5000/api/drivers/login',
//     'Student': 'http://192.168.31.104:5000/api/students/login',
//   };

//   bool isAdminEmail(String email) {
//     return email.endsWith('@campusadmin.com') || email.contains('admin');
//   }

//   void _checkEmail() {
//     final email = _emailController.text.trim();
//     setState(() {
//       _isAdmin = isAdminEmail(email);
//       if (_isAdmin) {
//         _selectedUserType = null;
//       } else {
//         _selectedUserType ??= 'Student';
//       }
//     });
//   }

//   Future<void> _login() async {
//     if (!_isAdmin && _selectedUserType == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Please select user type')));
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     final String loginUrl =
//         _isAdmin ? _loginUrls['Admin']! : _loginUrls[_selectedUserType!]!;

//     try {
//       final response = await http
//           .post(
//             Uri.parse(loginUrl),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({
//               'email': _emailController.text.trim(),
//               'password': _passwordController.text.trim(),
//             }),
//           )
//           .timeout(const Duration(seconds: 10));

//       print('Login response status: ${response.statusCode}');
//       print('Login response body: ${response.body}');

//       setState(() {
//         _isLoading = false;
//       });

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Login successful as ${_isAdmin ? "Admin" : _selectedUserType}!',
//             ),
//           ),
//         );

//         // Store driverId in SharedPreferences for Driver role
//         if (_selectedUserType == 'Driver') {
//           final driverId = data['driver']['id'] ?? '';
//           if (driverId.isEmpty) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Invalid driver ID received')),
//             );
//             return;
//           }
//           final prefs = await SharedPreferences.getInstance();
//           await prefs.setString('driverId', driverId);
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (context) => DriverDashboardScreen(
//                     driverName: data['driver']['name'] ?? 'Unknown',
//                     driverId: driverId,
//                   ),
//             ),
//           );
//         } else if (_isAdmin) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const DashboardScreen()),
//           );
//         } else if (_selectedUserType == 'Student') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (context) => StudentDashboardScreen(
//                     studentName: data['student']['name'] ?? 'Unknown',
//                     studentEmail: data['student']['email'] ?? '',
//                     envNumber: data['student']['envNumber'] ?? '',
//                   ),
//             ),
//           );
//         }
//       } else {
//         final errorMessage =
//             jsonDecode(response.body)['message'] ?? 'Login failed';
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(errorMessage)));
//       }
//     } catch (error) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error during login: $error')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           Image.asset('assets/images/campus_bus.jpg', fit: BoxFit.cover),
//           Container(color: Colors.black.withOpacity(0.5)),
//           Center(
//             child: Container(
//               width: 340,
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 16,
//                     spreadRadius: 2,
//                   ),
//                 ],
//                 border: Border.all(color: Colors.white.withOpacity(0.5)),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Campus Bus',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _emailController,
//                     onChanged: (value) => _checkEmail(),
//                     decoration: InputDecoration(
//                       labelText: 'Email',
//                       labelStyle: const TextStyle(color: Colors.white),
//                       prefixIcon: const Icon(Icons.email, color: Colors.white),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _passwordController,
//                     obscureText: _isObscure,
//                     decoration: InputDecoration(
//                       labelText: 'Password',
//                       labelStyle: const TextStyle(color: Colors.white),
//                       prefixIcon: const Icon(Icons.lock, color: Colors.white),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _isObscure ? Icons.visibility_off : Icons.visibility,
//                           color: Colors.white,
//                         ),
//                         onPressed:
//                             () => setState(() => _isObscure = !_isObscure),
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                   const SizedBox(height: 20),
//                   if (!_isAdmin)
//                     DropdownButtonFormField<String>(
//                       value: _selectedUserType,
//                       dropdownColor: Colors.black,
//                       items:
//                           ['Driver', 'Student'].map((role) {
//                             return DropdownMenuItem<String>(
//                               value: role,
//                               child: Text(
//                                 role,
//                                 style: const TextStyle(color: Colors.white),
//                               ),
//                             );
//                           }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedUserType = value;
//                         });
//                       },
//                       decoration: InputDecoration(
//                         labelText: 'Select User Type',
//                         labelStyle: const TextStyle(color: Colors.white),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 24),
//                   ElevatedButton(
//                     onPressed: _isLoading ? null : _login,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       backgroundColor: Colors.transparent,
//                       shadowColor: Colors.transparent,
//                       elevation: 0,
//                     ),
//                     child:
//                         _isLoading
//                             ? const CircularProgressIndicator(
//                               color: Colors.white,
//                             )
//                             : Ink(
//                               decoration: BoxDecoration(
//                                 gradient: const LinearGradient(
//                                   colors: [Colors.purple, Colors.deepPurple],
//                                 ),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Container(
//                                 alignment: Alignment.center,
//                                 height: 50,
//                                 child: const Text(
//                                   'Login',
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               ),
//                             ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ✅ Modified version of your LoginScreen with type-safe JSON extraction and Parent login support
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './admin/screen/dashboard.dart';
import './driver/screen/driver_dashboard_screen.dart';
import './student/screen/dashboard.dart';
import './parent/screen/parent_dashboard_screen.dart';
import 'config/api_config.dart'; // ✅ Import centralized URL

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ✅ Centralized URLs using ApiConfig.baseUrl
    final roleApis = [
      {
        'role': 'Admin',
        'url': '${ApiConfig.baseUrl}/admin/auth/login',
        'body': {'email': email, 'password': password},
      },
      {
        'role': 'Driver',
        'url': '${ApiConfig.baseUrl}/drivers/login',
        'body': {'email': email, 'password': password},
      },
      {
        'role': 'Student',
        'url': '${ApiConfig.baseUrl}/students/login',
        'body': {'email': email, 'password': password},
      },
      {
        'role': 'Parent',
        'url': '${ApiConfig.baseUrl}/students/parent-login',
        'body': {'parentEmail': email, 'parentContact': password},
      },
    ];

    for (final api in roleApis) {
      try {
        final res = await http.post(
          Uri.parse(api['url'] as String),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(api['body']),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final role = api['role'];

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Login successful as $role')));

          if (role == 'Admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          } else if (role == 'Driver') {
            final driver = data['driver'] ?? {};
            final driverId = (driver['id'] ?? '').toString();
            final driverName = (driver['name'] ?? 'Unknown').toString();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('driverId', driverId);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => DriverDashboardScreen(
                      driverName: driverName,
                      driverId: driverId,
                    ),
              ),
            );
          } else if (role == 'Student') {
            final student = data['student'] ?? {};
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => StudentDashboardScreen(
                      studentName: (student['name'] ?? 'Unknown').toString(),
                      studentEmail: (student['email'] ?? '').toString(),
                      envNumber: (student['envNumber'] ?? '').toString(),
                    ),
              ),
            );
          } else if (role == 'Parent') {
            final parentEmail = email;
            final parentContact = password;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ParentDashboardScreen(
                      parentContact: parentContact,
                      parentEmail: parentEmail,
                    ),
              ),
            );
          }

          return;
        }
      } catch (e) {
        // Ignore error, continue checking next role
      }
    }

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login failed: Invalid credentials')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/campus_bus.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.5)),
          Center(
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Campus Bus',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.email, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed:
                            () => setState(() => _isObscure = !_isObscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.purple, Colors.deepPurple],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                height: 50,
                                child: const Text(
                                  'Login',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
