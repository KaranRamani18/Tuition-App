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

  void save() async {
    if (nameController.text.isEmpty) return;
    await StudentService().addStudent(
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
      appBar: AppBar(
        title: const Text("New Student"),
        actions: [TextButton(onPressed: save, child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)))]
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildAppleInput(nameController, "Name", Icons.person),
            _buildAppleInput(batchController, "Batch", Icons.class_outlined),
            _buildAppleInput(mobileController, "Mobile", Icons.phone_iphone),
            _buildAppleInput(feeController, "Monthly Fee", Icons.currency_rupee),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleInput(TextEditingController controller, String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(icon: Icon(icon, size: 20, color: Colors.grey), labelText: label, border: InputBorder.none),
      ),
    );
  }
}