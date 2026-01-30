import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> loginTeacher(String username, String password) async {
    final doc =
        await _firestore.collection('admin').doc('teacher').get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    return data['username'] == username &&
        data['password'] == password;
  }
}
