import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;

  Future<void> _sendResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'myapp://reset-password',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset link sent. Check your email!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter your email address to reset your password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _sendResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B9BD5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Reset Password',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );

  }
}
