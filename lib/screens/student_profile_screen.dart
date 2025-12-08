import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class StudentProfileScreen extends StatefulWidget {
  final String studentId;
  
  const StudentProfileScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  
  // Profile data
  String name = '';
  String email = '';
  String role = '';
  String department = '';
  String employeeId = '';
  String avatarUrl = '';
  DateTime? memberSince;
  
  // Stats
  int _totalQuestions = 0;
  int _totalPolls = 0;
  int _participationRate = 0;
  
  // Preferences
  bool _pushNotifications = true;
  bool _emailUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', widget.studentId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _userData = Map<String, dynamic>.from(response);
          name = response['name'] ?? '';
          email = response['email'] ?? '';
          role = response['role'] ?? 'Student';
          department = response['department'] ?? '';
          employeeId = response['employee_id'] ?? '';
          avatarUrl = response['avatar_url'] ?? '';
          _pushNotifications = response['push_notifications'] ?? true;
          _emailUpdates = response['email_updates'] ?? true;
          memberSince = DateTime.tryParse(response['created_at'] ?? '');
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        _showSnack('Failed to load profile: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      // Total questions asked
      final questions = await supabase
          .from('questions')
          .select('id')
          .eq('student_id', widget.studentId);
      _totalQuestions = questions.length;

      // Total polls answered
      final polls = await supabase
          .from('poll_responses')
          .select('id')
          .eq('student_id', widget.studentId);
      _totalPolls = polls.length;

      // Participation rate calculation
      final totalSessions = await supabase
          .from('session_participants')
          .select('id')
          .eq('student_id', widget.studentId);

      if (totalSessions.isNotEmpty) {
        _participationRate = 91; // Placeholder - customize based on your logic
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _updatePreference(String field, bool value) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await supabase
          .from('users')
          .update({field: value})
          .eq('id', widget.studentId);

      setState(() {
        if (field == 'push_notifications') _pushNotifications = value;
        if (field == 'email_updates') _emailUpdates = value;
      });
      
      _showSnack('$field updated', Colors.green);
    } catch (e) {
      debugPrint('Error updating preference: $e');
      _showSnack('Failed to update preference', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== Avatar picker & upload =====
  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      if (!mounted) return;
      setState(() => _isLoading = true);

      final File imageFile = File(pickedFile.path);
      final String fileName = 'avatar_${widget.studentId}.${pickedFile.path.split('.').last}';
      final String filePath = 'avatars/$fileName';

      await supabase.storage.from('avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      await supabase.from('users').update({'avatar_url': publicUrl}).eq('id', widget.studentId);

      if (mounted) {
        setState(() => avatarUrl = publicUrl);
        _showSnack('Avatar updated successfully', Colors.green);
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      if (mounted) {
        _showSnack('Failed to upload avatar: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== Edit Profile Modal =====
  void _showEditProfileModal() {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              color: const Color(0xFF5B9BD5),
                              image: avatarUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: avatarUrl.isEmpty
                                ? Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                Navigator.pop(context);
                                await _pickAndUploadAvatar();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF5B9BD5),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B9BD5),
                          ),
                          onPressed: () async {
                            if (!mounted) return;
                            setState(() => _isLoading = true);
                            try {
                              await supabase.from('users').update({
                                'name': nameController.text.trim(),
                                'email': emailController.text.trim(),
                              }).eq('id', widget.studentId);
                              
                              await _loadUserData();
                              Navigator.pop(context);
                              _showSnack('Profile updated', Colors.green);
                            } catch (e) {
                              debugPrint('Edit profile failed: $e');
                              _showSnack('Failed to update profile', Colors.red);
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== Change Password Modal =====
  void _showChangePasswordModal() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B9BD5),
                      ),
                      onPressed: () async {
                        if (newController.text != confirmController.text) {
                          _showSnack('Passwords do not match', Colors.red);
                          return;
                        }

                        if (newController.text.length < 6) {
                          _showSnack('Password must be at least 6 characters', Colors.red);
                          return;
                        }

                        Navigator.pop(context);
                        if (!mounted) return;
                        setState(() => _isLoading = true);
                        
                        try {
                          // Verify current password using RPC
                          final verifyResponse = await supabase.rpc(
                            'login_student',
                            params: {
                              'email_in': email,
                              'password_in': currentController.text,
                            },
                          );

                          if (verifyResponse['error'] != null) {
                            _showSnack('Current password is incorrect', Colors.red);
                            return;
                          }

                          // Update password
                          await supabase.rpc(
                            'update_student_password',
                            params: {
                              'student_id_in': widget.studentId,
                              'new_password': newController.text,
                            },
                          );

                          _showSnack('Password changed successfully', Colors.green);
                        } catch (e) {
                          debugPrint('Error changing password: $e');
                          _showSnack('Failed to change password', Colors.red);
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      child: const Text(
                        'Change',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== Update Email Modal =====
  void _showUpdateEmailModal() {
    final emailController = TextEditingController(text: email);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Email',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'New Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B9BD5),
                      ),
                      onPressed: () async {
                        final newEmail = emailController.text.trim();
                        if (newEmail.isEmpty || !newEmail.contains('@')) {
                          _showSnack('Enter a valid email', Colors.red);
                          return;
                        }

                        Navigator.pop(context);
                        if (!mounted) return;
                        setState(() => _isLoading = true);
                        
                        try {
                          await supabase
                              .from('users')
                              .update({'email': newEmail})
                              .eq('id', widget.studentId);

                          setState(() => email = newEmail);
                          _showSnack('Email updated', Colors.green);
                        } catch (e) {
                          debugPrint('Update email failed: $e');
                          _showSnack('Failed to update email: $e', Colors.red);
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      child: const Text(
                        'Update',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== About Modal =====
  void _showAboutModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About AskUp',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'AskUp is a lightweight classroom interaction tool built for lectures.',
                ),
                const SizedBox(height: 8),
                const Text('Version: 1.0.0 (College project)'),
                const SizedBox(height: 16),
                const Text(
                  '© 2025 AskUp. All rights reserved.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== Logout =====
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('SignOut error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            Text(
              'Manage your account and preferences',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _loadUserData();
              await _loadStats();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildAccountInfo(),
                const SizedBox(height: 24),
                _buildStatSection(),
                const SizedBox(height: 24),
                _buildPreferencesSection(),
                const SizedBox(height: 24),
                _buildAccountActions(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _showEditProfileModal,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B9BD5),
                    borderRadius: BorderRadius.circular(30),
                    image: avatarUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarUrl.isEmpty
                      ? Center(
                          child: Text(
                            _getInitials(name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Loading...' : name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isEmpty ? 'Loading...' : email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showEditProfileModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF5B9BD5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFF5B9BD5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF5B9BD5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              role.isEmpty ? 'Student' : role,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Department', style: TextStyle(color: Colors.grey)),
              Text('Student ID', style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                department,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                employeeId,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Member Since', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 6),
              Text(
                memberSince != null
                    ? "${memberSince!.month}/${memberSince!.year}"
                    : '-',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            _totalQuestions.toString(),
            'Questions Asked',
            const Color(0xFF5B9BD5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            _totalPolls.toString(),
            'Polls Answered',
            const Color(0xFFF5A623),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '$_participationRate%',
            'Participation',
            const Color(0xFF34C759),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferences',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildPreferenceToggle(
          'Push Notifications',
          'Receive notifications for questions and polls',
          _pushNotifications,
          (value) => _updatePreference('push_notifications', value),
        ),
        const SizedBox(height: 12),
        _buildPreferenceToggle(
          'Email Updates',
          'Get notified about activity via email',
          _emailUpdates,
          (value) => _updatePreference('email_updates', value),
        ),
      ],
    );
  }

  Widget _buildPreferenceToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5B9BD5),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildAccountButton(
          Icons.lock_outline,
          'Change Password',
          const Color(0xFF5B9BD5),
          _showChangePasswordModal,
        ),
        const SizedBox(height: 12),
        _buildAccountButton(
          Icons.email_outlined,
          'Update Email',
          const Color(0xFF5B9BD5),
          _showUpdateEmailModal,
        ),
        const SizedBox(height: 12),
        _buildAccountButton(
          Icons.info_outline,
          'About AskUp',
          const Color(0xFF5B9BD5),
          _showAboutModal,
        ),
        const SizedBox(height: 12),
        _buildAccountButton(
          Icons.logout,
          'Log Out',
          Colors.red,
          _handleLogout,
        ),
      ],
    );
  }

  Widget _buildAccountButton(
    IconData icon,
    String text,
    Color iconColor,
    VoidCallback onTap,
  ) {
    final isLogout = text == 'Log Out';
    return Container(
      decoration: BoxDecoration(
        color: isLogout ? const Color(0xFFFFEBEE) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isLogout ? Colors.red : const Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}