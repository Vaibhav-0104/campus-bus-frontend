import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'dart:developer' as developer;

/// Configuration class for contact information
class ContactConfig {
  static const String screenTitle = 'Contact & Support';
  static const String headerTitle = 'Contact Information';
  static const String transportAdminPhone = '+91 8320810061';
  static const String busDriverPhone = '+91 9723588031';
  static const String emergencyPhone = '+91 9313888538';
}

/// Theme-related constants
class AppTheme {
  static const Color primaryColor = Color(0xFF1E88E5); // Bright Blue
  static const Color backgroundColor = Color(0xFF0C1337); // Very Dark Blue
  static const Color accentColor = Color(0xFF80D8FF); // Light Cyan/Blue Accent
  static const Color successColor = Colors.green;
  static const Color pendingColor = Colors.orange;
  static const Color absentColor = Color(0xFFFF5252); // Red for absences
  static const Color cardBackground = Color(
    0xFF16204C,
  ); // Darker Blue for cards
  static const Color iconColor1 = Color(0xFF69F0AE); // Green for icons
  static const Color iconColor2 = Color(0xFFFFC107); // Amber for icons
  static const Color iconColor3 = Color(0xFFFF5252); // Red for icons
  static const double cardBorderRadius = 20.0;
  static const double blurSigma = 12.0; // Aligned with other screens
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
  static const double elevation = 8.0;
  static const double iconSize = 28.0;
}

/// Reusable contact card widget
class ContactCard extends StatelessWidget {
  final String title;
  final String phone;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onCall;
  final VoidCallback onChat;

  const ContactCard({
    super.key,
    required this.title,
    required this.phone,
    required this.icon,
    required this.iconColor,
    required this.onCall,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing / 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(4, 4),
            blurRadius: AppTheme.blurSigma,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
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
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.102), // 26/255
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.298), // 76/255
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: AppTheme.iconSize),
                    const SizedBox(width: AppTheme.spacing / 2),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing / 2),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Phone number copied to clipboard'),
                        backgroundColor: AppTheme.accentColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    'Phone: $phone',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8), // 204/255
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.phone,
                        color: AppTheme.iconColor1,
                        size: AppTheme.iconSize,
                      ),
                      onPressed: onCall,
                      tooltip: 'Call',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chat,
                        color: AppTheme.accentColor,
                        size: AppTheme.iconSize,
                      ),
                      onPressed: onChat,
                      tooltip: 'Chat',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contact and Support screen with improved structure and error handling
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  _ContactSupportScreenState createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  /// Shows confirmation dialog before launching action
  Future<bool> _showConfirmationDialog(String action, String phone) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: AppTheme.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.cardBorderRadius,
                  ),
                ),
                title: Text(
                  'Confirm $action',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'Do you want to $action $phone?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.absentColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Confirm',
                      style: TextStyle(color: AppTheme.accentColor),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  /// Launches phone call with error handling
  Future<void> _launchPhone(String phoneNumber) async {
    if (!await _showConfirmationDialog('call', phoneNumber)) return;

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Initiated call to $phoneNumber'),
              backgroundColor: AppTheme.accentColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'Could not launch phone call';
      }
    } catch (e) {
      developer.log(
        'Error launching phone call to $phoneNumber: $e',
        name: 'ContactSupportScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching phone call: $e'),
            backgroundColor: AppTheme.absentColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Launches SMS chat with error handling
  Future<void> _launchChat(String phoneNumber) async {
    if (!await _showConfirmationDialog('message', phoneNumber)) return;

    final Uri chatUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      if (await canLaunchUrl(chatUri)) {
        await launchUrl(chatUri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opened chat with $phoneNumber'),
              backgroundColor: AppTheme.accentColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw 'Could not launch chat';
      }
    } catch (e) {
      developer.log(
        'Error launching chat with $phoneNumber: $e',
        name: 'ContactSupportScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching chat: $e'),
            backgroundColor: AppTheme.absentColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          ContactConfig.screenTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundColor.withValues(alpha: 0.3),
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
        color: AppTheme.backgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
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
                        colors: [
                          AppTheme.backgroundColor,
                          AppTheme.primaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.cardBorderRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(4, 4),
                          blurRadius: AppTheme.blurSigma,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          offset: const Offset(-4, -4),
                          blurRadius: AppTheme.blurSigma,
                        ),
                      ],
                    ),
                    child: Text(
                      ContactConfig.headerTitle,
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
                  // Contact Cards
                  ContactCard(
                    title: 'Transport Admin',
                    phone: ContactConfig.transportAdminPhone,
                    icon: Icons.admin_panel_settings,
                    iconColor: AppTheme.iconColor2, // Amber for admin
                    onCall:
                        () => _launchPhone(ContactConfig.transportAdminPhone),
                    onChat:
                        () => _launchChat(ContactConfig.transportAdminPhone),
                  ),
                  ContactCard(
                    title: 'Bus Driver',
                    phone: ContactConfig.busDriverPhone,
                    icon: Icons.directions_bus,
                    iconColor: AppTheme.iconColor1, // Green for driver
                    onCall: () => _launchPhone(ContactConfig.busDriverPhone),
                    onChat: () => _launchChat(ContactConfig.busDriverPhone),
                  ),
                  const SizedBox(height: AppTheme.spacing * 1.5),
                  // Emergency Contact Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.absentColor, AppTheme.iconColor3],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.cardBorderRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(4, 4),
                          blurRadius: AppTheme.blurSigma,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          offset: const Offset(-4, -4),
                          blurRadius: AppTheme.blurSigma,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _launchPhone(ContactConfig.emergencyPhone),
                      icon: Icon(
                        Icons.emergency,
                        color: Colors.white,
                        size: AppTheme.iconSize,
                      ),
                      label: Text(
                        'Emergency Contact (${ContactConfig.emergencyPhone})',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.cardBorderRadius,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.cardPadding,
                          horizontal: AppTheme.cardPadding * 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
