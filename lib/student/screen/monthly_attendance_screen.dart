import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:campus_bus_management/student/screen/daily_attendance_detail_screen.dart';
import 'package:campus_bus_management/config/api_config.dart';

class MonthlyAttendanceScreen extends StatefulWidget {
  final String envNumber;

  const MonthlyAttendanceScreen({Key? key, required this.envNumber})
    : super(key: key);

  @override
  State<MonthlyAttendanceScreen> createState() =>
      _MonthlyAttendanceScreenState();
}

class _MonthlyAttendanceScreenState extends State<MonthlyAttendanceScreen>
    with TickerProviderStateMixin {
  Map<String, String> monthlyAttendance = {};
  Map<String, int> monthlyPresentDays = {};
  Map<String, int> monthlyTotalPossibleDays = {};

  bool isLoading = true;
  String errorMessage = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _fetchMonthlyAttendance();
  }

  int _getTotalPossibleDaysInMonth(int year, int month) {
    int totalDays = 0;
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    for (
      var d = firstDayOfMonth;
      d.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
      d = d.add(const Duration(days: 1))
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
        final lastDayOfMonth = DateTime(currentYear, i + 1, 0);
        final monthName = DateFormat('MMMM').format(firstDayOfMonth);

        final totalPossibleDaysInMonth = _getTotalPossibleDaysInMonth(
          currentYear,
          i,
        );

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

          final calculatedPercentage =
              totalPossibleDaysInMonth > 0
                  ? (currentMonthPresentDays / totalPossibleDaysInMonth) * 100
                  : 0.0;

          tempMonthlyData[monthName] =
              '${calculatedPercentage.toStringAsFixed(1)}%';
          tempMonthlyPresentDays[monthName] = currentMonthPresentDays;
          tempMonthlyTotalPossibleDays[monthName] = totalPossibleDaysInMonth;
        } else {
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
      setState(() {
        errorMessage =
            'Failed to load attendance data. Please check your network or try again later.';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Monthly Attendance",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF87CEEB), Color(0xFF4682B4), Color(0xFF1E90FF)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.cyan),
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
                : ListView.builder(
                  padding: EdgeInsets.only(
                    top:
                        kToolbarHeight +
                        MediaQuery.of(context).padding.top +
                        16,
                    left: 16,
                    right: 16,
                    bottom: 20,
                  ),
                  itemCount: monthlyAttendance.length,
                  itemBuilder: (context, index) {
                    final monthName = monthlyAttendance.keys.elementAt(index);
                    final percentage = monthlyAttendance[monthName]!;
                    final presentDays = monthlyPresentDays[monthName] ?? 0;
                    final totalPossibleDays =
                        monthlyTotalPossibleDays[monthName] ?? 0;
                    final monthNumber = index + 1;
                    final currentYear = DateTime.now().year;

                    return AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.01,
                          child: _buildMonthlyAttendanceCard(
                            monthName: monthName,
                            percentage: percentage,
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
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }

  List<Color> _getGradientColorsForMonth(int index) {
    final List<List<Color>> gradients = [
      [Colors.cyan.shade400, Colors.blue.shade600],
      [Colors.green.shade400, Colors.teal.shade600],
      [Colors.orange.shade400, Colors.red.shade600],
      [Colors.purple.shade400, Colors.pink.shade600],
      [Colors.indigo.shade400, Colors.blue.shade700],
      [Colors.amber.shade400, Colors.orange.shade600],
      [Colors.lightGreen.shade400, Colors.lime.shade700],
      [Colors.deepOrange.shade400, Colors.red.shade700],
      [Colors.blueGrey.shade400, Colors.grey.shade700],
      [Colors.cyanAccent.shade400, Colors.lightBlue.shade600],
      [Colors.amber.shade400, Colors.deepOrange.shade600],
      [Colors.teal.shade400, Colors.cyan.shade600],
    ];
    return gradients[index % gradients.length];
  }

  Color _getIconColorForMonth(int index) {
    final List<Color> colors = [
      Colors.cyanAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.amberAccent,
      Colors.limeAccent,
      Colors.redAccent,
      Colors.pinkAccent,
      Colors.cyan,
      Colors.orange,
      Colors.tealAccent,
    ];
    return colors[index % colors.length];
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.8,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColors[0].withOpacity(0.25),
                    gradientColors[1].withOpacity(0.15),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.cyan, blurRadius: 12),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Present: $presentDays / $totalPossibleDays days',
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          percentage,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getPercentageColor(percentage),
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPercentageColor(String percentage) {
    final value = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    if (value >= 80) return Colors.greenAccent;
    if (value >= 60) return Colors.yellowAccent;
    return Colors.redAccent;
  }
}
