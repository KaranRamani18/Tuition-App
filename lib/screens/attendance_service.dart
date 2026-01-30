import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final CollectionReference attendance =
      FirebaseFirestore.instance.collection('attendance');

  Future<void> markAttendance(
    String date,
    String studentId,
    bool present,
  ) async {
    await attendance.doc(date).set({
      studentId: present,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getAttendance(String date) async {
    final doc = await attendance.doc(date).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : {};
  }
}
