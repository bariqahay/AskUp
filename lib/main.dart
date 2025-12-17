import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/lecturer_login_screen.dart';
import 'themes/app_theme.dart';

// Global key untuk restart app saat theme berubah
final GlobalKey<_AskUpAppState> appKey = GlobalKey<_AskUpAppState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ynptioatjdujbcblwcwu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlucHRpb2F0amR1amJjYmx3Y3d1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MjEyMjMsImV4cCI6MjA3OTE5NzIyM30.7b2HJHudbrKyfM3phCjRxOV4ItSB9UcGmXlsZ7Ry_14',
  );
  runApp(AskUpApp(key: appKey));
}

class AskUpApp extends StatefulWidget {
  const AskUpApp({super.key});

  @override
  State<AskUpApp> createState() => _AskUpAppState();
}

class _AskUpAppState extends State<AskUpApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeStr = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeModeStr,
        orElse: () => ThemeMode.system,
      );
    });
  }

  // Method untuk update theme dari luar (dipanggil dari ThemeSwitcher)
  void updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AskUp+',
      debugShowCheckedModeBanner: false,
      
      // 🌙 Dark Mode Support
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,

      // 🔥 daftar semua named routes
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LecturerLoginScreen(),
      },

      // 🔥 start dari InitialScreen
      home: const InitialScreen(),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _controller.forward();
    _checkSession();
  }

  void _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    final session = supabase.auth.currentSession;

    if (session != null) {
      final prefs = await SharedPreferences.getInstance();
      final lecturerId = prefs.getString('lecturer_id');
      final lecturerName = prefs.getString('lecturer_name');

      if (lecturerId != null && lecturerName != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              lecturerId: lecturerId,
              lecturerName: lecturerName,
            ),
          ),
        );
        return;
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [Color(0xFF1A237E), Color(0xFF0D47A1)]
              : [Color(0xFF5B9FED), Color(0xFF4A8FDD)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'A+',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B9FED),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              
              // Text Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'AskUp+',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Interactive Q&A Platform',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48),
              
              // Loading Indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}