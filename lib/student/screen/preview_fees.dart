import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Required for ImageFilter for blur effects
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart'; // For date formatting if paymentDate is used
import 'package:path_provider/path_provider.dart'; // For getting application document directory
import 'package:pdf/pdf.dart'; // Core PDF package
import 'package:pdf/widgets.dart' as pw; // PDF widgets
import 'package:open_file/open_file.dart'; // For opening the generated PDF file
import 'package:flutter/services.dart'
    show rootBundle; // For loading assets like fonts

class PreviewFeesScreen extends StatefulWidget {
  final String envNumber;

  const PreviewFeesScreen({Key? key, required this.envNumber})
    : super(key: key);

  @override
  _PreviewFeesScreenState createState() => _PreviewFeesScreenState();
}

class _PreviewFeesScreenState extends State<PreviewFeesScreen> {
  Map<String, dynamic>? feeData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
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
            Uri.parse(
              'http://172.20.10.9:5000/api/fees/student/${widget.envNumber}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 15),
          ); // Add timeout for network requests

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
      print('Error fetching fee details: $e');
      setState(() {
        errorMessage = 'Network Error: Could not connect to the server.';
        isLoading = false;
      });
    }
  }

  // Reusable widget for a liquid glass detail card (key-value pair)
  Widget _buildLiquidGlassDetailCard(
    IconData icon,
    Color iconColor,
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blueGrey.shade300.withOpacity(0.15),
                  Colors.blueGrey.shade700.withOpacity(0.15),
                ],
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
                  offset: const Offset(-5, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // Use Expanded to ensure text wraps if it's too long
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 24), // Colorful icon
                      const SizedBox(
                        width: 12,
                      ), // Spacing between icon and title
                      Flexible(
                        // Flexible to prevent overflow if title is too long
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20, // Increased font size for title
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 3, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  // Flexible to prevent overflow if value is too long
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20, // Increased font size for value
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to show the export PDF confirmation dialog
  void _showExportPdfConfirmationDialog() {
    if (feeData == null || feeData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No fee data available to export."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
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
          backgroundColor: Colors.deepPurple.shade700.withOpacity(
            0.8,
          ), // Liquid glass dialog background
          title: const Text(
            "Export Fee Details",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
            ),
          ),
          content: Text(
            "Do you want to export the fee details for ${widget.envNumber} as a PDF?",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
              child: Text(
                "No",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss dialog
                await generateAndOpenPdf();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent, // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                "Yes, Export PDF",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> generateAndOpenPdf() async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Generating PDF..."),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    final pdf = pw.Document();

    // Load the font from assets (ensure you have this font in your assets/fonts/ directory)
    // Add 'assets/fonts/NotoSans-Regular.ttf' to your pubspec.yaml under assets:
    // flutter:
    //   assets:
    //     - assets/fonts/NotoSans-Regular.ttf
    try {
      final fontData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final ttf = pw.Font.ttf(fontData.buffer.asByteData());

      // Prepare fee details for the PDF table
      final List<List<String>> tableData = [
        ['Detail', 'Value'],
        ['Env Number', widget.envNumber],
        ['Student Name', feeData?['studentName'] ?? 'N/A'],
        ['Route', feeData?['route'] ?? 'N/A'],
        ['Fee Amount', '${feeData?['feeAmount'] ?? '0'} INR'],
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
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Center(
                  child: pw.Text(
                    'UTU Student PassYojna',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.deepPurple900,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Bus Pass Fee Details',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      color: PdfColors.deepPurple700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey400, thickness: 1),
                pw.SizedBox(height: 20),

                // Student Info Section
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

                // Fee Details Table
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
                    color: PdfColors.grey400,
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
                    color: PdfColors.deepPurple,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(3),
                  },
                  cellPadding: const pw.EdgeInsets.all(8),
                ),
                pw.Expanded(child: pw.SizedBox()), // Fills remaining space
                // Footer
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
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/FeeDetails_${widget.envNumber}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Open the generated PDF
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
      print('Error generating or opening PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating or opening PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Extend body behind app bar for full gradient
      appBar: AppBar(
        title: const Text(
          'Fee Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple.shade700.withOpacity(
          0.3,
        ), // Liquid glass app bar
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.redAccent.shade100,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                : (feeData == null || feeData!.isEmpty)
                ? Center(
                  child: Text(
                    'No fee details available for Enrollment Number: ${widget.envNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                : SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top:
                        AppBar().preferredSize.height +
                        MediaQuery.of(context).padding.top +
                        5,
                    bottom: 5.0, // Added padding for the button
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLiquidGlassDetailCard(
                        Icons.tag,
                        Colors.lightBlueAccent,
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
                        Icons.check_circle_outline,
                        feeData!['isPaid'] == true
                            ? Colors.lightGreenAccent
                            : Colors.redAccent,
                        'Paid Status',
                        feeData!['isPaid'] == true ? "Yes" : "No",
                      ),
                      if (feeData!['paymentDate'] != null)
                        _buildLiquidGlassDetailCard(
                          Icons.calendar_today,
                          Colors.purpleAccent,
                          'Payment Date',
                          // Format date for better readability if it's a valid date string
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

                      const SizedBox(height: 5), // Spacing before the button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton(
                          onPressed: _showExportPdfConfirmationDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade600
                                .withOpacity(0.8), // Darker liquid glass button
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                30,
                              ), // More rounded button
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ), // Subtle border
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ), // Larger padding
                            shadowColor: Colors.black.withOpacity(0.4),
                            elevation: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.picture_as_pdf,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Export as PDF",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 5,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
