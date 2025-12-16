import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show appKey;

class ThemeSwitcher extends StatefulWidget {
  const ThemeSwitcher({super.key});

  @override
  State<ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<ThemeSwitcher> {
  String _selectedTheme = 'system';

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('theme_mode') ?? 'system';
    });
  }

  Future<void> _saveThemePreference(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', theme);
    setState(() {
      _selectedTheme = theme;
    });
    
    // Update app theme immediately
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == theme,
      orElse: () => ThemeMode.system,
    );
    
    // Trigger app theme reload via global key
    appKey.currentState?.updateThemeMode(themeMode);
    
    if (mounted) {
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Theme changed to ${theme == 'system' ? 'System Default' : theme == 'dark' ? 'Dark Mode' : 'Light Mode'}'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    
    return Card(
      color: cardColor,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 2 : 1,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: Colors.blue,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Light Mode
            RadioListTile<String>(
              value: 'light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                if (value != null) _saveThemePreference(value);
              },
              title: Text('Light Mode'),
              subtitle: Text('Always use light theme'),
              secondary: Icon(Icons.light_mode, color: Colors.orange),
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
            ),
            
            // Dark Mode
            RadioListTile<String>(
              value: 'dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                if (value != null) _saveThemePreference(value);
              },
              title: Text('Dark Mode'),
              subtitle: Text('Always use dark theme'),
              secondary: Icon(Icons.dark_mode, color: Colors.indigo),
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
            ),
            
            // System Default
            RadioListTile<String>(
              value: 'system',
              groupValue: _selectedTheme,
              onChanged: (value) {
                if (value != null) _saveThemePreference(value);
              },
              title: Text('System Default'),
              subtitle: Text('Follow system settings'),
              secondary: Icon(Icons.settings_suggest, color: Colors.grey),
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
