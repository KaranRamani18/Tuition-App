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
  final AttendanceService service = AttendanceService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, dynamic> attendance = {};

  late DateTime selectedDate;
  late DateTime today;

  bool isHoliday = false;

  // 🔍 SEARCH + FILTER STATE
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

  void loadData() async {
    attendance = await service.getAttendance(dateKey);
    await checkHoliday();
    setState(() {});
  }

  // ---------------- HOLIDAY LOGIC ----------------

  Future<void> checkHoliday() async {
    final doc =
        await firestore.collection('holidays').doc(dateKey).get();
    isHoliday = doc.exists;
  }

  Future<void> markHoliday() async {
    if (!isAttendanceEditable()) return;

    await firestore.collection('holidays').doc(dateKey).set({
      'isHoliday': true,
    });

    setState(() {
      isHoliday = true;
      attendance.clear();
    });
  }

  Future<void> removeHoliday() async {
    if (!isAttendanceEditable()) return;

    await firestore.collection('holidays').doc(dateKey).delete();

    setState(() {
      isHoliday = false;
    });

    loadData();
  }

  // ---------------- LOCK LOGIC (2 DAYS) ----------------

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool isAttendanceEditable() {
    final todayDate = _normalize(today);
    final selected = _normalize(selectedDate);
    final difference = todayDate.difference(selected).inDays;
    return difference >= 0 && difference <= 2;
  }

  // ---------------- ATTENDANCE ----------------

  void toggleAttendance(String studentId, bool value) async {
    if (!isAttendanceEditable() || isHoliday) return;

    await service.markAttendance(dateKey, studentId, value);
    setState(() {
      attendance[studentId] = value;
    });
  }

  // ---------------- DATE NAVIGATION ----------------

  void goToPreviousDate() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
    loadData();
  }

  void goToNextDate() {
    if (isToday) return;

    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
    loadData();
  }

  bool get isToday {
    return DateFormat('yyyy-MM-dd').format(selectedDate) ==
        DateFormat('yyyy-MM-dd').format(today);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final editable = isAttendanceEditable();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: Column(
        children: [
          // DATE + HOLIDAY SECTION (UNCHANGED)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: goToPreviousDate,
                    ),
                    Text(
                      dateKey,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: isToday ? null : goToNextDate,
                    ),
                  ],
                ),

                if (!editable)
                  const Text(
                    'Attendance is locked for this date',
                    style: TextStyle(color: Colors.red),
                  ),

                if (isHoliday)
                  const Text(
                    'Holiday / No Class',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                if (editable)
                  TextButton(
                    onPressed:
                        isHoliday ? removeHoliday : markHoliday,
                    child: Text(
                      isHoliday
                          ? 'Remove Holiday'
                          : 'Mark as Holiday',
                    ),
                  ),
              ],
            ),
          ),

          // 🔽 CLASS / BATCH FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<QuerySnapshot>(
              stream: StudentService().getStudents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final batches = snapshot.data!.docs
                    .map((e) => e['batch'] as String)
                    .toSet()
                    .toList();

                return DropdownButtonFormField<String>(
                  value: selectedBatch.isEmpty
                      ? null
                      : selectedBatch,
                  hint: const Text('Select Class / Batch'),
                  items: batches.map((batch) {
                    return DropdownMenuItem(
                      value: batch,
                      child: Text(batch),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBatch = value!;
                      searchText = '';
                    });
                  },
                );
              },
            ),
          ),

          // 🔍 SEARCH BAR
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              enabled: selectedBatch.isNotEmpty,
              decoration: InputDecoration(
                hintText: selectedBatch.isEmpty
                    ? 'Select class first'
                    : 'Search student name',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // STUDENT LIST (FILTERED)
          Expanded(
            child: isHoliday
                ? const Center(
                    child: Text(
                      'No attendance required for this day',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: StudentService().getStudents(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final students =
                          snapshot.data!.docs.where((student) {
                        if (selectedBatch.isEmpty) return false;

                        final name = student['name']
                            .toString()
                            .toLowerCase();
                        final batch =
                            student['batch'].toString();

                        final matchesBatch =
                            batch == selectedBatch;
                        final matchesSearch = searchText.isEmpty ||
                            name.contains(searchText);

                        return matchesBatch && matchesSearch;
                      }).toList();

                      return ListView(
                        children: students.map((student) {
                          final present =
                              attendance[student.id] ?? false;

                          return SwitchListTile(
                            title: Text(student['name']),
                            subtitle: Text(student['batch']),
                            value: present,
                            onChanged: editable
                                ? (value) => toggleAttendance(
                                    student.id, value)
                                : null,
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
