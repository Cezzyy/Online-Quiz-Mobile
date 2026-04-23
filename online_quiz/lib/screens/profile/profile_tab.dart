import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/local_auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/error_messages.dart';
import '../../widgets/profile_skeleton_loader.dart';
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
    Future.microtask(() {
      final authState = ref.read(authProvider);
      final localAuthState = ref.read(localAuthProvider);
      
      if (authState.user != null) {
        // If app was just unlocked, reset to loading state first
        if (localAuthState.shouldReloadData) {
          ref.read(userProfileProvider.notifier).resetToLoading();
        }
        
        ref
            .read(userProfileProvider.notifier)
            .loadUserData(authState.user!.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(userProfileProvider);
    final localAuthState = ref.watch(localAuthProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Show loading indicator while data is being fetched
    if (profileState.isLoading || authState.user == null || localAuthState.shouldReloadData) {
      return const ProfileSkeletonLoader();
    }

    // Show error if any
    if (profileState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Unable to Load Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  ErrorMessages.getUserFriendlyMessage(profileState.error),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(userProfileProvider.notifier)
                      .loadUserData(authState.user!.userId);
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
      body: RefreshIndicator(
        onRefresh: () async {
          final authState = ref.read(authProvider);
          if (authState.user != null) {
            await ref.read(userProfileProvider.notifier).loadUserData(authState.user!.userId);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header Section with Gradient and Profile Picture
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Gradient Background
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                  // Decorative Circles
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // Profile Picture
                  Positioned(
                    bottom: -60,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.scaffoldBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: const AssetImage(
                          'assets/images/aclclogo-nobg.png',
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 70),

              // User Name and ID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      user.fullName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    if (student != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${student.studentId}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Academic Information
                    if (student != null)
                      _buildInfoCard(
                        context,
                        title: 'Academic Information',
                        icon: Icons.school,
                        children: [
                          _buildInfoRow(
                            context,
                            'Course',
                            student.course ?? 'Not set',
                          ),
                          _buildDivider(context),
                          _buildInfoRow(
                            context,
                            'Year Level',
                            student.yearLevel != null
                                ? _getYearLevelText(student.yearLevel!)
                                : 'Not set',
                          ),
                          _buildDivider(context),
                          _buildInfoRow(
                            context,
                            'Section',
                            student.section ?? 'Not set',
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Contact Information
                    _buildInfoCard(
                      context,
                      title: 'Contact Information',
                      icon: Icons.contact_phone,
                      children: [
                        _buildInfoRow(context, 'Email', user.email),
                        _buildDivider(context),
                        _buildInfoRow(
                          context,
                          'Phone',
                          user.contactNumber.isNotEmpty
                              ? user.contactNumber
                              : 'Not set',
                        ),
                        _buildDivider(context),
                        _buildInfoRow(
                          context,
                          'Emergency Contact Person',
                          user.emergencyContactPerson.isNotEmpty
                              ? user.emergencyContactPerson
                              : 'Not set',
                        ),
                        _buildDivider(context),
                        _buildInfoRow(
                          context,
                          'Emergency Contact Number',
                          user.emergencyContactNumber.isNotEmpty
                              ? user.emergencyContactNumber
                              : 'Not set',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Account Status
                    _buildInfoCard(
                      context,
                      title: 'Account Status',
                      icon: Icons.verified_user,
                      children: [
                        _buildInfoRow(
                          context,
                          'Status',
                          user.status,
                          valueColor: user.isActive ? Colors.green : Colors.red,
                        ),
                        _buildDivider(context),
                        _buildInfoRow(
                          context,
                          'Member Since',
                          DateFormat('MMMM d, yyyy').format(user.createdAt),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white54
                                    : AppTheme.primaryColor,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Settings',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      height: 16,
    );
  }

  String _getYearLevelText(int yearLevel) {
    String suffix = 'th';
    if (yearLevel % 100 < 11 || yearLevel % 100 > 13) {
      switch (yearLevel % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
      }
    }
    return '$yearLevel$suffix Year';
  }
}
