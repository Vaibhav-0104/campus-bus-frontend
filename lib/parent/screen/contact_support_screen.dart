import 'package:flutter/material.dart';
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
}

/// Reusable contact card widget
class ContactCard extends StatelessWidget {
  final String title;
  final String phone;
  final VoidCallback onCall;
  final VoidCallback onChat;

  const ContactCard({
    super.key,
    required this.title,
    required this.phone,
    required this.onCall,
    required this.onChat,
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
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26), // 0.1 * 255 = 26
              border: Border.all(
                color: Colors.white.withAlpha(76),
                width: 1.5,
              ), // 0.3 * 255 = 76
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing / 2),
                Text(
                  'Phone: $phone',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
                    fontSize: 16,
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
  /// Launches phone call with error handling
  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else if (mounted) {
        _showErrorSnackBar('Could not launch phone call');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error launching phone call: $e');
      }
    }
  }

  /// Launches SMS chat with error handling
  Future<void> _launchChat(String phoneNumber) async {
    final Uri chatUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      if (await canLaunchUrl(chatUri)) {
        await launchUrl(chatUri);
      } else if (mounted) {
        _showErrorSnackBar('Could not launch chat');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error launching chat: $e');
      }
    }
  }

  /// Shows error message in SnackBar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.absentColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(ContactConfig.screenTitle),
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
                    onCall:
                        () => _launchPhone(ContactConfig.transportAdminPhone),
                    onChat:
                        () => _launchChat(ContactConfig.transportAdminPhone),
                  ),
                  ContactCard(
                    title: 'Bus Driver',
                    phone: ContactConfig.busDriverPhone,
                    onCall: () => _launchPhone(ContactConfig.busDriverPhone),
                    onChat: () => _launchChat(ContactConfig.busDriverPhone),
                  ),
                  const SizedBox(height: AppTheme.spacing * 1.5),
                  // Emergency Contact Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: AppTheme.absentColor,
                      borderRadius: BorderRadius.circular(
                        AppTheme.cardBorderRadius,
                      ),
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
