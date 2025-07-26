// lib/parent/screen/parent_dashboard_screen.dart
import 'package:flutter/material.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Dashboard')),
      body: const Center(
        child: Text('Welcome, Parent!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
