import 'package:flutter/material.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool pushNotifications = true;
  bool emailNotifications = true;
  bool darkMode = false;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
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
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B9BD5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'PT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paldo Tampu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'paldo.tampu@university.edu',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account Information Section
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow('Major', 'Computer Science'),
                const SizedBox(height: 16),
                _buildInfoRow('Student ID', 'E1703109S'),
                const SizedBox(height: 16),
                _buildInfoRow('Year', '3'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Activity Statistics Section
          const Text(
            'Activity Statistics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('38', 'Questions Asked', const Color(0xFF5B9BD5)),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[300],
                ),
                _buildStatItem('20', 'Polls Answered', const Color(0xFFF5A623)),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[300],
                ),
                _buildStatItem('91', 'Participation Rate', const Color(0xFF34C759)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Preferences Section
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildToggleRow(
                  'Push Notifications',
                  'Receive notifications on mobile and web',
                  pushNotifications,
                  (value) {
                    setState(() {
                      pushNotifications = value;
                    });
                  },
                ),
                Divider(height: 24, color: Colors.grey[200]),
                _buildToggleRow(
                  'Email Updates',
                  'Receive weekly summary via email',
                  emailNotifications,
                  (value) {
                    setState(() {
                      emailNotifications = value;
                    });
                  },
                ),
                Divider(height: 24, color: Colors.grey[200]),
                _buildToggleRow(
                  'Dark Mode',
                  'Switch dark theme for better visibility',
                  darkMode,
                  (value) {
                    setState(() {
                      darkMode = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account Section
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          _buildActionButton(
            '🔒 Change Password',
            Colors.white,
            const Color(0xFF5B9BD5),
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change password feature'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _buildActionButton(
            '📧 Update Email',
            Colors.white,
            const Color(0xFF5B9BD5),
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Update email feature'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _buildActionButton(
            'ℹ️ About AskUp',
            Colors.white,
            const Color(0xFF5B9BD5),
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('About AskUp'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _buildActionButton(
            '🚪 Log Out',
            const Color(0xFFFFEBEE),
            const Color(0xFFE53935),
            () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Log Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
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
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
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
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
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
    );
  }

  Widget _buildActionButton(
    String text,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
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
