import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter

// This is the FeesPaymentScreen class, now with an even more enhanced Liquid Glass iOS 26 inspired UI.
class FeesPaymentScreen extends StatefulWidget {
  final String envNumber;
  const FeesPaymentScreen({Key? key, required this.envNumber})
    : super(key: key);

  @override
  State<FeesPaymentScreen> createState() => _FeesPaymentScreenState();
}

class _FeesPaymentScreenState extends State<FeesPaymentScreen> {
  late Razorpay _razorpay;
  String? orderId; // To store the order ID received from the backend

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    // Register event listeners for payment success, error, and external wallet
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Shows a confirmation dialog before initiating the payment.
  void _showPaymentConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white.withOpacity(
            0.95,
          ), // Slightly more opaque for clarity
          title: Text(
            "Confirm Payment",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
              fontSize: 20, // Slightly larger title
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 48,
              ), // Larger, darker icon
              SizedBox(height: 15),
              Text(
                "You are about to pay the bus fees for enrollment:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black87,
                ), // Darker text for readability
              ),
              SizedBox(height: 8),
              Text(
                widget.envNumber,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22, // Larger enrollment number
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700, // Darker purple
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Do you want to proceed with the payment?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.black87),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _startPayment(); // Proceed with payment
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: Text(
                "Pay",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Initiates the payment process by first creating an order on the backend.
  void _startPayment() async {
    // Show a loading indicator (optional, but good practice)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Initiating payment, please wait..."),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Make an HTTP POST request to your backend to create a Razorpay order
      // Ensure your backend server is running and accessible at this IP address.
      final response = await http.post(
        Uri.parse(
          "http://172.20.10.9:5000/api/fees/pay",
        ), // Replace with your actual backend URL
        body: jsonEncode({"envNumber": widget.envNumber}),
        headers: {"Content-Type": "application/json"},
      );

      // Check if the backend request was successful
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orderId =
              data['orderId']; // Store the order ID for later use (e.g., if you re-introduce verification)
        });

        // Prepare Razorpay options with data from the backend
        var options = {
          'key':
              'rzp_test_clLO3OkPO7TcaC', // Your Razorpay API Key ID (test key)
          'amount':
              data['amount'], // Amount from backend (in smallest currency unit)
          'currency': data['currency'], // Currency from backend (e.g., 'INR')
          'name': 'Campus Bus Management', // Your application/business name
          'description':
              'Bus Route Payment for ${widget.envNumber}', // Payment description
          'order_id': data['orderId'], // Order ID generated by your backend
          'prefill': {
            'contact':
                '8320810061', // Pre-fill contact number (can be dynamic, fetched from user profile)
            'email':
                'vaibhavsonar012@gmail.com', // Pre-fill email (can be dynamic)
          },
          'theme': {
            'color': '#6200EE',
          }, // Custom theme color for Razorpay checkout (Deep Purple variation)
        };

        _razorpay.open(options); // Open the Razorpay checkout
      } else {
        // Show an error message if backend order creation failed
        final errorData = jsonDecode(response.body);
        String errorMessage =
            errorData['error'] ??
            'Failed to create payment order! Status: ${response.statusCode}';
        // Customize the message for the "already paid" case
        if (errorData['error'] ==
            "Fee for this enrollment number is already paid.") {
          errorMessage =
              "Fee for envNumber ${widget.envNumber} is already paid.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Handle network or other errors during payment initiation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error starting payment: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Handles successful payment responses from Razorpay.
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Call the backend to verify the payment and update the database
    // This step is CRUCIAL for security and to ensure payment authenticity.
    try {
      final verifyResponse = await http.post(
        Uri.parse(
          "http://172.20.10.9:5000/api/fees/verify",
        ), // Your backend verification endpoint
        body: jsonEncode({
          "envNumber": widget.envNumber,
          "paymentId": response.paymentId,
          "orderId": orderId, // Use the orderId obtained from createPayment
          "signature": response.signature,
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (verifyResponse.statusCode == 200) {
        print("Payment Successful! Payment ID: ${response.paymentId}");
        Fluttertoast.showToast(
          msg: "✅ Payment Successful and Verified!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        // Verification failed on the backend
        print(
          "Payment Successful but Verification Failed! Status: ${verifyResponse.statusCode}",
        );
        Fluttertoast.showToast(
          msg:
              "⚠️ Payment Successful, but verification failed! Please contact support.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      // Error during verification request
      print("Error verifying payment: $e");
      Fluttertoast.showToast(
        msg:
            "⚠️ Payment Successful, but an error occurred during verification! Please contact support.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  /// Handles payment error responses from Razorpay.
  void _handlePaymentError(PaymentFailureResponse response) {
    print(
      "Payment Failed: Code: ${response.code}, Message: ${response.message}",
    ); // Print error to console
    Fluttertoast.showToast(
      msg:
          "❌ Payment Failed: ${response.message ?? 'Unknown Error'}", // Show error message on Flutter toast
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Handles external wallet selections (e.g., Google Pay, PhonePe).
  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet Selected: ${response.walletName}");
    Fluttertoast.showToast(
      msg: "External Wallet Selected: ${response.walletName}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blueAccent,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clear Razorpay listeners to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Extends body behind app bar for full gradient
      appBar: AppBar(
        title: const Text(
          "Pay Bus Fees",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(
          0.4,
        ), // Slightly more transparent app bar
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0, // Remove shadow for a flat look
        centerTitle: true,
        flexibleSpace: ClipRect(
          // Clip to make the blur effect contained within the AppBar area
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 8,
              sigmaY: 8,
            ), // Increased blur for app bar background
            child: Container(
              color: Colors.transparent, // Transparent to allow blur to show
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
              Colors.deepPurple.shade600,
              Colors.deepPurple.shade400,
            ], // More vibrant gradient
            stops: [0.1, 0.5, 0.9],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              // Clip for rounded corners on the "glass" effect
              borderRadius: BorderRadius.circular(
                30,
              ), // More rounded corners for the glass card
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 25.0,
                  sigmaY: 25.0,
                ), // Significantly stronger blur for the main content glass
                child: Container(
                  padding: const EdgeInsets.all(30.0), // Increased padding
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.08,
                    ), // More transparent white for a lighter glass feel
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ), // Thinner, lighter border
                    boxShadow: [
                      // Enhanced shadows for more depth
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.3,
                        ), // Darker, more spread shadow
                        blurRadius: 40, // Increased blur radius
                        spreadRadius: 5, // Added spread radius
                        offset: Offset(
                          0,
                          20,
                        ), // More pronounced vertical offset
                      ),
                      BoxShadow(
                        // Inner light shadow for a subtle glow
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, -5),
                      ),
                    ],
                    gradient: LinearGradient(
                      // Subtle internal gradient for glass sheen
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.01),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Wrap content
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch, // Stretch content horizontally
                    children: [
                      // Informative header for the fees
                      Text(
                        "Outstanding Bus Fees for Enrollment:",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22, // Slightly larger font
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(
                            0.95,
                          ), // Brighter white text
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black.withOpacity(0.5),
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15), // Increased spacing
                      // Display the enrollment number prominently
                      Text(
                        widget.envNumber,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30, // Larger enrollment number
                          fontWeight: FontWeight.w900,
                          color:
                              Colors.amberAccent.shade200, // Brighter highlight
                          letterSpacing: 2.0, // More letter spacing
                          shadows: [
                            Shadow(
                              blurRadius: 12.0,
                              color: Colors.black.withOpacity(0.7),
                              offset: Offset(3.0, 3.0),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 60), // Increased spacing
                      // Button to initiate payment via backend (for dynamic fee payment)
                      ElevatedButton.icon(
                        onPressed:
                            _showPaymentConfirmationDialog, // Call confirmation dialog first
                        icon: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 30,
                        ), // Larger icon
                        label: const Text(
                          "Pay Now with Razorpay",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ), // Larger font size
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors
                                  .green
                                  .shade600, // Green for "Pay Now" action
                          foregroundColor:
                              Colors.white, // Text color for button
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 20,
                          ), // More padding
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ), // More rounded
                          elevation: 15, // Even more prominent shadow
                          shadowColor:
                              Colors
                                  .green
                                  .shade400, // Brighter shadow for button
                          splashFactory:
                              InkRipple.splashFactory, // Nice ripple effect
                        ),
                      ),
                      SizedBox(height: 40), // Increased spacing
                      // Security message
                      Text(
                        "Your payments are securely processed by Razorpay.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14, // Slightly larger
                          color: Colors.white.withOpacity(
                            0.8,
                          ), // Brighter translucent
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              blurRadius: 5.0,
                              color: Colors.black.withOpacity(0.2),
                              offset: Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
