import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/export_import_provider.dart';
import '../../widgets/info_card.dart';
import '../../services/system_info_service.dart';
import '../../services/local_notification_service.dart';
import 'admin_activity_logs_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class AdminSettingsTab extends ConsumerStatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  ConsumerState<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends ConsumerState<AdminSettingsTab> {
  final SystemInfoService _systemInfoService = SystemInfoService();
  final LocalNotificationService _notificationService =
      LocalNotificationService();
  SystemStatus? _systemStatus;
  bool _isLoadingSystemInfo = true;
  bool _notificationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final isGranted = await _notificationService.isPermissionGranted();
    if (mounted) {
      setState(() {
        _notificationPermissionGranted = isGranted;
      });
    }
  }

  Future<void> _loadSystemInfo() async {
    setState(() {
      _isLoadingSystemInfo = true;
    });

    try {
      final status = await _systemInfoService.checkSystemStatus();

      if (mounted) {
        setState(() {
          _systemStatus = status;
          _isLoadingSystemInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSystemInfo = false;
        });
      }
    }
  }

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

              // Audit Logs Section
              _buildAuditLogsSection(context),

              const SizedBox(height: 16),

              // Notification Permissions Section
              _buildNotificationPermissionsSection(context),

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
          subtitle: 'Download audit logs as Excel',
          onTap: () => _showExportAuditLogsDialog(context),
        ),
      ],
    );
  }

  Widget _buildNotificationPermissionsSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Notification Permissions',
      icon: Icons.notifications_active,
      children: [
        _buildSettingsTile(
          context,
          icon: _notificationPermissionGranted
              ? Icons.check_circle
              : Icons.warning_amber,
          title: 'Push Notifications',
          subtitle: _notificationPermissionGranted
              ? 'Notifications are enabled'
              : 'Tap to enable notifications',
          trailing: _notificationPermissionGranted
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: _notificationPermissionGranted
              ? null
              : () => _requestNotificationPermission(context),
        ),
        if (!_notificationPermissionGranted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Enable notifications to receive real-time updates about quizzes, courses, and system announcements.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Widget _buildSystemInformationSection(BuildContext context) {
    if (_isLoadingSystemInfo) {
      return _buildSection(
        context,
        title: 'System Information',
        icon: Icons.info,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    final appVersion = _systemInfoService.getAppVersion();
    final systemStatus = _systemStatus;

    return _buildSection(
      context,
      title: 'System Information',
      icon: Icons.info,
      children: [
        InfoCard(
          title: 'App Version',
          value: appVersion,
          icon: Icons.apps,
          iconColor: AppTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        InfoCard(
          title: 'Database Connection',
          value: systemStatus?.message ?? 'Unknown',
          icon: systemStatus?.isOperational == true
              ? Icons.check_circle
              : Icons.error,
          iconColor: systemStatus?.isOperational == true
              ? Colors.green
              : Colors.red,
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

  void _showAuditLogsDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminActivityLogsScreen()),
    );
  }

  void _showExportAuditLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export Audit Logs'),
        content: const Text(
          'Export all activity audit logs to an Excel file?\n\nThe file will be saved to your Downloads folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performAuditLogsExport(context);
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAuditLogsExport(BuildContext context) async {
    // Get current user ID
    final authState = ref.read(authProvider);
    final userId = authState.user?.userId;

    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Exporting audit logs...'),
            ],
          ),
        ),
      );
    }

    // Perform export
    final exportNotifier = ref.read(exportImportProvider.notifier);
    final filePath = await exportNotifier.exportAuditLogsToExcel(
      userId: userId,
    );

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show result
    final exportState = ref.read(exportImportProvider);
    if (context.mounted) {
      if (filePath != null && exportState.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exportState.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (exportState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exportState.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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

  Future<void> _requestNotificationPermission(BuildContext context) async {
    final granted = await _notificationService.requestPermission();

    if (granted) {
      setState(() {
        _notificationPermissionGranted = true;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // If permission denied, show dialog to open settings
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Enable Notifications'),
            content: const Text(
              'Notification permission is required to receive real-time updates. '
              'Please enable notifications in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await openAppSettings();
                  // Recheck permission after user returns from settings
                  await Future.delayed(const Duration(seconds: 1));
                  await _checkNotificationPermission();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }
}
