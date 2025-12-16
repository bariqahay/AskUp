import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/theme_switcher.dart';

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

  // User
  String _name = '';
  String _email = '';
  String _department = '-';
  String _studentId = '-';
  String _avatarUrl = '';
  bool pushNotifications = true;
  bool emailNotifications = true;
  String _initials = 'ST';

  // Stats
  int _questionsAsked = 0;
  int _pollsAnswered = 0;
  int _participationRate = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadProfile(),
      _loadStats(),
    ]);

    setState(() => _isLoading = false);
  }

  // ================= USER =================
  Future<void> _loadProfile() async {
    final user = await supabase
        .from('users')
        .select(
            'name, email, department, employee_id, avatar_url, push_notifications, email_updates')
        .eq('id', widget.studentId)
        .single();

    _name = user['name'];
    _avatarUrl = user['avatar_url'] ?? '';
    _email = user['email'];
    _department = user['department'] ?? '-';
    _studentId = user['employee_id'] ?? '-';
    pushNotifications = user['push_notifications'] ?? true;
    emailNotifications = user['email_updates'] ?? true;

    final parts = _name.split(' ');
    _initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : _name.substring(0, 2).toUpperCase();
  }

  // ================= STATS =================
  Future<void> _loadStats() async {
    // Questions asked
    final questions = await supabase
        .from('questions')
        .select('id')
        .eq('student_id', widget.studentId);

    _questionsAsked = questions.length;

    // Polls answered (pakai session_participants)
    final polls = await supabase
        .from('session_participants')
        .select('id')
        .eq('student_id', widget.studentId);

    _pollsAnswered = polls.length;

    // Participation rate (simple version)
    final sessions = await supabase.from('sessions').select('id');

    if (sessions.isNotEmpty) {
      _participationRate =
          ((_pollsAnswered / sessions.length) * 100).round();
    }
  }

  // ================= UPDATE PREF =================
  Future<void> _updatePreferences() async {
    await supabase.from('users').update({
      'push_notifications': pushNotifications,
      'email_updates': emailNotifications,
    }).eq('id', widget.studentId);
  }

  // ================= AVATAR UPLOAD =================
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
        setState(() {
          _avatarUrl = publicUrl;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ================= EDIT PROFILE =================
  void _showEditProfileModal() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadAvatar();
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF5B9BD5),
                        backgroundImage:
                            _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                        child: _avatarUrl.isEmpty
                            ? Text(_initials,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 32))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await supabase.from('users').update({
                            'name': nameController.text.trim(),
                            'email': emailController.text.trim(),
                          }).eq('id', widget.studentId);

                          await _loadProfile();
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Profile updated'),
                                  backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to update'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('Save'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: BackButton(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ================= PROFILE =================
          Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF5B9BD5),
                backgroundImage:
                    _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                child: _avatarUrl.isEmpty
                    ? Text(
                        _initials,
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      )
                    : null,
              ),
              title: Text(_name),
              subtitle: Text(_email),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _showEditProfileModal,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ================= ACCOUNT =================
          const Text('Account Information'),
          Card(
            child: Column(
              children: [
                _row('Department', _department),
                _row('Student ID', _studentId),
                _row('Role', 'Student'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= STATS =================
          const Text('Activity Statistics'),
          Card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(_questionsAsked.toString(), 'Questions'),
                _stat(_pollsAnswered.toString(), 'Polls'),
                _stat('$_participationRate%', 'Participation'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= THEME =================
          const Text('Appearance'),
          const ThemeSwitcher(),

          const SizedBox(height: 20),

          // ================= PREF =================
          const Text('Preferences'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  value: pushNotifications,
                  onChanged: (v) {
                    setState(() => pushNotifications = v);
                    _updatePreferences();
                  },
                ),
                SwitchListTile(
                  title: const Text('Email Updates'),
                  value: emailNotifications,
                  onChanged: (v) {
                    setState(() => emailNotifications = v);
                    _updatePreferences();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= ACTION =================
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k), Text(v)],
      ),
    );
  }

  Widget _stat(String v, String l) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(l),
        ],
      ),
    );
  }
}
