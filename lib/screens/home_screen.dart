import 'package:flutter/material.dart';
import 'student_list_screen.dart';
import 'attendance_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF2F2F7), Color(0xFFE5E5EA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                const Text("Classroom", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -1.2)),
                const Text("Manage your students & attendance", style: TextStyle(fontSize: 17, color: Colors.grey)),
                const SizedBox(height: 40),
                _buildGlassCard(
                  context,
                  title: "Take Attendance",
                  icon: Icons.how_to_reg_rounded,
                  color: const Color(0xFF007AFF),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())),
                ),
                const SizedBox(height: 16),
                _buildGlassCard(
                  context,
                  title: "Student Records",
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF34C759),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentListScreen())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}