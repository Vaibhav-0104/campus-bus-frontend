import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:logger/logger.dart';
import 'package:campus_bus_management/config/api_config.dart';

class AllocateBusScreen extends StatefulWidget {
  const AllocateBusScreen({super.key});

  @override
  State<AllocateBusScreen> createState() => _AllocateBusScreenState();
}

class _AllocateBusScreenState extends State<AllocateBusScreen> {
  final logger = Logger();

  // ────── Dashboard Colors ──────
  final Color bgStart = const Color(0xFF0A0E1A);
  final Color bgMid = const Color(0xFF0F172A);
  final Color bgEnd = const Color(0xFF1E293B);
  // Color.withValues replaced with Color.withAlpha for safer use
  final Color glassBg = Colors.white.withAlpha(0x14);
  final Color glassBorder = Colors.white.withAlpha(0x26);
  final Color textSecondary = Colors.white70;
  final Color busYellow = const Color(0xFFFBBF24);

  // ────── Data ──────
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> buses = [];
  List<Map<String, dynamic>> allocations = [];
  List<String> toDestinations = [];
  List<String> departments = [];
  List<Map<String, dynamic>> filteredStudents = [];
  String? selectedStudentId;
  String studentName = '';
  String? selectedTo;
  String? selectedBusId;
  String? selectedSeatNumber;
  String? editingAllocationId;
  String? selectedDepartment;
  List<Map<String, dynamic>> filteredBuses = [];
  List<String> availableSeats = [];
  List<String> allocatedSeats = [];
  bool isLoadingStudents = true;
  bool isLoadingSeats = false;

  @override
  void initState() {
    super.initState();
    fetchStudents();
    fetchBuses();
    fetchAllocations();
  }

