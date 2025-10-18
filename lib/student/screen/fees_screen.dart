import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:campus_bus_management/config/api_config.dart';

class FeesPaymentScreen extends StatefulWidget {
  final String envNumber;
  const FeesPaymentScreen({Key? key, required this.envNumber})
    : super(key: key);

  @override
  State<FeesPaymentScreen> createState() => _FeesPaymentScreenState();
}

class _FeesPaymentScreenState extends State<FeesPaymentScreen> {
  late Razorpay _razorpay;
  String? orderId;
  String? duration;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchFeeDetails();
  }

  Future<void> _fetchFeeDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/fees/student/${widget.envNumber}"),
        headers: {"Content-Type": "application/json"},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            duration = data['duration'];
            isLoading = false;
          });
        } else {
          final errorData = jsonDecode(response.body);
          setState(() {
            errorMessage = errorData['error'] ?? "Failed to fetch fee details";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error fetching fee details: $e";
          isLoading = false;
        });
      }
    }
  }

  void _showPaymentConfirmationDialog() {
    if (duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No fee duration set for this enrollment!"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white.withOpacity(0.95),
          title: Text(
            "Confirm Payment",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 48,
              ),
              SizedBox(height: 15),
              Text(
                "You are about to pay the bus fees for:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.black87),
              ),
              SizedBox(height: 8),
              Text(
                widget.envNumber,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Duration: ${duration!.replaceAll('month', ' Month').replaceAll('year', ' Year')}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade600,
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
                Navigator.of(context).pop();
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
                Navigator.of(context).pop();
                _startPayment();
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

  void _startPayment() async {
    if (duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No fee duration set for this enrollment!"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Initiating payment, please wait..."),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/fees/pay"),
        body: jsonEncode({"envNumber": widget.envNumber, "duration": duration}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orderId = data['orderId'];
        });

        var options = {
          'key': 'rzp_test_clLO3OkPO7TcaC',
          'amount': data['amount'],
          'currency': data['currency'],
          'name': 'Campus Bus Management',
          'description':
              'Bus Route Payment for ${widget.envNumber} ($duration)',
          'order_id': data['orderId'],
          'prefill': {
            'contact': '8320810061',
            'email': 'vaibhavsonar012@gmail.com',
          },
          'theme': {'color': '#6200EE'},
        };

        _razorpay.open(options);
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage =
            errorData['error'] ??
            'Failed to create payment order! Status: ${response.statusCode}';
        if (errorData['error'] ==
            "Fee for this enrollment number and duration is already paid.") {
          errorMessage =
              "Fee for envNumber ${widget.envNumber} ($duration) is already paid.";
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error starting payment: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verifyResponse = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/fees/verify"),
        body: jsonEncode({
          "envNumber": widget.envNumber,
          "duration": duration,
          "paymentId": response.paymentId,
          "orderId": orderId,
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

  void _handlePaymentError(PaymentFailureResponse response) {
    print(
      "Payment Failed: Code: ${response.code}, Message: ${response.message}",
    );
    Fluttertoast.showToast(
      msg: "❌ Payment Failed: ${response.message ?? 'Unknown Error'}",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

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
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Pay Bus Fees",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(0.4),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.transparent),
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
            ],
            stops: [0.1, 0.5, 0.9],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                child: Container(
                  padding: const EdgeInsets.all(30.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 5,
                        offset: Offset(0, 20),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, -5),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.01),
                      ],
                    ),
                  ),
                  child:
                      isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.lightBlueAccent,
                              ),
                            ),
                          )
                          : errorMessage != null
                          ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _fetchFeeDetails,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "Retry",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Outstanding Bus Fees for Enrollment:",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.95),
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black.withOpacity(0.5),
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                widget.envNumber,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amberAccent.shade200,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 12.0,
                                      color: Colors.black.withOpacity(0.7),
                                      offset: Offset(3.0, 3.0),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                "Duration: ${duration!.replaceAll('month', ' Month').replaceAll('year', ' Year')}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                  shadows: [
                                    Shadow(
                                      blurRadius: 5.0,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: Offset(1.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 60),
                              ElevatedButton.icon(
                                onPressed: _showPaymentConfirmationDialog,
                                icon: Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                label: const Text(
                                  "Pay Now with Razorpay",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 20,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 15,
                                  shadowColor: Colors.green.shade400,
                                  splashFactory: InkRipple.splashFactory,
                                ),
                              ),
                              SizedBox(height: 40),
                              Text(
                                "Your payments are securely processed by Razorpay.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
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
