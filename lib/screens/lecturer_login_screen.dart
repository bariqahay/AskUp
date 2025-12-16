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
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  void _loadRememberMe() async {
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
      // Panggil RPC (return langsung Map, bukan .data)
      final response = await supabase.rpc(
        'login_lecturer',
        params: {
          'email_in': email,
          'password_in': password,
        },
      );

      // langsung pake response (NO .data)
      final userData = response;

      if (userData == null) {
        _showSnackBar("Login failed: no response from server");
        return;
      }

      // Handle error dari RPC (kalau return Map error)
      if (userData is Map && userData['error'] != null) {
        final err = userData['error'].toString();
        if (err == 'email_not_found') {
          _showSnackBar("Email not registered");
        } else if (err == 'invalid_password') {
          _showSnackBar("Invalid password");
        } else {
          _showSnackBar("Login error: $err");
        }
        return;
      }

      // Ambil id + nama dari response RPC (valid login)
      String lecturerId = '';
      String lecturerName = 'Lecturer';

      if (userData is Map) {
        lecturerId = userData['id']?.toString() ?? '';
        lecturerName = userData['name']?.toString()
            ?? userData['full_name']?.toString()
            ?? userData['username']?.toString()
            ?? 'Lecturer';
      } else {
        _showSnackBar("Unexpected response format");
        return;
      }

      // Save shared prefs (remember + lecturer info)
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

      // Navigate ke Dashboard
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
      _showSnackBar("Unexpected error: $e");
    } finally {
      setState(() => isLoading = false);
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                        color: const Color(0xFF5B9BD5),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 50),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Lecturer Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your classroom sessions',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                    _buildInputField(
                      'Email Address',
                      false,
                      _emailController,
                      (value) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      'Password',
                      true,
                      _passwordController,
                      null,
                      focusNode: _passwordFocus,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              activeColor: const Color(0xFF5B9BD5),
                              onChanged: (value) =>
                                  setState(() => rememberMe = value ?? false),
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                color: Color(0xFF2D2D2D),
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
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF5B9BD5),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
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
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'SIGN IN',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "By signing in, you agree to the University's Terms of Service",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildInputField(String label, bool obscure,
      TextEditingController controller, Function(String)? onSubmitted,
      {FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          focusNode: focusNode,
          onSubmitted: onSubmitted,
          style: const TextStyle(color: Color(0xFF2D2D2D)),
          decoration: InputDecoration(
            hintText: obscure ? 'Enter your password' : 'Enter your email',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(
              obscure ? Icons.lock_outline : Icons.email_outlined,
              color: const Color(0xFF5B9BD5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
              borderSide: const BorderSide(color: Color(0xFF5B9BD5), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
