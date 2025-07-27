import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

/// Configuration class for settings
class SettingsConfig {
  static const String screenTitle = 'Settings';
  static const String headerTitle = 'Settings';
  static const List<String> languageOptions = ['English', 'Hindi', 'Gujarati'];
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

/// Reusable settings tile widget
class SettingsTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
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
            child: SwitchListTile(
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.accentColor,
              inactiveThumbColor: Colors.white.withAlpha(
                204,
              ), // 0.8 * 255 = 204
              inactiveTrackColor: Colors.white.withAlpha(76), // 0.3 * 255 = 76
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen to manage user settings
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _smsAlerts = false;
  String _language = SettingsConfig.languageOptions[0];

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications', _pushNotifications);
      await prefs.setBool('sms_alerts', _smsAlerts);
      await prefs.setString('language', _language);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
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
        title: const Text(SettingsConfig.screenTitle),
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
                      SettingsConfig.headerTitle,
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
                  // Notification Preferences
                  SettingsTile(
                    title: 'Push Notifications',
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() {
                        _pushNotifications = value;
                      });
                    },
                  ),
                  SettingsTile(
                    title: 'SMS Alerts',
                    value: _smsAlerts,
                    onChanged: (value) {
                      setState(() {
                        _smsAlerts = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing * 1.5),
                  // Language Selection
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacing / 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppTheme.cardBorderRadius,
                      ),
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
                                'Language',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing / 2),
                              DropdownButtonFormField<String>(
                                value: _language,
                                items:
                                    SettingsConfig.languageOptions
                                        .map(
                                          (lang) => DropdownMenuItem(
                                            value: lang,
                                            child: Text(
                                              lang,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.copyWith(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _language = value;
                                    });
                                  }
                                },
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                dropdownColor: AppTheme.cardBackground,
                                decoration: InputDecoration(
                                  labelText: 'Select Language',
                                  labelStyle: TextStyle(
                                    color: Colors.white.withAlpha(
                                      204,
                                    ), // 0.8 * 255 = 204
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(
                                    26,
                                  ), // 0.1 * 255 = 26
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.cardBorderRadius / 2,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.white.withAlpha(
                                        76,
                                      ), // 0.3 * 255 = 76
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.cardBorderRadius / 2,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.white.withAlpha(
                                        76,
                                      ), // 0.3 * 255 = 76
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.cardBorderRadius / 2,
                                    ),
                                    borderSide: BorderSide(
                                      color: AppTheme.accentColor,
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
                        onPressed: _saveSettings,
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
                          'Save Settings',
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
    );
  }
}
