import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../widgets/info_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/teacher_profile_provider.dart';

class TeacherProfileTab extends ConsumerWidget {
  final Function(int) onNavigateToTab;
  
  const TeacherProfileTab({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final settingsState = ref.watch(settingsProvider);
    final teacherProfileState = ref.watch(teacherProfileProvider);

    // Show loading state
    if (teacherProfileState.isLoading && teacherProfileState.user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state
    if (teacherProfileState.error != null) {
      return Scaffold(
        body: EmptyStatePresets.error(
          title: 'Failed to Load Profile',
          message: teacherProfileState.error!,
          onRetry: () {
            if (authState.user != null) {
              ref.read(teacherProfileProvider.notifier).refreshTeacherData(authState.user!.userId);
            }
          },
        ),
      );
    }

    // Show empty state if no user data
    if (teacherProfileState.user == null) {
      return const Scaffold(
        body: EmptyStateWidget(
          icon: Icons.person_off_outlined,
          title: 'No Profile Data',
          message: 'Unable to load teacher profile information.',
        ),
      );
    }

    final user = teacherProfileState.user!;
    final teacher = teacherProfileState.teacher!;
    final courses = teacherProfileState.courses;
    final statistics = ref.watch(teacherStatisticsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Profile Header
              _buildProfileHeader(context, user, teacher),
              const SizedBox(height: 32),
              
              // Statistics Cards
              _buildStatisticsSection(context, statistics),
              const SizedBox(height: 32),
              
              // Teaching Details
              _buildTeachingDetails(context, teacher, courses),
              const SizedBox(height: 32),
              
              // Settings Section
              _buildSettingsSection(context, ref, settingsState),
              const SizedBox(height: 32),
              
              // Sign Out Button
              _buildSignOutButton(context, ref),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user, teacher) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: const AssetImage('assets/images/aclclogo-nobg.png'),
          ),
          const SizedBox(height: 16),
          
          // Teacher Name
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Department
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              teacher.department ?? 'Department',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Email
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          
          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                user.status,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, Map<String, num> statistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teaching Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.class_outlined,
                title: 'Courses',
                value: statistics['courses']?.toInt().toString() ?? '0',
                color: AppTheme.getCourseColor('CS101'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.quiz_outlined,
                title: 'Quizzes',
                value: statistics['quizzes']?.toInt().toString() ?? '0',
                color: AppTheme.getQuizTypeColor('quiz'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.people_outlined,
                title: 'Students',
                value: statistics['students']?.toInt().toString() ?? '0',
                color: AppTheme.getQuizTypeColor('course'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeachingDetails(BuildContext context, teacher, courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teaching Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // Department Info Card
        InfoCard(
          icon: Icons.business_outlined,
          title: 'Department',
          value: teacher.department ?? 'Not specified',
          iconColor: AppTheme.getCourseColor('CS101'),
        ),
        const SizedBox(height: 12),
        
        // Courses Info Card
        InfoCard(
          icon: Icons.class_outlined,
          title: 'Active Courses',
          value: '${courses.length} courses',
          iconColor: AppTheme.getQuizTypeColor('course'),
          onTap: () {
            // Navigate to courses tab (index 1)
            onNavigateToTab(1);
          },
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref, settingsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Theme Toggle
              Row(
                children: [
                  Icon(
                    settingsState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          settingsState.isDarkMode ? 'Dark Mode' : 'Light Mode',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settingsState.isDarkMode,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).toggleDarkMode(value);
                    },
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Notifications Toggle
              Row(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          settingsState.notificationsEnabled ? 'Enabled' : 'Disabled',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settingsState.notificationsEnabled,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setNotificationsEnabled(value);
                    },
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
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
    );
  }
}