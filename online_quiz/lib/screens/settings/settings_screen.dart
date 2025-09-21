import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_routes.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profile Section
          _buildSectionHeader('Profile'),
          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              // Navigate to change password screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change Password feature coming soon')),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Receive quiz reminders and updates',
            value: settingsState.notificationsEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setNotificationsEnabled(value);
            },
          ),

          
          const SizedBox(height: 24),
          
          // App Preferences Section
          _buildSectionHeader('App Preferences'),
          _buildSettingsTile(
            icon: Icons.palette,
            title: 'Theme Mode',
            subtitle: _getThemeModeSubtitle(settingsState.themeMode),
            onTap: () {
              _showThemeModeDialog();
            },
          ),

          
          const SizedBox(height: 24),
          
          // Academic Section
          _buildSectionHeader('Academic'),
          _buildSettingsTile(
            icon: Icons.school,
            title: 'Study Progress',
            subtitle: 'View your learning analytics',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Study Progress feature coming soon')),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.bookmark,
            title: 'Saved Questions',
            subtitle: 'Review your bookmarked questions',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved Questions feature coming soon')),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.history,
            title: 'Quiz History',
            subtitle: 'View your past quiz attempts',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quiz History feature coming soon')),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              _showAboutDialog();
            },
          ),
          _buildSettingsTile(
            icon: Icons.restore,
            title: 'Reset Settings',
            subtitle: 'Reset all settings to default',
            onTap: () {
              _showResetSettingsDialog();
            },
            textColor: Colors.orange,
          ),
          
          const SizedBox(height: 24),
          
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: () {
              _showSignOutDialog();
            },
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor ?? Colors.blue,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: Colors.blue,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.blue,
      ),
    );
  }



  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'ACLC Online Quiz',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.quiz,
        size: 48,
        color: Colors.blue,
      ),
      children: [
        const Text(
          'A comprehensive quiz application for ACLC students to practice and improve their knowledge across various subjects.',
        ),
      ],
    );
  }

  String _getThemeModeSubtitle(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
      case ThemeMode.system:
        return 'Follow system setting';
    }
  }

  void _showThemeModeDialog() {
    final settingsState = ref.read(settingsProvider);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Light theme'),
                value: ThemeMode.light,
                groupValue: settingsState.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Dark theme'),
                value: ThemeMode.dark,
                groupValue: settingsState.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                subtitle: const Text('Follow system setting'),
                value: ThemeMode.system,
                groupValue: settingsState.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text('Are you sure you want to reset all settings to their default values? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(settingsProvider.notifier).resetSettings();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings have been reset to default'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Perform logout and explicitly navigate to login screen
                await ref.read(authProvider.notifier).logout();
                
                // Force navigation to login screen
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false, // Clear all routes
                  );
                }
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}