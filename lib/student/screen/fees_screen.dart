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

class _FeesPaymentScreenState extends State<FeesPaymentScreen>
    with TickerProviderStateMixin {
  late Razorpay _razorpay;
  String? orderId;
  String? duration;
  bool isLoading = true;
  String? errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Pulse animation for button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

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
      setState(() {
        errorMessage = "Network error: $e";
        isLoading = false;
      });
    }
  }

  void _showPaymentConfirmationDialog() {
    if (duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No fee duration set!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: Colors.white.withOpacity(0.97),
            elevation: 20,
            title: const Text(
              "Confirm Payment",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontWeight: FontWeight.bold,
                fontSize: 22,
                shadows: [Shadow(color: Colors.cyan, blurRadius: 10)],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.cyan.shade400, Colors.blue.shade600],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.6),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.payment,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Paying for:",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.envNumber,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00D4FF),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.shade300),
                  ),
                  child: Text(
                    "${duration!.replaceAll('month', ' Month').replaceAll('year', ' Year')}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066CC),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Proceed with secure payment?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startPayment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  "Pay Now",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _startPayment() async {
    if (duration == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Starting secure payment..."),
        backgroundColor: Colors.blue,
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
        setState(() => orderId = data['orderId']);

        var options = {
          'key': 'rzp_test_clLO3OkPO7TcaC',
          'amount': data['amount'],
          'currency': data['currency'],
          'name': 'Campus Bus',
          'description': 'Fee for $duration',
          'order_id': data['orderId'],
          'prefill': {
            'contact': '8320810061',
            'email': 'vaibhavsonar012@gmail.com',
          },
          'theme': {'color': '#00D4FF'},
        };

        _razorpay.open(options);
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err['error'] ?? "Payment failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verify = await http.post(
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

      if (verify.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Payment Successful!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Verification failed. Contact support.",
        backgroundColor: Colors.orange,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: "Payment Failed: ${response.message}",
      backgroundColor: Colors.red,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "Wallet: ${response.walletName}");
  }

  @override
  void dispose() {
    _razorpay.clear();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Pay Bus Fees",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // PURE WHITE TITLE
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white, // PURE WHITE BACK ARROW
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, -10),
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child:
                            isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.cyan,
                                  ),
                                )
                                : errorMessage != null
                                ? _buildErrorState()
                                : _buildSuccessState(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, size: 60, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(
          errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _fetchFeeDetails,
          icon: const Icon(Icons.refresh),
          label: const Text("Retry"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Pay Bus Fees",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.cyan, blurRadius: 15)],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyan, width: 1.5),
          ),
          child: Text(
            widget.envNumber,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "${duration!.replaceAll('month', ' Month').replaceAll('year', ' Year')}",
          style: const TextStyle(
            fontSize: 20,
            color: Colors.cyanAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: _showPaymentConfirmationDialog,
          icon: const Icon(Icons.payment, size: 32),
          label: const Text(
            "Pay with Razorpay",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 20,
            shadowColor: Colors.cyan.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, color: Colors.cyan.shade300, size: 18),
            const SizedBox(width: 8),
            const Text(
              "Secured by Razorpay",
              style: TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
