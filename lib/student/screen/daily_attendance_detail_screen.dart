import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:campus_bus_management/config/api_config.dart';

class DailyAttendanceDetailScreen extends StatefulWidget {
  final String envNumber;
  final int month;
  final int year;
  final String monthName;

  const DailyAttendanceDetailScreen({
    Key? key,
    required this.envNumber,
    required this.month,
    required this.year,
    required this.monthName,
  }) : super(key: key);

  @override
  State<DailyAttendanceDetailScreen> createState() =>
      _DailyAttendanceDetailScreenState();
}

class _DailyAttendanceDetailScreenState
    extends State<DailyAttendanceDetailScreen> {
  Map<int, String> dailyAttendanceStatus = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDailyAttendance();
  }

  Future<void> _fetchDailyAttendance() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final firstDayOfMonth = DateTime(widget.year, widget.month, 1);
      final lastDayOfMonth = DateTime(widget.year, widget.month + 1, 0);

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/students/attendance/by-date'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'envNumber': widget.envNumber,
              'startDate': DateFormat('yyyy-MM-dd').format(firstDayOfMonth),
              'endDate': DateFormat('yyyy-MM-dd').format(lastDayOfMonth),
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> records = data['dailyRecords'] ?? [];

        final Map<int, String> tempDailyStatus = {};
        for (int day = 1; day <= lastDayOfMonth.day; day++) {
          final currentDayDate = DateTime(widget.year, widget.month, day);
          // Check if it's a Sunday
          if (currentDayDate.weekday == DateTime.sunday) {
            tempDailyStatus[day] = 'Holiday';
          } else {
            tempDailyStatus[day] = 'No Data';
          }
        }

        for (var record in records) {
          try {
            final recordDate = DateTime.parse(record['date']);
            // Only update the status if the current status is not 'Holiday' (Sunday)
            if (tempDailyStatus[recordDate.day] != 'Holiday') {
              tempDailyStatus[recordDate.day] = record['status'];
            }
          } catch (e) {
            print('Error parsing record date: ${record['date']} - $e');
          }
        }

        setState(() {
          dailyAttendanceStatus = tempDailyStatus;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "${widget.monthName} ${widget.year}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
            // Adds space for the AppBar and status bar
            const SizedBox(height: kToolbarHeight + 60),
            Expanded(
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : errorMessage.isNotEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      )
                      : _buildAttendanceGrid(),
            ),
          ],
        ),
      ),
    );
  }

  // --- FIX APPLIED HERE ---
  Widget _buildAttendanceGrid() {
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        // *** FIX: Increased aspect ratio for more vertical space
        childAspectRatio: 0.95,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final day = index + 1;
        final status = dailyAttendanceStatus[day] ?? 'No Data';
        return _glassAttendanceCard(day, status);
      },
    );
  }

  // --- FIX APPLIED HERE ---
  Widget _glassAttendanceCard(int day, String status) {
    late final Color primaryColor;
    late final Color lightColor;
    late final String displayText;

    switch (status) {
      case 'Present':
        primaryColor = Colors.green.shade600;
        lightColor = Colors.green.shade300;
        displayText = 'P';
        break;
      case 'Absent':
        primaryColor = Colors.red.shade600;
        lightColor = Colors.red.shade300;
        displayText = 'A';
        break;
      case 'Holiday':
        primaryColor = Colors.blue.shade600;
        lightColor = Colors.cyan.shade300;
        displayText = 'H';
        break;
      case 'No Data':
      default:
        primaryColor = Colors.red.shade600;
        lightColor = Colors.red.shade300;
        displayText = 'A';
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          // *** FIX: Reduced vertical padding slightly
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.4),
                primaryColor.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(3, 3),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day Number (Top)
              Text(
                day.toString(),
                style: const TextStyle(
                  // *** FIX: Reduced font size from 24 to 20
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              // *** FIX: Reduced vertical space
              const SizedBox(height: 4),

              // Status Text (Center - Replaces Icon)
              Text(
                displayText,
                style: TextStyle(
                  // *** FIX: Reduced font size from 18 to 16
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: lightColor,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
