import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/app_theme.dart';
import 'edit_profile_screen.dart';
import '../settings/settings_screen.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  @override
  void initState() {
    super.initState();
    // Load user profile data when tab is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref.read(userProfileProvider.notifier).loadUserData(authState.user!.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(userProfileProvider);

    // Show loading indicator while data is being fetched
    if (profileState.isLoading || authState.user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error if any
    if (profileState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profileState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(userProfileProvider.notifier).loadUserData(authState.user!.userId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final user = profileState.user ?? authState.user!;
    final student = profileState.student;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
            const SizedBox(height: 40),
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.surface,
              backgroundImage: const AssetImage('assets/images/aclclogo-nobg.png'),
            ),
            const SizedBox(height: 24),
            
            // User Name
            Text(
              user.fullName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Student ID
            if (student != null)
              Text(
                'Student ID: ${student.studentId}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 4),
            
            // Email
             Text(
               user.email,
               style: TextStyle(
                 fontSize: 14,
                 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
               ),
             ),
             const SizedBox(height: 32),
             
             // User Details Card
             Container(
               width: double.infinity,
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
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     'Profile Details',
                     style: TextStyle(
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                       color: Theme.of(context).colorScheme.onSurface,
                     ),
                   ),
                   const SizedBox(height: 16),
                   if (student != null) ...[
                     _buildDetailRow(context, Icons.school_outlined, 'Degree Program', student.course ?? 'N/A'),
                     const SizedBox(height: 12),
                     _buildDetailRow(context, Icons.class_outlined, 'Year Level', student.yearLevel != null ? 'Year ${student.yearLevel}' : 'N/A'),
                     const SizedBox(height: 12),
                     _buildDetailRow(context, Icons.group_outlined, 'Section', student.section ?? 'N/A'),
                     const SizedBox(height: 12),
                   ],
                   _buildDetailRow(context, Icons.badge_outlined, 'Status', user.status),
                 ],
               ),
             ),
             const SizedBox(height: 32),
             
             // Action Buttons
             Row(
               children: [
                 Expanded(
                   child: ElevatedButton.icon(
                     onPressed: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => const EditProfileScreen(),
                         ),
                       );
                     },
                     icon: const Icon(Icons.edit_outlined),
                     label: const Text('Edit Profile'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.primaryColor,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: OutlinedButton.icon(
                     onPressed: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => const SettingsScreen(),
                         ),
                       );
                     },
                     icon: const Icon(Icons.settings_outlined),
                     label: const Text('Settings'),
                     style: OutlinedButton.styleFrom(
                       foregroundColor: AppTheme.primaryColor,
                       side: BorderSide(color: AppTheme.primaryColor),
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                   ),
                 ),
               ],
             ),
           ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}