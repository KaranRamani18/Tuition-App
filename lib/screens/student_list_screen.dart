import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/student_service.dart';
import 'add_student_screen.dart';

class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  // --- REPORT GENERATION LOGIC ---
  void _generateReport(BuildContext context, String studentId, String studentName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int presentCount = 0;
    int totalDays = 0;
    
    // Get current month and year
    DateTime now = DateTime.now();
    String monthYearPrefix = DateFormat('yyyy-MM').format(now); // e.g., "2026-01"

    // Fetch all attendance records for this month
    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: monthYearPrefix)
        .where(FieldPath.documentId, isLessThan: '${monthYearPrefix}z')
        .get();

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data();
      if (data.containsKey(studentId)) {
        totalDays++;
        if (data[studentId] == true) {
          presentCount++;
        }
      }
    }

    Navigator.pop(context); // Close loading indicator

    _showReportDialog(context, studentName, presentCount, totalDays);
  }

  void _showReportDialog(BuildContext context, String name, int present, int total) {
    int absent = total - present;
    double percentage = total == 0 ? 0 : (present / total) * 100;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("$name's Report", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            _reportRow("Total Working Days", "$total", Colors.black),
            _reportRow("Days Present", "$present", Colors.green),
            _reportRow("Days Absent", "$absent", Colors.red),
            const SizedBox(height: 20),
            Text("${percentage.toStringAsFixed(1)}%", 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: percentage > 75 ? Colors.green : Colors.orange)),
            const Text("Attendance Rate", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF007AFF)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen())),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: StudentService().getStudents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final studentId = doc.id;
              final studentName = doc['name'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: ListTile(
                  title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Batch: ${doc['batch']}'),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _generateReport(context, studentId, studentName),
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text("Report"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F2F7),
                      foregroundColor: const Color(0xFF007AFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}