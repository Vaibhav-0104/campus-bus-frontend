import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _issueController = TextEditingController();

  void _submitIssue() {
    if (_issueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the issue before submitting.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Issue submitted: ${_issueController.text}'),
        backgroundColor: Colors.green,
      ),
    );

    _issueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Help & Support",
          style: TextStyle(color: Colors.white), // ✅ Font color white
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 2,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // ✅ Back Icon White
      ),
      backgroundColor: const Color(0xFFE3F2FD),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contact Admin",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 17, 16, 16), // ✅ Font color white
              ),
            ),
            const SizedBox(height: 10),

            // Admin Contact Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Admin Name: John Doe",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black, // ✅ Keep this readable
                          ),
                        ),
                        Text(
                          "Contact: +91-9876543210",
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                        Text(
                          "Email: admin@campusbus.com",
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Initiate call to Admin"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Report an Issue",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 9, 9, 9), // ✅ Font color white
              ),
            ),
            const SizedBox(height: 10),

            // Report Issue Text Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: TextField(
                controller: _issueController,
                maxLines: 5,
                style: const TextStyle(
                  color: Colors.black,
                ), // ✅ Text Input Black for Visibility
                decoration: const InputDecoration(
                  hintText: "Describe your issue here...",
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button (Small Size)
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 180, // ✅ Button Size Smaller
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text(
                    "Submit Issue",
                    style: TextStyle(fontSize: 14), // ✅ Small Font Size
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 224, 223, 226),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ), // ✅ Smaller Padding
                  ),
                  onPressed: _submitIssue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
