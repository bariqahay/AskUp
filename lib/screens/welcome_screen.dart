import 'package:flutter/material.dart';
import '../widgets/role_card.dart';
import 'lecturer_login_screen.dart';
import 'student_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B9BD5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      'A+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'Welcome to AskUp+',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose your role to get started',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                // Lecturer Role
                RoleCard(
                  iconPlaceholder: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B9BD5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  title: 'LECTURER',
                  subtitle: 'Manage Classes',
                  description: 'Create sessions, manage Q&A, and run polls',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LecturerLoginScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Student Role
                RoleCard(
                  iconPlaceholder: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  title: 'STUDENT',
                  subtitle: 'Join Classes',
                  description: 'Ask questions, participate in polls, and check-in',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StudentLoginScreen()),
                    );
                  },
                ),
                const SizedBox(height: 60),
                Text(
                  'Need help? Contact your IT administrator',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


