import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LecturerLoginScreen extends StatefulWidget {
  const LecturerLoginScreen({super.key});

  @override
  State<LecturerLoginScreen> createState() => _LecturerLoginScreenState();
}

class _LecturerLoginScreenState extends State<LecturerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool rememberMe = false;
  bool isLoading = false;
  bool _obscurePassword = true; // 🔑 penting

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        rememberMe = true;
      });
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

    setState(() => isLoading = true);

    try {
      final response = await supabase.rpc(
        'login_lecturer',
        params: {
          'email_in': email,
          'password_in': password,
        },
      );

      if (response is Map && response['error'] != null) {
        final err = response['error'];
        _showSnackBar(
          err == 'email_not_found'
              ? 'Email not registered'
              : err == 'invalid_password'
                  ? 'Invalid password'
                  : 'Login failed',
        );
        return;
      }

      final lecturerId = response['id'];
      final lecturerName = response['name'] ?? 'Lecturer';

      final prefs = await SharedPreferences.getInstance();

      if (rememberMe) {
        await prefs.setString('saved_email', email);
        await prefs.setString('saved_password', password);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }

      await prefs.setString('lecturer_id', lecturerId);
      await prefs.setString('lecturer_name', lecturerName);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            lecturerId: lecturerId,
            lecturerName: lecturerName,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar("Unexpected error");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
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
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B9BD5),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Lecturer Login',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    /// EMAIL
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'lecturer@university.ac.id',
                      icon: Icons.email_outlined,
                      obscure: false,
                      textColor: textColor,
                      cardColor: cardColor,
                      hintColor: hintColor,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 20),

                    /// PASSWORD
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      textColor: textColor,
                      cardColor: cardColor,
                      hintColor: hintColor,
                      focusNode: _passwordFocus,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (v) =>
                                  setState(() => rememberMe = v ?? false),
                            ),
                            Text('Remember me', style: TextStyle(color: textColor)),
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
                            style: TextStyle(color: Color(0xFF5B9BD5)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B9BD5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'SIGN IN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscure,
    required Color textColor,
    required Color cardColor,
    required Color? hintColor,
    FocusNode? focusNode,
    Widget? suffixIcon,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          focusNode: focusNode,
          onSubmitted: onSubmitted,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: cardColor,
            hintText: hint,
            hintStyle: TextStyle(color: hintColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
