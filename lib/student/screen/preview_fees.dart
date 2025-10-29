import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:campus_bus_management/config/api_config.dart';

class PreviewFeesScreen extends StatefulWidget {
  final String envNumber;

  const PreviewFeesScreen({Key? key, required this.envNumber})
    : super(key: key);

  @override
  _PreviewFeesScreenState createState() => _PreviewFeesScreenState();
}

class _PreviewFeesScreenState extends State<PreviewFeesScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? feeData;
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    fetchFeeDetails();
  }

  Future<void> fetchFeeDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/fees/student/${widget.envNumber}'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        setState(() {
          feeData = decodedData;
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage =
              'No fee details found for Enrollment Number: ${widget.envNumber}';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load fee details. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network Error: Could not connect to the server.';
        isLoading = false;
      });
    }
  }

  Widget _buildLiquidGlassDetailCard(
    IconData icon,
    Color iconColor,
    String title,
    String value,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.01,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                        Colors.cyan.withOpacity(0.25),
                        Colors.blue.withOpacity(0.15),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconColor.withOpacity(0.2),
                          border: Border.all(
                            color: iconColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 26, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.cyan, blurRadius: 8),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
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
        );
      },
    );
  }

  void _showExportPdfConfirmationDialog() {
    if (feeData == null || feeData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No fee data available to export."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            // FIXED: Removed extra parentheses
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: Colors.white.withOpacity(0.97),
            elevation: 20,
            title: const Text(
              "Export Fee Details",
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
                    Icons.picture_as_pdf,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Export fee details for:",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.envNumber,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00D4FF),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Generate PDF?",
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
                onPressed: () async {
                  Navigator.pop(context);
                  await generateAndOpenPdf();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  "Export PDF",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> generateAndOpenPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Generating PDF..."),
        backgroundColor: Colors.blue,
      ),
    );

    final pdf = pw.Document();

    try {
      final fontData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final ttf = pw.Font.ttf(fontData.buffer.asByteData());

      final List<List<String>> tableData = [
        ['Detail', 'Value'],
        ['Env Number', widget.envNumber],
        ['Student Name', feeData?['studentName'] ?? 'N/A'],
        ['Route', feeData?['route'] ?? 'N/A'],
        ['Fee Amount', '${feeData?['feeAmount'] ?? '0'} INR'],
        [
          'Duration',
          (feeData?['duration'] ?? 'N/A')
              .replaceAll('month', ' Month')
              .replaceAll('year', ' Year'),
        ],
        ['Paid Status', feeData?['isPaid'] == true ? "Yes" : "No"],
      ];

      if (feeData?['paymentDate'] != null) {
        tableData.add([
          'Payment Date',
          DateFormat('MMM dd, yyyy').format(
            DateTime.tryParse(feeData!['paymentDate']) ?? DateTime.now(),
          ),
        ]);
      }
      if (feeData?['transactionId'] != null) {
        tableData.add(['Transaction ID', feeData!['transactionId']]);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'UTU Student PassYojna',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 30,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.cyan900,
                      ),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      'Bus Pass Fee Details',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 18,
                        color: PdfColors.cyan700,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.cyan400, thickness: 1),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Student Information:',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Name: ${feeData?['studentName'] ?? 'N/A'}',
                    style: pw.TextStyle(font: ttf, fontSize: 16),
                  ),
                  pw.Text(
                    'Enrollment Number: ${widget.envNumber}',
                    style: pw.TextStyle(font: ttf, fontSize: 16),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Fee Breakdown:',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    headers: tableData[0],
                    data: tableData.sublist(1),
                    border: pw.TableBorder.all(
                      color: PdfColors.cyan400,
                      width: 1,
                    ),
                    headerStyle: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 14,
                    ),
                    cellStyle: pw.TextStyle(font: ttf, fontSize: 12),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.cyan,
                    ),
                    cellAlignment: pw.Alignment.centerLeft,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(3),
                    },
                    cellPadding: const pw.EdgeInsets.all(8),
                  ),
                  pw.Expanded(child: pw.SizedBox()),
                  pw.Align(
                    alignment: pw.Alignment.bottomRight,
                    child: pw.Text(
                      'Generated on: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/FeeDetails_${widget.envNumber}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open PDF: ${result.message}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PDF exported successfully and opened."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          'Fee Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                : (feeData == null || feeData!.isEmpty)
                ? Center(
                  child: Text(
                    'No fee details available for Enrollment Number: ${widget.envNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                )
                : SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top:
                        kToolbarHeight +
                        MediaQuery.of(context).padding.top +
                        20,
                    bottom: 30,
                  ),
                  child: Column(
                    children: [
                      _buildLiquidGlassDetailCard(
                        Icons.tag,
                        Colors.cyanAccent,
                        'Env Number',
                        widget.envNumber,
                      ),
                      _buildLiquidGlassDetailCard(
                        Icons.person,
                        Colors.greenAccent,
                        'Student Name',
                        feeData!['studentName'] ?? 'N/A',
                      ),
                      _buildLiquidGlassDetailCard(
                        Icons.route,
                        Colors.orangeAccent,
                        'Route',
                        feeData!['route'] ?? 'N/A',
                      ),
                      _buildLiquidGlassDetailCard(
                        Icons.currency_rupee,
                        Colors.pinkAccent,
                        'Fee Amount',
                        '${feeData!['feeAmount'] ?? '0'} INR',
                      ),
                      _buildLiquidGlassDetailCard(
                        Icons.calendar_today,
                        Colors.cyanAccent,
                        'Duration',
                        (feeData!['duration'] ?? 'N/A')
                            .replaceAll('month', ' Month')
                            .replaceAll('year', ' Year'),
                      ),
                      _buildLiquidGlassDetailCard(
                        Icons.check_circle_outline,
                        feeData!['isPaid'] == true
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        'Paid Status',
                        feeData!['isPaid'] == true ? "Yes" : "No",
                      ),
                      if (feeData!['paymentDate'] != null)
                        _buildLiquidGlassDetailCard(
                          Icons.event,
                          Colors.purpleAccent,
                          'Payment Date',
                          DateFormat('MMM dd, yyyy').format(
                            DateTime.tryParse(feeData!['paymentDate']) ??
                                DateTime.now(),
                          ),
                        ),
                      if (feeData!['transactionId'] != null)
                        _buildLiquidGlassDetailCard(
                          Icons.receipt_long,
                          Colors.tealAccent,
                          'Transaction ID',
                          feeData!['transactionId'],
                        ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ElevatedButton.icon(
                          onPressed: _showExportPdfConfirmationDialog,
                          icon: const Icon(Icons.picture_as_pdf, size: 28),
                          label: const Text(
                            "Export as PDF",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 15,
                            shadowColor: Colors.cyan.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
