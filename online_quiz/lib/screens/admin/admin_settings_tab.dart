import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/info_card.dart';
import 'admin_activity_logs_screen.dart';

class AdminSettingsTab extends ConsumerStatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  ConsumerState<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends ConsumerState<AdminSettingsTab> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Settings Section
              _buildThemeSection(context, settingsState, settingsNotifier),

              const SizedBox(height: 16),

              // Data Management Section
              _buildDataManagementSection(context),

              const SizedBox(height: 16),

              // Audit Logs Section
              _buildAuditLogsSection(context),

              const SizedBox(height: 16),

              // System Information Section
              _buildSystemInformationSection(context),

              const SizedBox(height: 16),

              // Account Actions Section
              _buildAccountActionsSection(context),

              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActionsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Account Actions',
      icon: Icons.account_circle,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Sign out of admin account',
          textColor: Colors.red,
          onTap: () => _showSignOutDialog(context),
        ),
      ],
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    SettingsState settingsState,
    SettingsNotifier settingsNotifier,
  ) {
    return _buildSection(
      context,
      title: 'Theme Settings',
      icon: Icons.palette,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.dark_mode,
          title: 'Dark Theme Mode',
          subtitle: 'Configure app appearance',
          trailing: DropdownButton<ThemeMode>(
            value: settingsState.themeMode,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            onChanged: (ThemeMode? value) {
              if (value != null) {
                settingsNotifier.setThemeMode(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Data Management',
      icon: Icons.storage,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.backup,
          title: 'Data Backup',
          subtitle: 'Configure automatic backups',
          onTap: () => _showBackupDialog(context),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.file_download,
          title: 'Export Data',
          subtitle: 'Export system data to files',
          onTap: () => _showExportDialog(context),
        ),
      ],
    );
  }

  Widget _buildAuditLogsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Audit Logs',
      icon: Icons.history,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.history,
          title: 'View Audit Logs',
          subtitle: 'View system activity logs',
          onTap: () => _showAuditLogsDialog(context),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.download,
          title: 'Export Audit Logs',
          subtitle: 'Download audit logs as CSV',
          onTap: () => _showExportAuditLogsDialog(context),
        ),
      ],
    );
  }

  Widget _buildSystemInformationSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'System Information',
      icon: Icons.info,
      children: [
        InfoCard(
          title: 'App Version',
          value: '1.0.0',
          icon: Icons.apps,
          iconColor: AppTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        InfoCard(
          title: 'Last Backup',
          value: 'Today, 2:30 AM',
          icon: Icons.backup,
          iconColor: Colors.green,
        ),
        const SizedBox(height: 12),
        InfoCard(
          title: 'System Status',
          value: 'All Systems Operational',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (textColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: textColor ?? AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor ?? AppTheme.getTextColor(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
        ),
        trailing:
            trailing ??
            (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Dialog methods

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Backup'),
        content: const Text(
          'Data backup configuration will be available in future updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Data export functionality will be available in future updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAuditLogsDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminActivityLogsScreen()),
    );
  }

  void _showExportAuditLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Audit Logs'),
        content: const Text(
          'Audit log export functionality will be available in future updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your admin account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
