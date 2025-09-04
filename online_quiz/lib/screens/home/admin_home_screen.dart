import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_routes.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              // Perform logout
              await ref.read(authProvider.notifier).logout();
              
              // Force navigation to login screen
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false, // Clear all routes
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${user?.name ?? 'Admin'}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'System administration and management',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Admin Tools',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    icon: Icons.people,
                    title: 'User Management',
                    subtitle: 'Manage users & roles',
                    color: Colors.blue,
                    onTap: () {
                      // TODO: Navigate to user management screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User Management - Coming Soon!')),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.school,
                    title: 'Course Management',
                    subtitle: 'Manage courses',
                    color: Colors.green,
                    onTap: () {
                      // TODO: Navigate to course management screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Course Management - Coming Soon!')),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.bar_chart,
                    title: 'System Reports',
                    subtitle: 'View system analytics',
                    color: Colors.orange,
                    onTap: () {
                      // TODO: Navigate to reports screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('System Reports - Coming Soon!')),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.security,
                    title: 'System Settings',
                    subtitle: 'Configure system',
                    color: Colors.red,
                    onTap: () {
                      // TODO: Navigate to system settings screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('System Settings - Coming Soon!')),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.backup,
                    title: 'Data Backup',
                    subtitle: 'Backup & restore',
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Navigate to backup screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data Backup - Coming Soon!')),
                      );
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'System notifications',
                    color: Colors.teal,
                    onTap: () {
                      // TODO: Navigate to notifications screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications - Coming Soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}