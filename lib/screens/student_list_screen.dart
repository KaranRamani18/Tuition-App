import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/student_service.dart';
import 'add_student_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Students Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const AddStudentScreen())
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => searchText = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search by student name...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: StudentService().getStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs.where((doc) {
                  return doc['name'].toString().toLowerCase().contains(searchText);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                          child: Text(data['name'][0], 
                            style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Batch: ${data['batch']} • Fee: ₹${data['monthlyFee']}'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          // You can add a 'Student Detail' screen later here
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No students found", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}