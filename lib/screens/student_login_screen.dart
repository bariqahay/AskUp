import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_dashboard_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('student_saved_email');
    final savedPassword = prefs.getString('student_saved_password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Query student dari database
      final response = await supabase
          .from('users')
          .select('id, email, name, password, role')
          .eq('email', email)
          .eq('role', 'student')
          .maybeSingle();

      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not registered as student'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Check password
      if (response['password'] != password) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid password'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Save remember me preferences
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('student_saved_email', email);
        await prefs.setString('student_saved_password', password);
      } else {
        await prefs.remove('student_saved_email');
        await prefs.remove('student_saved_password');
      }

      // Login berhasil - navigate dengan studentId
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDashboardScreen(
              studentId: response['id'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Student Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Sign in to join classes and participate',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFF2D2D2D)),
                  decoration: InputDecoration(
                    hintText: 'Enter your student email',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFF5A623)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF5A623), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Color(0xFF2D2D2D)),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFF5A623)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF5A623), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFFF5A623),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Forgot password feature will be implemented'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFF5A623),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "By signing in, you agree to the University's Terms of Service",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
