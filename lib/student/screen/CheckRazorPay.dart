import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:ui';

class CheckRazorPay extends StatefulWidget {
  @override
  _CheckRazorPayState createState() => _CheckRazorPayState();
}

class _CheckRazorPayState extends State<CheckRazorPay> {
  late Razorpay _razorpay;
  String statusText = "Razorpay Initialized";

  static const String email = "testuser@example.com";
  static const String contactNumber = "8320810061";
  static const int amountInPaise = 50000; // 500 INR
  static const String key = "rzp_test_Zcd4OU98qiD4Zu";

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _updateStatus(String message) {
    setState(() => statusText = message);
  }

  void _showToast(String message) {
    Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);
  }

  Future<void> _startPayment() async {
    _updateStatus("Opening Razorpay");
    try {
      var options = {
        'key': key,
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'Campus Bus',
        'description': 'Payment of 500 INR for testing',
        'prefill': {'contact': contactNumber, 'email': email},
        'theme': {'color': '#3399cc'},
        'timeout': 300,
      };

      _updateStatus("Working...");
      _razorpay.open(options);
    } catch (e) {
      print("Error: $e");
      _showToast("Failed to start payment");
      _updateStatus("Failed to start payment");
      _showPaymentResultDialog(
        context,
        "Payment Failed",
        "Could not open payment gateway.",
        Colors.red,
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("Success: ${response.paymentId}");
    _updateStatus("Pay Successfully");
    _showToast("Payment Successful!");
    _showPaymentResultDialog(
      context,
      "Payment Successful!",
      "Payment ID: ${response.paymentId}\nSignature: ${response.signature}",
      Colors.green,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Error: ${response.code} - ${response.message}");
    _updateStatus("Payment Failed");
    _showToast("Payment Failed: ${response.message}");
    _showPaymentResultDialog(
      context,
      "Payment Failed",
      "Code: ${response.code}\nMessage: ${response.message}",
      Colors.red,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("Wallet: ${response.walletName}");
    _showToast("Wallet: ${response.walletName}");
    _updateStatus("External Wallet: ${response.walletName}");
    _showPaymentResultDialog(
      context,
      "Wallet Selected",
      "Paying with: ${response.walletName}",
      Colors.orange,
    );
  }

  void _showPaymentResultDialog(
    BuildContext context,
    String title,
    String message,
    Color color,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white.withOpacity(0.95),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // GLASS CARD — SAME AS DASHBOARD
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(4, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(-3, -3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Check RazorPay",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF87CEEB), Color(0xFF4682B4), Color(0xFF1E90FF)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 60), // Extra space
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // PAYMENT BUTTON CARD
                    _glassCard(
                      child: Column(
                        children: [
                          Icon(Icons.payment, size: 50, color: Colors.white),
                          const SizedBox(height: 16),
                          const Text(
                            "Pay 500 INR",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _startPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                            ),
                            child: const Text(
                              "Proceed to Pay",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // STATUS CARD
                    _glassCard(
                      child: Column(
                        children: [
                          const Text(
                            "Payment Status",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildStatusRow("Razorpay Initialized"),
                          _buildStatusRow("Opening Razorpay"),
                          _buildStatusRow("Working..."),
                          _buildStatusRow("Pay Successfully"),
                          _buildStatusRow("Payment Failed"),
                          _buildStatusRow("External Wallet"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STATUS ROW WITH DYNAMIC HIGHLIGHT
  Widget _buildStatusRow(String text) {
    bool isActive = statusText.contains(text);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isActive ? Colors.green : Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
