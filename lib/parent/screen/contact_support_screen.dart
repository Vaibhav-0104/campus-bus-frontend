import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

/// Configuration class for contact information
class ContactConfig {
  static const String screenTitle = 'Contact & Support';
  static const String headerTitle = 'Contact Information';
  static const String transportAdminPhone = '+91 8320810061';
  static const String busDriverPhone = '+91 9723588031';
  static const String emergencyPhone = '+91 9313888538';
}

/// Purple Theme (Matches Dashboard)
class AppTheme {
  static const Color primary = Color(0xFF6A1B9A); // Deep Purple
  static const Color lightPurple = Color(0xFFCE93D8); // Light Purple Accent
  static const Color background = Color(0xFFF8F5FF); // Light Purple BG
  static const Color cardBg = Colors.white; // White Cards
  static const Color textPrimary = Color(0xFF4A148C); // Dark Purple Text
  static const Color textSecondary = Color(0xFF7E57C2);
  static const Color successColor = Color(0xFF66BB6A); // Green
  static const Color absentColor = Color(0xFFFF5252); // Red

  static const double cardBorderRadius = 20.0;
  static const double blur = 12.0;
  static const double cardPadding = 16.0;
  static const double spacing = 16.0;
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.blur,
            sigmaY: AppTheme.blur,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: BoxDecoration(
              color: AppTheme.cardBg.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
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
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
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
                        backgroundColor: AppTheme.lightPurple,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    'Phone: $phone',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
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
                        color: AppTheme.successColor,
                        size: AppTheme.iconSize,
                      ),
                      onPressed: onCall,
                      tooltip: 'Call',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chat,
                        color: AppTheme.lightPurple,
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

/// Contact and Support screen
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  _ContactSupportScreenState createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  Future<bool> _showConfirmationDialog(String action, String phone) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: AppTheme.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.cardBorderRadius,
                  ),
                ),
                title: Text(
                  'Confirm $action',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'Do you want to $action $phone?',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.absentColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(color: AppTheme.lightPurple),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

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
              backgroundColor: AppTheme.lightPurple,
            ),
          );
        }
      } else {
        throw 'Could not launch phone call';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.absentColor,
          ),
        );
      }
    }
  }

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
              backgroundColor: AppTheme.lightPurple,
            ),
          );
        }
      } else {
        throw 'Could not launch chat';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.absentColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          ContactConfig.screenTitle,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppTheme.cardPadding),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(
                      AppTheme.cardBorderRadius,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    ContactConfig.headerTitle,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
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
                  iconColor: AppTheme.lightPurple,
                  onCall: () => _launchPhone(ContactConfig.transportAdminPhone),
                  onChat: () => _launchChat(ContactConfig.transportAdminPhone),
                ),
                ContactCard(
                  title: 'Bus Driver',
                  phone: ContactConfig.busDriverPhone,
                  icon: Icons.directions_bus,
                  iconColor: AppTheme.successColor,
                  onCall: () => _launchPhone(ContactConfig.busDriverPhone),
                  onChat: () => _launchChat(ContactConfig.busDriverPhone),
                ),

                const SizedBox(height: AppTheme.spacing * 1.5),

                // Emergency Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.absentColor, Color(0xFFE53935)],
                    ),
                    borderRadius: BorderRadius.circular(
                      AppTheme.cardBorderRadius,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _launchPhone(ContactConfig.emergencyPhone),
                    icon: const Icon(
                      Icons.emergency,
                      color: Colors.white,
                      size: AppTheme.iconSize,
                    ),
                    label: Text(
                      'Emergency Contact (${ContactConfig.emergencyPhone})',
                      style: const TextStyle(
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
    );
  }
}
