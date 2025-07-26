import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:intl/intl.dart'; // For date formatting and month names
import 'package:campus_bus_management/student/screen/daily_attendance_detail_screen.dart'; // New import

class MonthlyAttendanceScreen extends StatefulWidget {
  final String envNumber;

  const MonthlyAttendanceScreen({Key? key, required this.envNumber})
    : super(key: key);

  @override
  State<MonthlyAttendanceScreen> createState() =>
      _MonthlyAttendanceScreenState();
}

class _MonthlyAttendanceScreenState extends State<MonthlyAttendanceScreen> {
  Map<String, String> monthlyAttendance = {}; // Stores month name -> percentage
  Map<String, int> monthlyPresentDays = {}; // Stores month name -> present days
  Map<String, int> monthlyTotalPossibleDays =
      {}; // Stores month name -> total possible days (excluding Sundays)

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMonthlyAttendance();
  }

  // Helper to calculate total possible days in a month, excluding Sundays
  int _getTotalPossibleDaysInMonth(int year, int month) {
    int totalDays = 0;
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    for (
      var d = firstDayOfMonth;
      d.isBefore(lastDayOfMonth.add(Duration(days: 1)));
      d = d.add(Duration(days: 1))
    ) {
      if (d.weekday != DateTime.sunday) {
        totalDays++;
      }
    }
    return totalDays;
  }

  Future<void> _fetchMonthlyAttendance() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final now = DateTime.now();
      final currentYear = now.year;
      final tempMonthlyData = <String, String>{};
      final tempMonthlyPresentDays = <String, int>{};
      final tempMonthlyTotalPossibleDays = <String, int>{};

      for (int i = 1; i <= 12; i++) {
        final firstDayOfMonth = DateTime(currentYear, i, 1);
        final lastDayOfMonth = DateTime(
          currentYear,
          i + 1,
          0,
        ); // Last day of current month
        final monthName = DateFormat('MMMM').format(firstDayOfMonth);

        final totalPossibleDaysInMonth = _getTotalPossibleDaysInMonth(
          currentYear,
          i,
        );

        final response = await http
            .post(
              Uri.parse(
                'http://192.168.31.104:5000/api/students/attendance/by-date',
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'envNumber': widget.envNumber,
                'startDate': DateFormat('yyyy-MM-dd').format(firstDayOfMonth),
                'endDate': DateFormat('yyyy-MM-dd').format(lastDayOfMonth),
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          double currentMonthPercentage = 0.0;
          int currentMonthPresentDays = 0;

          if (data['percentage'] != null) {
            final dynamic rawPercentage = data['percentage'];
            if (rawPercentage is num) {
              currentMonthPercentage = rawPercentage.toDouble();
            } else if (rawPercentage is String) {
              currentMonthPercentage = double.tryParse(rawPercentage) ?? 0.0;
            }
          }
          if (data['presentDays'] != null) {
            currentMonthPresentDays = data['presentDays'] as int;
          }

          // Calculate percentage based on total possible days excluding Sundays
          final calculatedPercentage =
              totalPossibleDaysInMonth > 0
                  ? (currentMonthPresentDays / totalPossibleDaysInMonth) * 100
                  : 0.0;

          tempMonthlyData[monthName] =
              '${calculatedPercentage.toStringAsFixed(1)}%';
          tempMonthlyPresentDays[monthName] = currentMonthPresentDays;
          tempMonthlyTotalPossibleDays[monthName] = totalPossibleDaysInMonth;
        } else {
          print(
            'API Error for $monthName: Status=${response.statusCode}, Body=${response.body}',
          );
          tempMonthlyData[monthName] = 'Error';
          tempMonthlyPresentDays[monthName] = 0;
          tempMonthlyTotalPossibleDays[monthName] = totalPossibleDaysInMonth;
        }
      }

      setState(() {
        monthlyAttendance = tempMonthlyData;
        monthlyPresentDays = tempMonthlyPresentDays;
        monthlyTotalPossibleDays = tempMonthlyTotalPossibleDays;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching monthly attendance: $e');
      setState(() {
        errorMessage =
            'Failed to load attendance data. Please check your network or try again later.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Monthly Attendance",
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
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade500,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child:
            isLoading
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
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.redAccent.shade100,
                      ),
                    ),
                  ),
                )
                : ListView.builder(
                  padding: EdgeInsets.only(
                    top:
                        AppBar().preferredSize.height +
                        MediaQuery.of(context).padding.top +
                        16,
                  ),
                  itemCount: monthlyAttendance.length,
                  itemBuilder: (context, index) {
                    final monthName = monthlyAttendance.keys.elementAt(index);
                    final percentage = monthlyAttendance[monthName];
                    final presentDays = monthlyPresentDays[monthName] ?? 0;
                    final totalPossibleDays =
                        monthlyTotalPossibleDays[monthName] ?? 0;
                    final monthNumber = index + 1; // 1-indexed month number
                    final currentYear = DateTime.now().year;

                    return _buildMonthlyAttendanceCard(
                      monthName: monthName,
                      percentage: percentage!,
                      presentDays: presentDays,
                      totalPossibleDays: totalPossibleDays,
                      gradientColors: _getGradientColorsForMonth(index),
                      iconColor: _getIconColorForMonth(index),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DailyAttendanceDetailScreen(
                                  envNumber: widget.envNumber,
                                  month: monthNumber,
                                  year: currentYear,
                                  monthName: monthName,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }

  // Helper to get different gradient colors for each card
  List<Color> _getGradientColorsForMonth(int index) {
    final List<List<Color>> predefinedGradients = [
      [Colors.blue.shade300, Colors.cyan.shade600],
      [Colors.green.shade300, Colors.teal.shade600],
      [Colors.orange.shade300, Colors.red.shade600],
      [Colors.purple.shade300, Colors.pink.shade600],
      [Colors.indigo.shade300, Colors.blue.shade600],
      [Colors.yellow.shade300, Colors.amber.shade600],
      [Colors.lightGreen.shade300, Colors.lime.shade600],
      [Colors.deepOrange.shade300, Colors.brown.shade600],
      [Colors.blueGrey.shade300, Colors.grey.shade600],
      [Colors.cyanAccent.shade100, Colors.lightBlue.shade600],
      [Colors.amber.shade300, Colors.deepOrange.shade600],
    ];
    return predefinedGradients[index % predefinedGradients.length];
  }

  // Helper to get different icon colors for each card
  Color _getIconColorForMonth(int index) {
    final List<Color> predefinedIconColors = [
      Colors.lightBlueAccent.shade100,
      Colors.greenAccent.shade100,
      Colors.orangeAccent.shade100,
      Colors.purpleAccent.shade100,
      Colors.blueAccent.shade100,
      Colors.yellowAccent.shade100,
      Colors.limeAccent.shade100,
      Colors.deepOrangeAccent.shade100,
      Colors.pinkAccent.shade100,
      Colors.blueGrey.shade100,
      Colors.cyanAccent.shade100,
      Colors.amberAccent.shade100,
    ];
    return predefinedIconColors[index % predefinedIconColors.length];
  }

  Widget _buildMonthlyAttendanceCard({
    required String monthName,
    required String percentage,
    required int presentDays,
    required int totalPossibleDays,
    required List<Color> gradientColors,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    // Determine icon based on percentage or status - REMOVED
    // IconData cardIcon;
    // if (percentage == 'No Data' || percentage == 'Error') {
    //   cardIcon = Icons.info_outline;
    // } else {
    //   double value = double.tryParse(percentage.replaceAll('%', '')) ?? 0.0;
    //   if (value >= 75) {
    //     cardIcon = Icons.check_circle_outline;
    //   } else if (value >= 50) {
    //     cardIcon = Icons.warning_amber_outlined;
    //   } else {
    //     cardIcon = Icons.cancel_outlined;
    //   }
    // }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      gradientColors
                          .map((color) => color.withOpacity(0.15))
                          .toList(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 25,
                    spreadRadius: 3,
                    offset: const Offset(8, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: Offset(-5, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Removed the leading icon here
                  // Icon(
                  //   cardIcon,
                  //   size: 48,
                  //   color: iconColor,
                  //   shadows: [
                  //     Shadow(
                  //       blurRadius: 12.0,
                  //       color: Colors.black.withOpacity(0.6),
                  //       offset: Offset(3.0, 3.0),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(width: 20), // Removed this spacing as well
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 6.0,
                                color: Colors.black45,
                                offset: Offset(1.5, 1.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Present: $presentDays / $totalPossibleDays days ($percentage)',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white54,
                    size: 20,
                  ), // Arrow icon for navigation
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
