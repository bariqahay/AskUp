// profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/stat_card.dart';
import '../widgets/preference_toggle.dart';
import '../widgets/account_button.dart';
import '../widgets/theme_switcher.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> lecturerData;
  const ProfileScreen({super.key, required this.lecturerData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool pushNotifications = true;
  bool emailUpdates = true;
  bool isLoading = false;

  String name = '';
  String email = '';
  String role = '';
  String department = '';
  String employeeId = '';
  String avatarUrl = '';
  DateTime? memberSince;

  int sessionsCreated = 0;
  int sessionsReached = 0;
  double averageRating = 0.0;

  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadStats();
  }

  // ===== Fetch profile info from users table =====
  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final userId = widget.lecturerData['id'];
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          name = response['name'] ?? '';
          email = response['email'] ?? '';
          role = response['role'] ?? '';
          department = response['department'] ?? '';
          employeeId = response['employee_id'] ?? '';
          avatarUrl = response['avatar_url'] ?? '';
          pushNotifications = response['push_notifications'] ?? true;
          emailUpdates = response['email_updates'] ?? true;
          memberSince = DateTime.tryParse(response['created_at'] ?? '');
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ===== Load stats from RPC =====
  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final response = await supabase.rpc(
        'get_lecturer_stats',
        params: {'p_lecturer_id': widget.lecturerData['id']},
      ).maybeSingle();

      if (response != null) {
        setState(() {
          sessionsCreated = (response['sessions_created'] ?? 0).toInt();
          sessionsReached = (response['sessions_reached'] ?? 0).toInt();
          averageRating = (response['avg_rating'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ===== Update preferences =====
  Future<void> updatePreference(String field, bool value) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      await supabase.from('users').update({field: value}).eq('id', widget.lecturerData['id']);
      setState(() {
        if (field == 'push_notifications') pushNotifications = value;
        if (field == 'email_updates') emailUpdates = value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$field updated'), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint('Error updating $field: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $field'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
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
      setState(() => isLoading = true);

      final File imageFile = File(pickedFile.path);
      final String userId = widget.lecturerData['id'];
      final String fileName = 'avatar_$userId.${pickedFile.path.split('.').last}';
      final String filePath = 'avatars/$fileName';

      await supabase.storage.from('avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      await supabase.from('users').update({'avatar_url': publicUrl}).eq('id', userId);

      if (mounted) {
        setState(() => avatarUrl = publicUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ===== Edit profile modal (existing) =====
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
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(60),
                                  color: Colors.blue,
                                  image: avatarUrl.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: avatarUrl.isEmpty
                                    ? Center(
                                        child: Text(name.isNotEmpty ? name[0] : 'U',
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
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
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                        const SizedBox(height: 14),
                        TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              onPressed: () async {
                                if (!mounted) return;
                                setState(() => isLoading = true);
                                try {
                                  await supabase.from('users').update({
                                    'name': nameController.text.trim(),
                                    'email': emailController.text.trim(),
                                  }).eq('id', widget.lecturerData['id']);
                                  await _fetchProfile();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
                                  );
                                } catch (e) {
                                  debugPrint('Edit profile failed: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red),
                                  );
                                } finally {
                                  if (mounted) setState(() => isLoading = false);
                                }
                              },
                              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== New: Change Password modal & logic (direct DB update) =====
  void _showChangePasswordModal() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final newPass = passwordController.text.trim();
                    if (newPass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password cannot be empty'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // Directly update users.password (NOT recommended for production)
                    Navigator.pop(context);
                    if (!mounted) return;
                    setState(() => isLoading = true);
                    try {
                      await supabase.from('users').update({'password': newPass}).eq('id', widget.lecturerData['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      debugPrint('Change password failed: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to change password: $e'), backgroundColor: Colors.red),
                      );
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  },
                  child: const Text('Change'),
                ),
              ])
            ]),
          ),
        );
      },
    );
  }

  // ===== New: Update Email modal & logic (direct DB update) =====
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Update Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'New Email'),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final newEmail = emailController.text.trim();
                    if (newEmail.isEmpty || !newEmail.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid email'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    if (!mounted) return;
                    setState(() => isLoading = true);
                    try {
                      await supabase.from('users').update({'email': newEmail}).eq('id', widget.lecturerData['id']);
                      setState(() => email = newEmail);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email updated'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      debugPrint('Update email failed: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update email: $e'), backgroundColor: Colors.red),
                      );
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  },
                  child: const Text('Update'),
                ),
              ])
            ]),
          ),
        );
      },
    );
  }

  // ===== New: About AskUp modal =====
  void _showAboutModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('About AskUp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('AskUp is a lightweight classroom interaction tool built for lectures.'),
              const SizedBox(height: 8),
              const Text('Version: 0.1 (College project)'),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ]),
            ]),
          ),
        );
      },
    );
  }

  // ===== Logout logic =====
  Future<void> _handleLogout() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      // sign out supabase auth session if any
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('SignOut error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
            Text('Manage your account and preferences', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ],
        ),
      ),
      body: Stack(
        children: [
          ListView(
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
              _buildAccountActions(), // buttons wired to modals
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showEditProfileModal,
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B9BD5),
                    borderRadius: BorderRadius.circular(35),
                    image: avatarUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: avatarUrl.isEmpty
                      ? Center(
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'L',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B9BD5),
                      shape: BoxShape.circle,
                      border: Border.all(color: cardColor, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF5B9BD5), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
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
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Department', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
              Text('Employee ID', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(department, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15)),
              Text(employeeId, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Member Since', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                memberSince != null ? "${memberSince!.month}/${memberSince!.year}" : '-',
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15),
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
        Expanded(child: StatCard(value: sessionsCreated.toString(), label: 'Sessions Created', color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: StatCard(value: sessionsReached.toString(), label: 'Sessions Reached', color: Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: StatCard(value: averageRating.toStringAsFixed(1), label: 'Average Rating', color: Colors.orange)),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),
        const ThemeSwitcher(),
        const SizedBox(height: 24),
        Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),
        PreferenceToggle(
          title: 'Push Notifications',
          subtitle: 'Receive notifications for questions and polls',
          value: pushNotifications,
          onChanged: (value) => updatePreference('push_notifications', value),
        ),
        const SizedBox(height: 12),
        PreferenceToggle(
          title: 'Email Updates',
          subtitle: 'Get notified about activity via email',
          value: emailUpdates,
          onChanged: (value) => updatePreference('email_updates', value),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 12),
        AccountButton(icon: Icons.lock_outline, text: 'Change Password', iconColor: const Color(0xFF5B9BD5), onTap: _showChangePasswordModal),
        const SizedBox(height: 12),
        AccountButton(icon: Icons.email_outlined, text: 'Update Email', iconColor: const Color(0xFF5B9BD5), onTap: _showUpdateEmailModal),
        const SizedBox(height: 12),
        AccountButton(icon: Icons.info_outline, text: 'About AskUp', iconColor: const Color(0xFF5B9BD5), onTap: _showAboutModal),
        const SizedBox(height: 12),
        AccountButton(
          icon: Icons.logout,
          text: 'Log Out',
          iconColor: Colors.red,
          isLogout: true,
          onTap: _handleLogout,
        ),
      ],
    );
  }
}
