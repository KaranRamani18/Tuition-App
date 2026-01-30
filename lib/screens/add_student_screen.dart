import 'package:flutter/material.dart';
import '../services/student_service.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final nameController = TextEditingController();
  final batchController = TextEditingController();
  final mobileController = TextEditingController();
  final feeController = TextEditingController();
  final StudentService service = StudentService();

  void saveStudent() async {
    await service.addStudent(
      name: nameController.text,
      batch: batchController.text,
      mobile: mobileController.text,
      fee: feeController.text,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: batchController, decoration: const InputDecoration(labelText: 'Batch')),
            TextField(controller: mobileController, decoration: const InputDecoration(labelText: 'Mobile')),
            TextField(controller: feeController, decoration: const InputDecoration(labelText: 'Monthly Fee')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: saveStudent, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
