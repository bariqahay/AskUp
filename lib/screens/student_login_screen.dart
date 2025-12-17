import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_dashboard_screen.dart';
import 'forgot_password_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

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
      if (mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Email & Password cannot be empty");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil RPC login_student
      final response = await supabase.rpc(
        'login_student',
        params: {
          'email_in': email,
          'password_in': password,
        },
      );

      final userData = response;

      if (userData == null) {
        _showSnackBar("Login failed: no response from server");
        return;
      }

      // Handle error dari RPC
      if (userData is Map && userData['error'] != null) {
        final err = userData['error'].toString();
        if (err == 'email_not_found') {
          _showSnackBar("Email not registered as student");
        } else if (err == 'invalid_password') {
          _showSnackBar("Invalid password");
        } else {
          _showSnackBar("Login error: $err");
        }
        return;
      }

      // Ambil id + nama dari response RPC
      String studentId = '';
      String studentName = 'Student';

      if (userData is Map) {
        studentId = userData['id']?.toString() ?? '';
        studentName = userData['name']?.toString() ??
            userData['full_name']?.toString() ??
            userData['username']?.toString() ??
            'Student';
      } else {
        _showSnackBar("Unexpected response format");
        return;
      }

      // Save shared prefs
      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        await prefs.setString('student_saved_email', email);
        await prefs.setString('student_saved_password', password);
      } else {
        await prefs.remove('student_saved_email');
        await prefs.remove('student_saved_password');
      }

      await prefs.setString('student_id', studentId);
      await prefs.setString('student_name', studentName);

      // Navigate ke Dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDashboardScreen(
              studentId: studentId,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar("Unexpected error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[50];
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final cardColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[400];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Student Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to join classes and participate',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    _buildInputField(
                      'Email Address',
                      false,
                      _emailController,
                      (value) => _passwordFocus.requestFocus(),
                      textColor: textColor,
                      cardColor: cardColor,
                      hintColor: hintColor,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    _buildInputField(
                      'Password',
                      true,
                      _passwordController,
                      null,
                      focusNode: _passwordFocus,
                      textColor: textColor,
                      cardColor: cardColor,
                      hintColor: hintColor,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 12),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xFFF5A623),
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value ?? false),
                            ),
                            Text(
                              'Remember me',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFFF5A623),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5A623),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'SIGN IN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Text(
                      "By signing in, you agree to the University's Terms of Service",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    bool obscure,
    TextEditingController controller,
    Function(String)? onSubmitted, {
    FocusNode? focusNode,
    required Color textColor,
    required Color cardColor,
    required Color? hintColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure ? !_isPasswordVisible : false,
          focusNode: focusNode,
          onSubmitted: onSubmitted,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: obscure ? 'Enter your password' : 'Enter your email',
            hintStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(
              obscure ? Icons.lock_outline : Icons.email_outlined,
              color: const Color(0xFFF5A623),
            ),
            suffixIcon: obscure
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: isDark ? Colors.grey[400] : Colors.grey,
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF5A623), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}