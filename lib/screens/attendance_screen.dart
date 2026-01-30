import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';
import '../services/student_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // --- YOUR ORIGINAL LOGIC VARIABLES ---
  final AttendanceService service = AttendanceService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, dynamic> attendance = {};
  late DateTime selectedDate;
  late DateTime today;
  bool isHoliday = false;

  String selectedBatch = '';
  String searchText = '';

  @override
  void initState() {
    super.initState();
    today = DateTime.now();
    selectedDate = today;
    loadData();
  }

  String get dateKey => DateFormat('yyyy-MM-dd').format(selectedDate);

  // --- YOUR ORIGINAL DATA LOADING ---
  void loadData() async {
    attendance = await service.getAttendance(dateKey);
    await checkHoliday();
    if (mounted) setState(() {});
  }

  bool get isSunday => selectedDate.weekday == DateTime.sunday; //

  Future<void> checkHoliday() async {
    final doc = await firestore.collection('holidays').doc(dateKey).get();
    isHoliday = doc.exists;
  }

  // --- YOUR ORIGINAL HOLIDAY/DATE ACTIONS ---
  Future<void> markHoliday() async {
    if (!isAttendanceEditable() || isSunday) return;
    await firestore.collection('holidays').doc(dateKey).set({'isHoliday': true});
    setState(() {
      isHoliday = true;
      attendance.clear();
    });
  }

  Future<void> removeHoliday() async {
    if (!isAttendanceEditable() || isSunday) return;
    await firestore.collection('holidays').doc(dateKey).delete();
    setState(() => isHoliday = false);
    loadData();
  }

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  bool isAttendanceEditable() {
    final todayDate = _normalize(today);
    final selected = _normalize(selectedDate);
    final difference = todayDate.difference(selected).inDays;
    return difference >= 0 && difference <= 2; //
  }

  void toggleAttendance(String studentId, bool value) async {
    if (!isAttendanceEditable() || isHoliday || isSunday) return;
    await service.markAttendance(dateKey, studentId, value);
    setState(() => attendance[studentId] = value);
  }

  void goToPreviousDate() {
    setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1)));
    loadData();
  }

  void goToNextDate() {
    if (isToday) return;
    setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
    loadData();
  }

  bool get isToday => DateFormat('yyyy-MM-dd').format(selectedDate) == DateFormat('yyyy-MM-dd').format(today);

  // --- "WORLD'S BEST" DESIGN IMPLEMENTATION ---
  @override
  Widget build(BuildContext context) {
    final editable = isAttendanceEditable();
    final noClassDay = isSunday || isHoliday;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.2)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(color: const Color(0xFFF2F2F7)),
          
          SafeArea(
            child: Column(
              children: [
                _buildGlassDateHeader(editable),
                _buildGlassFilters(noClassDay),
                Expanded(
                  child: noClassDay 
                    ? _buildGlassNoClassState() 
                    : _buildStudentList(editable),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassDateHeader(bool editable) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filledTonal(onPressed: goToPreviousDate, icon: const Icon(Icons.arrow_back_ios_new, size: 16)),
              Column(
                children: [
                  Text(DateFormat('EEEE').format(selectedDate), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(dateKey, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton.filledTonal(onPressed: isToday ? null : goToNextDate, icon: const Icon(Icons.arrow_forward_ios, size: 16)),
            ],
          ),
          if (!editable) const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('🔒 Locked (2-day limit)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          if (editable && !isSunday)
            TextButton.icon(
              onPressed: isHoliday ? removeHoliday : markHoliday,
              icon: Icon(isHoliday ? Icons.edit_calendar : Icons.beach_access, size: 18),
              label: Text(isHoliday ? 'Remove Holiday' : 'Mark as Holiday'),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassFilters(bool noClassDay) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // YOUR ORIGINAL BATCH DROPDOWN LOGIC
          StreamBuilder<QuerySnapshot>(
            stream: StudentService().getStudents(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final batches = snapshot.data!.docs.map((e) => e['batch'] as String).toSet().toList();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Select Batch"),
                    value: selectedBatch.isEmpty ? null : selectedBatch,
                    items: batches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) => setState(() { selectedBatch = v!; searchText = ''; }),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // YOUR ORIGINAL SEARCH LOGIC
          TextField(
            enabled: selectedBatch.isNotEmpty && !noClassDay,
            onChanged: (v) => setState(() => searchText = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search students...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(bool editable) {
    if (selectedBatch.isEmpty) return const Center(child: Text("Select a batch to start"));

    return StreamBuilder<QuerySnapshot>(
      stream: StudentService().getStudents(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // YOUR ORIGINAL FILTERING LOGIC
        final students = snapshot.data!.docs.where((s) {
          final matchesBatch = s['batch'] == selectedBatch;
          final matchesSearch = searchText.isEmpty || s['name'].toString().toLowerCase().contains(searchText);
          return matchesBatch && matchesSearch;
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final s = students[index];
            final present = attendance[s.id] ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: ListTile(
                title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("ID: ${s.id.substring(0,5)}"),
                trailing: Switch.adaptive(
                  value: present,
                  activeColor: const Color(0xFF34C759),
                  onChanged: editable ? (v) => toggleAttendance(s.id, v) : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlassNoClassState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSunday ? Icons.weekend : Icons.celebration, size: 80, color: Colors.blueGrey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(isSunday ? "Sunday - Rest Day" : "Holiday Declared", style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}