  // ────── API Calls ──────
  Future<void> fetchStudents() async {
    try {
      setState(() => isLoadingStudents = true);
      final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/students'));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        setState(() {
          students = List<Map<String, dynamic>>.from(
            data.map(
              (s) => {
                'id': s['_id'],
                'envNumber': s['envNumber'],
                'name': s['name'] ?? 'Unknown',
                'department': s['department'] ?? 'Unknown',
              },
            ),
          );
          departments =
              students
                  .map((s) => s['department'] as String)
                  .where((d) => d.isNotEmpty && d != 'Unknown')
                  .toSet()
                  .toList();
          filteredStudents = students;
          isLoadingStudents = false;
        });
      } else {
        _snack('Failed to load students');
        setState(() => isLoadingStudents = false);
      }
    } catch (e) {
      _snack('Error: $e');
      setState(() => isLoadingStudents = false);
    }
  }

  Future<void> fetchBuses() async {
    try {
      final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/buses'));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        setState(() {
          buses = List<Map<String, dynamic>>.from(
            data.map(
              (b) => {
                'id': b['_id'],
                'busNumber': b['busNumber'],
                'to': b['to'] ?? '',
                'capacity': b['capacity'] ?? 0,
                'allocatedSeats': List<String>.from(
                  (b['allocatedSeats'] ?? []).map((s) => s.toString()),
                ),
              },
            ),
          );
          toDestinations =
              buses
                  .map((b) => b['to'] as String)
                  .where((t) => t.isNotEmpty)
                  .toSet()
                  .toList();
        });
      } else {
        _snack('Failed to load buses');
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> fetchAllocations() async {
    try {
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/allocations/allocations'),
      );
      if (r.statusCode == 200) {
        setState(
          () =>
              allocations = List<Map<String, dynamic>>.from(
                json.decode(r.body),
              ),
        );
      } else {
        _snack('Failed to load allocations');
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> fetchAvailableSeats(String busId) async {
    try {
      setState(() => isLoadingSeats = true);
      final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/buses/$busId'));
      if (r.statusCode == 200) {
        final bus = json.decode(r.body);
        final capacity = bus['capacity'] as int;
        final allocated = List<String>.from(
          (bus['allocatedSeats'] ?? []).map((s) => s.toString()),
        );
        final all = List.generate(capacity, (i) => (i + 1).toString());

        setState(() {
          allocatedSeats = allocated;
          availableSeats = all.where((s) => !allocated.contains(s)).toList();
          isLoadingSeats = false;
        });

        final idx = buses.indexWhere((b) => b['id'] == busId);
        if (idx != -1) setState(() => buses[idx]['allocatedSeats'] = allocated);
        _updateAllocatedSeatsFromAllocations();
      } else {
        _snack('Failed to load bus');
        setState(() => isLoadingSeats = false);
      }
    } catch (e) {
      _snack('Error: $e');
      setState(() => isLoadingSeats = false);
    }
  }

  void _updateAllocatedSeatsFromAllocations() {
    if (selectedBusId == null) return;
    final extra =
        allocations
            .where((a) => a['busId']?['_id'] == selectedBusId)
            .map((a) => a['seatNumber']?.toString())
            .where((s) => s != null)
            .cast<String>()
            .toList();

    setState(() {
      allocatedSeats =
          [
            ...allocatedSeats,
            ...extra.where((s) => !allocatedSeats.contains(s)),
          ].toSet().toList();

      final cap =
          buses.firstWhere(
                (b) => b['id'] == selectedBusId,
                orElse: () => {'capacity': 0},
              )['capacity']
              as int;
      availableSeats =
          List.generate(
            cap,
            (i) => (i + 1).toString(),
          ).where((s) => !allocatedSeats.contains(s)).toList();
    });
  }

  // ────── CRUD ──────
  Future<void> allocateBus() async {
    if (selectedDepartment == null ||
        selectedStudentId == null ||
        selectedBusId == null ||
        selectedTo == null ||
        selectedSeatNumber == null) {
      _snack('Please fill all fields');
      return;
    }

    await fetchAvailableSeats(selectedBusId!);
    if (!availableSeats.contains(selectedSeatNumber)) {
      _snack('Seat no longer available');
      return;
    }

    final exists = allocations.firstWhere(
      (a) =>
          a['studentId']?['_id'] == selectedStudentId &&
          a['busId']?['_id'] == selectedBusId &&
          a['_id'] != editingAllocationId,
      orElse: () => {},
    );
    if (exists.isNotEmpty) {
      _snack('Student already allocated');
      return;
    }

    final payload = {
      'studentId': selectedStudentId,
      'busId': selectedBusId,
      'to': selectedTo,
      'seatNumber': selectedSeatNumber,
    };

    http.Response resp;
    String msg;
    if (editingAllocationId == null) {
      resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/allocations/allocate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      msg = 'Allocated!';
    } else {
      resp = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/allocations/$editingAllocationId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      msg = 'Updated!';
    }

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      await fetchAllocations();
      await fetchBuses();
      await fetchAvailableSeats(selectedBusId!);
      _snack(msg, true);
      _clearForm();
    } else {
      final err = jsonDecode(resp.body);
      _snack('Failed: ${err['message'] ?? 'Error'}');
    }
  }

  Future<void> deleteAllocation(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _confirmDialog(),
    );
    if (ok != true) return;

    try {
      final r = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/allocations/$id'),
      );
      if (r.statusCode == 200) {
        await fetchAllocations();
        await fetchBuses();
        if (selectedBusId != null) await fetchAvailableSeats(selectedBusId!);
        _snack('Deleted', true);
      } else {
        _snack('Delete failed');
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  void editAllocation(Map<String, dynamic> a) {
    setState(() {
      editingAllocationId = a['_id'];
      selectedStudentId = a['studentId']?['_id'];
      studentName = a['studentId']?['name'] ?? '';
      selectedDepartment = a['studentId']?['department'];
      selectedTo = a['to'] ?? a['busId']?['to'];
      selectedBusId = a['busId']?['_id'];
      selectedSeatNumber = a['seatNumber']?.toString();

      filterBusesByTo(selectedTo);
      filterStudentsByDepartment(selectedDepartment);
      if (selectedBusId != null) fetchAvailableSeats(selectedBusId!);
    });
  }

  void filterBusesByTo(String? to) {
    setState(() {
      selectedTo = to;
      selectedBusId = null;
      selectedSeatNumber = null;
      availableSeats = [];
      allocatedSeats = [];
      filteredBuses =
          to != null ? buses.where((b) => b['to'] == to).toList() : [];
    });
  }

  void filterStudentsByDepartment(String? dept) {
    setState(() {
      selectedDepartment = dept;
      selectedStudentId = null;
      studentName = '';
      filteredStudents =
          dept != null
              ? students.where((s) => s['department'] == dept).toList()
              : students;
    });
  }

  void _clearForm() {
    setState(() {
      selectedStudentId = null;
      studentName = '';
      selectedDepartment = null;
      selectedTo = null;
      selectedBusId = null;
      selectedSeatNumber = null;
      editingAllocationId = null;
      filteredBuses = [];
      filteredStudents = students;
      availableSeats = [];
      allocatedSeats = [];
    });
  }

  void _snack(String msg, [bool success = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ────── UI Helpers ──────
  Widget _glassCard({required Widget child, VoidCallback? onTap}) {
    return StatefulBuilder(
      builder: (ctx, set) {
        bool pressed = false;
        return GestureDetector(
          onTapDown: onTap != null ? (_) => set(() => pressed = true) : null,
          onTapUp:
              onTap != null
                  ? (_) {
                    set(() => pressed = false);
                    Future.delayed(const Duration(milliseconds: 100), onTap);
                  }
                  : null,
          onTapCancel: onTap != null ? () => set(() => pressed = false) : null,
          child: AnimatedScale(
            scale: pressed ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()..translate(0.0, pressed ? -4 : 0.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: glassBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: glassBorder, width: 1.2),
                      boxShadow:
                          pressed
                              ? [
                                BoxShadow(
                                  color: Colors.white.withAlpha(0x26),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                              : null,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: glassBg,
        border: Border.all(color: glassBorder, width: 1.2),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: TextStyle(color: textSecondary)),
        style: const TextStyle(color: Colors.white),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        dropdownColor: bgMid,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: busYellow, size: 24),
          labelText: hint,
          labelStyle: TextStyle(color: textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: items,
        onChanged: items.isNotEmpty ? onChanged : null,
      ),
    );
  }

  Widget _readOnly(String text, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: glassBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: glassBorder, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, color: busYellow, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ────── SEAT DIALOG (FIXED OVERFLOW) ──────
  Future<void> _showSeatingDialog() async {
    if (selectedBusId == null) return;
    final bus = buses.firstWhere(
      (b) => b['id'] == selectedBusId,
      orElse: () => {'busNumber': '??', 'capacity': 0},
    );
    final busNumber = bus['busNumber'] as String;
    String? localSeat = selectedSeatNumber;

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (ctx, setDialog) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: glassBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: glassBorder, width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Select Seat Bus: $busNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // LEGEND (FIX: Changed from Row to Wrap to handle overflow on small screens)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12.0, // Horizontal space between items
                              runSpacing:
                                  8.0, // Vertical space between lines if wrapped
                              children: [
                                _legendItem(busYellow, 'Available'),
                                _legendItem(Colors.redAccent, 'Allocated'),
                                _legendItem(Colors.green, 'Selected'),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // FLEXIBLE GRID – NO OVERFLOW
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 500),
                              child: SingleChildScrollView(
                                child:
                                    isLoadingSeats
                                        ? Center(
                                          child: CircularProgressIndicator(
                                            color: busYellow,
                                          ),
                                        )
                                        : availableSeats.isEmpty
                                        ? const Text(
                                          'No seats available',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        )
                                        : _seatGrid(
                                          localSeat,
                                          (s) => setDialog(() => localSeat = s),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // BUTTONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade700,
                                  ),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      localSeat != null
                                          ? () {
                                            setState(
                                              () =>
                                                  selectedSeatNumber =
                                                      localSeat,
                                            );
                                            Navigator.pop(ctx);
                                          }
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: busYellow,
                                  ),
                                  child: const Text(
                                    'Confirm',
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  // Uses childAspectRatio: 1.0 for robust seat sizing without manual width calculation errors.
  Widget _seatGrid(String? selected, Function(String?) onSelect) {
    final bus = buses.firstWhere(
      (b) => b['id'] == selectedBusId,
      orElse: () => {'capacity': 0},
    );
    final capacity = bus['capacity'] as int;
    const cols = 5;
    final rows = (capacity / 4).ceil();
    const spacing = 12.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio:
            1.0, // Ensures a square seat (height = width) and uses all available space perfectly.
      ),
      itemCount: rows * cols,
      itemBuilder: (ctx, i) {
        final row = i ~/ cols;
        final col = i % cols;

        if (col == 2) {
          // Aisle logic remains the same
          return const Center(
            child: Text(
              'Aisle',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          );
        }

        final seatIdx = row * 4 + (col < 2 ? col : col - 1);
        if (seatIdx >= capacity) return const SizedBox();

        final seat = (seatIdx + 1).toString();
        final isAllocated = allocatedSeats.contains(seat);
        final isSelected = selected == seat;

        return GestureDetector(
          onTap: isAllocated ? null : () => onSelect(seat),
          child: Container(
            decoration: BoxDecoration(
              color:
                  isAllocated
                      ? Colors.redAccent.withAlpha(0xE6)
                      : isSelected
                      ? Colors.green.withAlpha(0xE6)
                      : busYellow.withAlpha(0xB3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white : glassBorder,
                width: isSelected ? 3 : 1.5,
              ),
            ),
            child: Center(
              child: Text(
                seat,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _legendItem(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Important for use inside Wrap
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _confirmDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: glassBg,
      title: const Text(
        'Confirm Delete',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'Delete this allocation?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  // ────── MAIN UI ──────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus, color: busYellow, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Allocate Bus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.white.withAlpha(0x0D)),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgStart, bgMid, bgEnd],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  _glassCard(
                    child: Column(
                      children: [
                        Text(
                          editingAllocationId == null
                              ? 'New Allocation'
                              : 'Edit Allocation',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        isLoadingStudents
                            ? Center(
                              child: CircularProgressIndicator(
                                color: busYellow,
                              ),
                            )
                            : _dropdown(
                              value: selectedDepartment,
                              hint: 'Department',
                              items:
                                  departments
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d),
                                        ),
                                      )
                                      .toList(),
                              onChanged: filterStudentsByDepartment,
                              icon: Icons.school,
                            ),
                        const SizedBox(height: 16),

                        _dropdown(
                          value: selectedStudentId,
                          hint: 'Enrollment No.',
                          items:
                              filteredStudents
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s['id'] as String,
                                      child: Text(s['envNumber']),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            setState(() {
                              selectedStudentId = v;
                              final st = filteredStudents.firstWhere(
                                (s) => s['id'] == v,
                                orElse: () => {'name': ''},
                              );
                              studentName = st['name'] as String;
                            });
                          },
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _readOnly(
                          studentName.isEmpty ? 'Student Name' : studentName,
                          Icons.person,
                        ),

                        const SizedBox(height: 16),
                        _dropdown(
                          value: selectedTo,
                          hint: 'To Destination',
                          items:
                              toDestinations
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                          onChanged: filterBusesByTo,
                          icon: Icons.location_on,
                        ),
                        const SizedBox(height: 16),

                        _dropdown(
                          value: selectedBusId,
                          hint: 'Bus',
                          items:
                              filteredBuses
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b['id'] as String,
                                      child: Text(b['busNumber']),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) async {
                            setState(() {
                              selectedBusId = v;
                              selectedSeatNumber = null;
                            });
                            if (v != null) {
                              await fetchAvailableSeats(v);
                              if (mounted) _showSeatingDialog();
                            }
                          },
                          icon: Icons.directions_bus,
                        ),
                        const SizedBox(height: 16),

                        _readOnly(
                          selectedSeatNumber == null
                              ? 'No Seat Selected'
                              : 'Seat $selectedSeatNumber',
                          Icons.event_seat,
                          onTap:
                              selectedBusId == null
                                  ? () => _snack('Select a bus first')
                                  : () async {
                                    await fetchAvailableSeats(selectedBusId!);
                                    if (mounted) _showSeatingDialog();
                                  },
                        ),
                        const SizedBox(height: 24),

                        // LEGEND (FIX: Changed from Row to Wrap here too)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12.0,
                          runSpacing: 8.0,
                          children: [
                            _legendItem(busYellow, 'Available'),
                            _legendItem(Colors.redAccent, 'Allocated'),
                            _legendItem(Colors.green, 'Selected'),
                          ],
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: allocateBus,
                                icon: const Icon(Icons.save),
                                label: Text(
                                  editingAllocationId == null
                                      ? 'Save'
                                      : 'Update',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: busYellow,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _clearForm,
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _glassCard(
                    child:
                        allocations.isEmpty
                            ? const Center(
                              child: Text(
                                'No allocations yet',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                            : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStatePropertyAll(
                                  busYellow.withAlpha(0x33),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Student',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Bus',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'To',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Seat',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Actions',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows:
                                    allocations.map((a) {
                                      final s = a['studentId'];
                                      final b = a['busId'];
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              s?['name'] ?? '-',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              b?['busNumber'] ?? '-',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              a['to'] ?? b?['to'] ?? '-',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              a['seatNumber']?.toString() ??
                                                  '-',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: busYellow,
                                                  ),
                                                  onPressed:
                                                      () => editAllocation(a),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.redAccent,
                                                  ),
                                                  onPressed:
                                                      () => deleteAllocation(
                                                        a['_id'],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
