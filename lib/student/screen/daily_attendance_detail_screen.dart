import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:intl/intl.dart'; // For date formatting and month names

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
  State<DailyAttendanceDetailScreen> createState() => _DailyAttendanceDetailScreenState();
}

class _DailyAttendanceDetailScreenState extends State<DailyAttendanceDetailScreen> {
  Map<int, String> dailyAttendanceStatus = {}; // Day number -> status ("Present", "Absent", "Holiday", "No Data")
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

      // Fetch detailed attendance for the selected month
      final response = await http.post(
        Uri.parse('http://192.168.31.104:5000/api/students/attendance/by-date'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'envNumber': widget.envNumber,
          'startDate': DateFormat('yyyy-MM-dd').format(firstDayOfMonth),
          'endDate': DateFormat('yyyy-MM-dd').format(lastDayOfMonth),
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> records = data['dailyRecords'] ?? [];

        final Map<int, String> tempDailyStatus = {};
        // Initialize all days of the month (excluding Sundays) as "No Data" or "Holiday"
        for (int day = 1; day <= lastDayOfMonth.day; day++) {
          final currentDayDate = DateTime(widget.year, widget.month, day);
          if (currentDayDate.weekday == DateTime.sunday) {
            tempDailyStatus[day] = 'Holiday'; // Mark Sundays as holidays
          } else {
            tempDailyStatus[day] = 'No Data'; // Default for working days without record
          }
        }

        // Populate with actual attendance data
        for (var record in records) {
          try {
            final recordDate = DateTime.parse(record['date']);
            tempDailyStatus[recordDate.day] = record['status'];
          } catch (e) {
            print('Error parsing record date: ${record['date']} - $e');
          }
        }

        setState(() {
          dailyAttendanceStatus = tempDailyStatus;
          isLoading = false;
        });
      } else {
        print('API Error for daily attendance: Status=${response.statusCode}, Body=${response.body}');
        setState(() {
          errorMessage = 'Failed to load daily attendance: ${response.statusCode} - ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching daily attendance: $e');
      setState(() {
        errorMessage = 'Failed to load daily attendance data. Check network or API.';
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
          "${widget.monthName} ${widget.year} Attendance",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(0.4),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.transparent,
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
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade500
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.redAccent.shade100),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.only(
                        top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 16,
                        left: 16.0,
                        right: 16.0,
                        bottom: 16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // 5 columns for dates
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8, // Adjust as needed
                    ),
                    itemCount: DateTime(widget.year, widget.month + 1, 0).day, // Total days in the month
                    itemBuilder: (context, index) {
                      final day = index + 1; // Day number (1-indexed)
                      final status = dailyAttendanceStatus[day] ?? 'No Data'; // Default to 'No Data' if not found
                      return _buildDailyAttendanceCard(day, status);
                    },
                  ),
      ),
    );
  }

  Widget _buildDailyAttendanceCard(int day, String status) {
    IconData icon;
    Color iconColor;
    Color cardColor;
    String statusText = status;

    switch (status) {
      case 'Present':
        icon = Icons.check_circle_outline;
        iconColor = Colors.greenAccent;
        cardColor = Colors.green.shade700.withOpacity(0.2);
        break;
      case 'Absent':
        icon = Icons.cancel_outlined;
        iconColor = Colors.redAccent;
        cardColor = Colors.red.shade700.withOpacity(0.2);
        break;
      case 'Holiday':
        icon = Icons.beach_access;
        iconColor = Colors.lightBlueAccent;
        cardColor = Colors.blueGrey.shade700.withOpacity(0.2);
        statusText = 'Holiday';
        break;
      case 'No Data':
      default:
        icon = Icons.help_outline;
        iconColor = Colors.grey;
        cardColor = Colors.blueGrey.shade900.withOpacity(0.2);
        statusText = 'N/A';
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                  shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                icon,
                size: 36,
                color: iconColor,
                shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
              ),
              const SizedBox(height: 5),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
