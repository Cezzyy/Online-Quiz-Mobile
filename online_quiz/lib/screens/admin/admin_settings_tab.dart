import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';

class AdminSettingsTab extends ConsumerWidget {
  const AdminSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 80,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 24),
            Text(
              'System Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 48),
            // Sign Out Button
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Show confirmation dialog
                  final shouldSignOut = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  
                  if (shouldSignOut == true) {
                    // Perform logout - AuthWrapper will handle navigation automatically
                    await ref.read(authProvider.notifier).logout();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
