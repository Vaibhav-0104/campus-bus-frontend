import 'package:flutter/material.dart';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs (calls and emails)

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // Admin contact details
  final String adminContactNumber = '+918320810061';
  final String adminEmail = 'admin@gmail.com';

  // Function to launch the phone dialer
  Future<void> _launchPhoneDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not launch phone dialer."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Function to launch the email client
  Future<void> _launchEmailClient(String emailAddress) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );
    if (!await launchUrl(launchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not launch email client."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the height remaining after AppBar and top safe area padding
    final double remainingScreenHeight = MediaQuery.of(context).size.height -
        AppBar().preferredSize.height -
        MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true, // Extend body behind app bar for full gradient
      appBar: AppBar(
        title: const Text(
          "Help & Support",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(0.3), // Liquid glass app bar
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0, // Remove shadow for flat look
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade500
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView( // Use SingleChildScrollView to prevent overflow on smaller screens
          padding: EdgeInsets.only(
            top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
            left: 20.0,
            right: 20.0,
            bottom: 20.0,
          ),
          // Use ConstrainedBox to ensure the content takes at least the remaining height
          // This makes the scrollable area fill the screen, thus showing the full gradient.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: remainingScreenHeight - 40, // Subtract total vertical padding of SingleChildScrollView
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Contact Admin",
                  style: TextStyle(
                    fontSize: 24, // Larger title
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.95), // White text with slight transparency
                    shadows: [Shadow(blurRadius: 5, color: Colors.black54)], // Text shadow for depth
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect( // ClipRRect for the liquid glass effect
                  borderRadius: BorderRadius.circular(20), // Increased rounded corners
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Stronger blur effect
                    child: Container(
                      padding: const EdgeInsets.all(25), // Increased padding
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.15), // Slightly more opaque
                            Colors.blue.shade200.withOpacity(0.15) // Slightly more opaque
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.25)), // More prominent border
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25), // Darker shadow for depth
                            blurRadius: 25, // Increased blur radius
                            spreadRadius: 3, // Increased spread radius
                            offset: const Offset(8, 8), // More pronounced offset
                          ),
                          BoxShadow( // Inner light shadow for a subtle glow
                            color: Colors.white.withOpacity(0.15), // Brighter inner glow
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(-5, -5), // Top-left inner glow
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded( // Use Expanded to ensure text wraps and doesn't cause overflow
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Admin Name: Uka Tarsadia University",
                                  style: TextStyle(
                                    fontSize: 18, // Larger font size
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.9),
                                    shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                                  ),
                                ),
                                const SizedBox(height: 10), // Increased spacing
                                Text(
                                  "Contact: $adminContactNumber",
                                  style: TextStyle(
                                    fontSize: 16, // Consistent font size
                                    color: Colors.lightBlueAccent.shade100, // Vibrant color
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6), // Increased spacing
                                Text(
                                  "Email: $adminEmail",
                                  style: TextStyle(
                                    fontSize: 16, // Consistent font size
                                    color: Colors.lightBlueAccent.shade100, // Vibrant color
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row( // Wrap buttons in a Row
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.call,
                                  color: Colors.greenAccent.shade100, // Brighter green icon
                                  size: 32, // Larger icon
                                  shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                                ),
                                onPressed: () => _launchPhoneDialer(adminContactNumber), // Call function on press
                              ),
                              const SizedBox(width: 10), // Spacing between icons
                              IconButton(
                                icon: Icon(
                                  Icons.email,
                                  color: Colors.orangeAccent.shade100, // Orange icon for email
                                  size: 32, // Larger icon
                                  shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                                ),
                                onPressed: () => _launchEmailClient(adminEmail), // Email function on press
                              ),
                            ],
                          ),
                        ],
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
