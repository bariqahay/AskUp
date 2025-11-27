import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'deep_link_handler.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ynptioatjdujbcblwcwu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlucHRpb2F0amR1amJjYmx3Y3d1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MjEyMjMsImV4cCI6MjA3OTE5NzIyM30.7b2HJHudbrKyfM3phCjRxOV4ItSB9UcGmXlsZ7Ry_14',
  );
  runApp(const DeepLinkHandler(child: AskUpApp()));
}

class AskUpApp extends StatelessWidget {
  const AskUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AskUp+',
      debugShowCheckedModeBanner: false,
      home: const InitialScreen(),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final session = supabase.auth.currentSession;

    if (session != null) {
      final prefs = await SharedPreferences.getInstance();
      final lecturerId = prefs.getString('lecturer_id');
      final lecturerName = prefs.getString('lecturer_name');

      if (lecturerId != null && lecturerName != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DashboardScreen(lecturerId: lecturerId, lecturerName: lecturerName),
          ),
        );
        return;
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
