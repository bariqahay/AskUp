import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _updatePassword() async {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _show('Please fill all fields');
      return;
    }

    if (newPass.length < 8) {
      _show('Password must be at least 8 characters');
      return;
    }

    if (newPass != confirmPass) {
      _show('Passwords do not match');
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );

      if (!mounted) return;

      if (res.user != null) {
        _show('Password updated successfully!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
        return;
      }

      _show('Failed to update password');
    } catch (e) {
      if (mounted) _show('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create New Password'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create a strong password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your password must be at least 8 characters long',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // New Password Field
                Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newPasswordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter new password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Confirm Password Field
                Text(
                  'Confirm Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B9BD5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
