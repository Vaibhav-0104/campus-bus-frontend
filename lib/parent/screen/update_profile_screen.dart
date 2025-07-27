import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

/// Configuration class for profile update
class ProfileConfig {
  static const String screenTitle = 'Update Profile';
  static const String headerTitle = 'Profile Information';
}

/// Theme-related constants
class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color backgroundColor = Color(
    0xFF0D47A1,
  ); // Deep blue (Colors.blue[900])
  static const Color accentColor = Colors.lightBlueAccent;
  static const Color successColor = Colors.green;
  static const Color pendingColor = Colors.orange;
  static const Color absentColor = Colors.redAccent;
  static const Color cardBackground = Color(
    0xFF1E2A44,
  ); // Darker blue for cards
  static const double cardBorderRadius = 20.0;
  static const double blurSigma = 10.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double elevation = 8.0;
  static const double iconSize = 28.0;
  static const double avatarRadius = 30.0;
}

/// Reusable text field widget
class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing / 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(4, 4),
            blurRadius: AppTheme.blurSigma,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            offset: const Offset(-4, -4),
            blurRadius: AppTheme.blurSigma,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.blurSigma,
            sigmaY: AppTheme.blurSigma,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.cardPadding,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26), // 0.1 * 255 = 26
              border: Border.all(
                color: Colors.white.withAlpha(76),
                width: 1.5,
              ), // 0.3 * 255 = 76
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.white.withAlpha(204),
                ), // 0.8 * 255 = 204
                prefixIcon: Icon(icon, color: AppTheme.accentColor),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
              validator: validator,
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen to update parent and child profile information
class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parentNameController = TextEditingController(text: 'Jane Doe');
  final _parentPhoneController = TextEditingController(text: '+1234567890');
  final _childNameController = TextEditingController(text: 'John Doe');
  final _childClassController = TextEditingController(text: '5A');

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _childNameController.dispose();
    _childClassController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('parent_name', _parentNameController.text);
        await prefs.setString('parent_phone', _parentPhoneController.text);
        await prefs.setString('child_name', _childNameController.text);
        await prefs.setString('child_class', _childClassController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: AppTheme.absentColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(ProfileConfig.screenTitle),
        backgroundColor: AppTheme.backgroundColor.withAlpha(
          76,
        ), // 0.3 * 255 = 76
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppTheme.blurSigma,
              sigmaY: AppTheme.blurSigma,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.backgroundColor, // Solid deep blue background
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(AppTheme.cardPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.backgroundColor, Colors.blue[600]!],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardBorderRadius,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(4, 4),
                            blurRadius: AppTheme.blurSigma,
                          ),
                        ],
                      ),
                      child: Text(
                        ProfileConfig.headerTitle,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing * 1.5),
                    // Parent Information
                    Text(
                      'Parent Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    ProfileTextField(
                      controller: _parentNameController,
                      label: 'Parent Name',
                      icon: Icons.person,
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Please enter parent name'
                                  : null,
                    ),
                    ProfileTextField(
                      controller: _parentPhoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Please enter phone number'
                                  : null,
                    ),
                    const SizedBox(height: AppTheme.spacing * 1.5),
                    // Child Information
                    Text(
                      'Child Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing),
                    ProfileTextField(
                      controller: _childNameController,
                      label: 'Child Name',
                      icon: Icons.child_care,
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter child name' : null,
                    ),
                    ProfileTextField(
                      controller: _childClassController,
                      label: 'Class',
                      icon: Icons.school,
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter class' : null,
                    ),
                    const SizedBox(height: AppTheme.spacing * 1.5),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.absentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.cardBorderRadius / 2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.cardBorderRadius / 2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
