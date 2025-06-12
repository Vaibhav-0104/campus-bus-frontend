import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageFeesScreen extends StatefulWidget {
  const ManageFeesScreen({super.key});

  @override
  _ManageFeesScreenState createState() => _ManageFeesScreenState();
}

class _ManageFeesScreenState extends State<ManageFeesScreen> {
  final TextEditingController envNumberController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final TextEditingController routeController =
      TextEditingController(); //  Added Route Field

  //  Set Student Fees
  Future<void> _setFees() async {
    if (envNumberController.text.isEmpty ||
        feeController.text.isEmpty ||
        routeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("All fields are required!")));
      return;
    }

    double? feeAmount = double.tryParse(feeController.text);
    if (feeAmount == null || feeAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid fee amount!")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse("https://campus-bus-backend.onrender.com/api/fees/set-fee"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "envNumber": envNumberController.text,
        "feeAmount": feeAmount,
        "route": routeController.text, // Send route to backend
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fee updated successfully!")));
      envNumberController.clear();
      feeController.clear();
      routeController.clear();
    } else {
      final errorMsg =
          jsonDecode(response.body)['error'] ?? "Failed to update fee";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Fees")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: envNumberController,
              decoration: InputDecoration(
                labelText: "Enter Environment Number",
              ),
            ),
            TextField(
              controller: routeController, // Route input field
              decoration: InputDecoration(labelText: "Enter Route"),
            ),
            TextField(
              controller: feeController,
              decoration: InputDecoration(labelText: "Enter Fee Amount"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _setFees, child: const Text("Set Fees")),
          ],
        ),
      ),
    );
  }
}
