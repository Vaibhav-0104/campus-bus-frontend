import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:campus_bus_management/config/api_config.dart'; // ✅ Import centralized URL

class Fee {
  final String envNumber;
  final String studentName;
  final String route;
  final double feeAmount;
  final bool isPaid;
  final DateTime? paymentDate;
  final String? transactionId;

  Fee({
    required this.envNumber,
    required this.studentName,
    required this.route,
    required this.feeAmount,
    this.isPaid = false,
    this.paymentDate,
    this.transactionId,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    DateTime? parsedPaymentDate;
    if (json['paymentDate'] != null) {
      try {
        parsedPaymentDate = DateTime.parse(json['paymentDate']);
      } catch (e) {
        debugPrint('Error parsing paymentDate: ${json['paymentDate']} - $e');
        parsedPaymentDate = null;
      }
    }

    return Fee(
      envNumber: json['envNumber'] as String,
      studentName: json['studentName'] as String,
      route: json['route'] as String,
      feeAmount: (json['feeAmount'] as num).toDouble(),
      isPaid: json['isPaid'] as bool,
      paymentDate: parsedPaymentDate,
      transactionId: json['transactionId'] as String?,
    );
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Fee> _allFeeHistory = [];
  List<Fee> _filteredFeeHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFeeHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterFeeHistory(_searchController.text);
  }

  void _filterFeeHistory(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFeeHistory = _allFeeHistory;
      } else {
        _filteredFeeHistory =
            _allFeeHistory
                .where(
                  (fee) => fee.studentName.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .toList();
      }
    });
  }

  Future<void> _fetchFeeHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allFeeHistory = [];
      _filteredFeeHistory = [];
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/fees/all'), // ✅ Updated URL
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          _allFeeHistory =
              responseData.map((json) => Fee.fromJson(json)).toList();
          _filteredFeeHistory = _allFeeHistory;
          _isLoading = false;
        });

        if (_allFeeHistory.isEmpty) {
          Fluttertoast.showToast(
            msg: "No fee records found in the database.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.blueAccent,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          debugPrint('Info: No fee records found in the database.');
        } else {
          Fluttertoast.showToast(
            msg: "Fee history loaded successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 14.0,
          );
          debugPrint(
            'Info: Fee history loaded successfully. Found ${_allFeeHistory.length} records.',
          );
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to load fee history: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: "Failed to load fee history: ${response.statusCode}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        debugPrint('API Error: $_errorMessage');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching fee history: $e';
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg:
            "Network error: Could not fetch fee history. Please check your connection or server status.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      debugPrint('Network/Parsing Error: $_errorMessage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = AppBar().preferredSize.height;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double totalAppBarAndStatusBarHeight = appBarHeight + statusBarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Fees History",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800.withOpacity(0.3),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: totalAppBarAndStatusBarHeight + 16,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle("Fee History"),
              const SizedBox(height: 10),
              _buildLiquidGlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Search by student name...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterFeeHistory('');
                              },
                            )
                            : null,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildFeeHistoryContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
        ),
      ),
    );
  }

  Widget _buildLiquidGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: padding ?? const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueGrey.shade300.withOpacity(0.15),
                Colors.blueGrey.shade700.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(10, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(-8, -8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFeeHistoryContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    } else if (_errorMessage != null) {
      return _buildLiquidGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Center(
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Colors.redAccent, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_filteredFeeHistory.isEmpty) {
      return _buildLiquidGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Center(
          child: Text(
            _searchController.text.isEmpty
                ? 'No fee records found in the database.'
                : 'No student found matching "${_searchController.text}".',
            style: TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return Column(
        children:
            _filteredFeeHistory
                .map(
                  (fee) => Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: _buildFeeHistoryCard(fee),
                  ),
                )
                .toList(),
      );
    }
  }

  Widget _buildFeeHistoryCard(Fee fee) {
    return _buildLiquidGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            fee.isPaid ? Icons.check_circle_outline : Icons.pending_actions,
            color: fee.isPaid ? Colors.lightGreenAccent : Colors.orangeAccent,
            size: 38,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.studentName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Enrollment: ${fee.envNumber}",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                Text(
                  "Route: ${fee.route}",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                Text(
                  "Amount: ₹${fee.feeAmount.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      fee.isPaid ? Icons.check_circle : Icons.warning_rounded,
                      color:
                          fee.isPaid
                              ? Colors.lightGreenAccent
                              : Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fee.isPaid ? "Status: PAID" : "Status: UNPAID",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            fee.isPaid
                                ? Colors.lightGreenAccent
                                : Colors.redAccent,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                      ),
                    ),
                  ],
                ),
                if (fee.isPaid && fee.paymentDate != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    "Paid On: ${DateFormat('dd MMM BCE').format(fee.paymentDate!)}",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
                if (fee.isPaid && fee.transactionId != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    "Txn ID: ${fee.transactionId}",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
