import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _startPayment() async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.31.104:5000/api/fees/pay"),
        body: jsonEncode({"envNumber": widget.envNumber}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orderId = data['orderId'];
        });

        var options = {
          'key': 'rzp_test_Zcd4OU98qiD4Zu',
          'amount': data['amount'],
          'currency': data['currency'],
          'name': 'Bus Fee Payment',
          'description': 'Bus Route Payment',
          'order_id': data['orderId'],
          'prefill': {
            'contact': '8320810061',
            'email': 'vaibhavsonar012@gmail.com',
          },
          'theme': {'color': '#3399cc'},
        };

        _razorpay.open(options);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create payment order!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error starting payment: $e")));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final verifyResponse = await http.post(
      Uri.parse("https://campus-bus-backend.onrender.com/api/fees/verify"),
      body: jsonEncode({
        "envNumber": widget.envNumber,
        "paymentId": response.paymentId,
        "orderId": orderId,
        "signature": response.signature,
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (verifyResponse.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Payment Successful!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Payment Verification Failed!")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet Selected: ${response.walletName}"),
      ),
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
      appBar: AppBar(
        title: const Text("Pay Fees", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple, // ✅ Header color Purple
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _startPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple, // ✅ Button Background Purple
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text(
            "Pay Now with Razorpay",
            style: TextStyle(color: Colors.white),
          ), // ✅ Button Text White
        ),
      ),
    );
  }
}
