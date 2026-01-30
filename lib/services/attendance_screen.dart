import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/attendance_service.dart';
import '../services/student_service.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic> attendanceData = {};

  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  void _loadAttendance() async {
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final data = await _attendanceService.getAttendance(dateKey);
    setState(() => attendanceData = data);
  }

  void _toggleAttendance(String studentId, bool value) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    await _attendanceService.markAttendance(dateKey, studentId, value);
    setState(() => attendanceData[studentId] = value);
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance ($dateKey)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: StudentService().getStudents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          return ListView(
            children: students.map((student) {
              final studentId = student.id;
              final isPresent = attendanceData[studentId] ?? false;

              return SwitchListTile(
                title: Text(student['name']),
                subtitle: Text(student['batch']),
                value: isPresent,
                onChanged: (value) =>
                    _toggleAttendance(studentId, value),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
