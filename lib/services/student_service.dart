import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final CollectionReference students =
      FirebaseFirestore.instance.collection('students');

  Future<void> addStudent({
    required String name,
    required String batch,
    String? mobile,
    required String fee,
  }) async {
    await students.add({
      'name': name,
      'batch': batch,
      'mobile': mobile ?? '',
      'monthlyFee': fee,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getStudents() {
    return students.orderBy('createdAt', descending: true).snapshots();
  }
}
