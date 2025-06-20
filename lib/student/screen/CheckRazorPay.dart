import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CheckRazorPay extends StatefulWidget {
  @override
  _CheckRazorPayState createState() => _CheckRazorPayState();
}

class _CheckRazorPayState extends State<CheckRazorPay> {
  late Razorpay _razorpay;
  String statusText = "Razorpay Initialized";

  static const String email = "testuser@example.com";
  static const String contactNumber = "8320810061";
  static const int amountInPaise = 50000; // 500 INR in paise (1 INR = 100 paise)
  static const String key = "rzp_test_Zcd4OU98qiD4Zu"; // Your Razorpay Test Key ID

  @override
  void initState() {
    super.initState();
    // Initialize the Razorpay instance
    _razorpay = Razorpay();

    // Register callback listeners for payment events
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Updates the status text displayed on the UI.
  void _updateStatus(String message) {
    setState(() {
      statusText = message;
    });
  }

  /// Displays a short toast message at the bottom of the screen.
  void _showToast(String message) {
    Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);
  }

  /// Initiates the Razorpay payment flow.
  Future<void> _startPayment() async {
    _updateStatus("Opening Razorpay");
    try {
      // Configure the payment options.
      // Removed 'order_id' as per request.
      // In a real production app, generating order_id from your backend
      // is highly recommended for security and advanced features.
      var options = {
        'key': key, // Your test or production API key
        'amount': amountInPaise, // Amount in smallest currency unit (paise for INR)
        'currency': 'INR',
        'name': 'Test Payment', // Name of your business or product
        'description': 'Payment of 500 INR for testing', // Description of the payment
        // 'order_id': 'order_${DateTime.now().millisecondsSinceEpoch}', // Removed as per user request
        'prefill': {
          'contact': contactNumber, // Pre-fill user's contact number
          'email': email, // Pre-fill user's email
        },
        'theme': {'color': '#3399cc'}, // Custom theme color for the Razorpay checkout
        'timeout': 300, // Timeout for the payment (in seconds)
      };

      _updateStatus("Working...");
      // Open the Razorpay payment checkout
      _razorpay.open(options);
    } catch (e) {
      // Log any errors that occur before opening Razorpay
      print("Error starting payment: $e");
      _showToast("Failed to start payment");
      _updateStatus("Failed to start payment");
      // Show an error dialog if payment initiation fails
      _showPaymentResultDialog(
        context,
        "Payment Initiation Failed",
        "There was an error trying to open the payment gateway. Please try again.",
        Colors.red,
      );
    }
  }

  /// Handles successful payment responses from Razorpay.
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("Payment Success: ${response.paymentId}");
    _updateStatus("Pay Successfully");
    _showToast("Payment Successful!");
    // Show a success dialog
    _showPaymentResultDialog(
      context,
      "Payment Successful!",
      "Payment ID: ${response.paymentId ?? 'N/A'}\nSignature: ${response.signature ?? 'N/A'}",
      Colors.green,
    );
  }

  /// Handles payment error responses from Razorpay.
  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Error: ${response.code} - ${response.message}");
    _updateStatus("Payment Failed");
    _showToast("Payment Failed: ${response.message ?? 'Unknown Error'}");
    // Show an error dialog
    _showPaymentResultDialog(
      context,
      "Payment Failed",
      "Code: ${response.code}\nMessage: ${response.message ?? 'Please try again.'}",
      Colors.red,
    );
  }

  /// Handles external wallet selections (e.g., Google Pay, PhonePe).
  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
    _showToast("External Wallet: ${response.walletName}");
    _updateStatus("External Wallet: ${response.walletName}");
    // Optionally, show a dialog for external wallet selection confirmation
    _showPaymentResultDialog(
      context,
      "External Wallet Selected",
      "You chose to pay with: ${response.walletName ?? 'an external wallet'}",
      Colors.orange,
    );
  }

  /// Custom dialog to show payment results (success or failure).
  void _showPaymentResultDialog(
      BuildContext context, String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                color == Colors.green ? Icons.check_circle : Icons.error,
                color: color,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "OK",
                style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Clear the Razorpay listeners to prevent memory leaks
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Check RazorPay",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Button to initiate payment
            ElevatedButton(
              onPressed: _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Button background color
                foregroundColor: Colors.white, // Button text color
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
                elevation: 5, // Shadow effect
              ),
              child: Text("Pay 500 INR"),
            ),
            SizedBox(height: 50), // Spacing
            // Display area for status updates
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Payment Status:",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple),
                    ),
                    SizedBox(height: 15),
                    _buildStatusText("Razorpay Initialized"),
                    _buildStatusText("Opening Razorpay"), // Updated text to match logic
                    _buildStatusText("Working..."), // Updated text to match logic
                    _buildStatusText("Pay Successfully"),
                    _buildStatusText("Payment Failed"), // Added status for failure
                    _buildStatusText("External Wallet: "), // Added status for external wallet
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget to build and highlight the current status text.
  Widget _buildStatusText(String text) {
    // Check if the current text matches the active status
    bool isCurrent = statusText.startsWith(text); // Use startsWith for dynamic messages

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: isCurrent ? FontWeight.w900 : FontWeight.normal,
          color: isCurrent ? Colors.blueAccent.shade700 : Colors.grey.shade700,
          decoration: isCurrent ? TextDecoration.underline : TextDecoration.none,
          decorationColor: Colors.blueAccent.shade700,
          decorationThickness: 2,
        ),
      ),
    );
  }
}
