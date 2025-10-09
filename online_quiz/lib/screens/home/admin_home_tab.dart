import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../data/mock_data.dart';
import '../../utils/app_theme.dart';

class AdminHomeTab extends ConsumerWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Watch providers for reactive updates
    final courseState = ref.watch(courseProvider);
    final quizState = ref.watch(quizProvider);
    
    // Initialize providers if not already loaded
    if (!courseState.isLoading && courseState.allCourses.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(courseProvider.notifier).initializeCourses(user.userId);
        ref.read(quizProvider.notifier).initializeQuizzes(user.userId);
      });
    }
    
    // Calculate admin statistics
    final adminStats = _calculateAdminStats(courseState, quizState);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Welcome Section
            _buildWelcomeSection(context, user),
            const SizedBox(height: 30),
            
            // Statistics Cards
            _buildStatsSection(context, adminStats),
            const SizedBox(height: 30),
            
            // Quick Actions
            _buildQuickActionsSection(context),
            const SizedBox(height: 30),
            
            // System Overview
            _buildSystemOverview(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeSection(BuildContext context, user) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryColor;
    final onPrimaryColor = Colors.white;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [
                primaryColor.withValues(alpha: 0.9),
                primaryColor.withValues(alpha: 0.7),
              ]
            : [
                primaryColor,
                primaryColor.withValues(alpha: 0.8),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: TextStyle(
              color: onPrimaryColor.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin ${user.fullName.split(' ')[0]}',
            style: TextStyle(
              color: onPrimaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'System administration and management dashboard',
            style: TextStyle(
              color: onPrimaryColor.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsSection(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.people_outline,
                title: 'Total Users',
                value: stats['totalUsers'].toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.class_outlined,
                title: 'Active Courses',
                value: stats['totalCourses'].toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.quiz_outlined,
                title: 'Total Quizzes',
                value: stats['totalQuizzes'].toString(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.analytics_outlined,
                title: 'Quiz Attempts',
                value: stats['totalAttempts'].toString(),
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_add,
                title: 'Add User',
                color: Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add User - Coming Soon!')),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle,
                title: 'Create Course',
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create Course - Coming Soon!')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.backup,
                title: 'System Backup',
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('System Backup - Coming Soon!')),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.settings,
                title: 'System Settings',
                color: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('System Settings - Coming Soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionCard({
    required IconData icon,
    required String title,
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
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSystemOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Status',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
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
            children: [
              _buildStatusItem(
                context,
                icon: Icons.check_circle,
                title: 'System Health',
                status: 'All Systems Operational',
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildStatusItem(
                context,
                icon: Icons.storage,
                title: 'Database',
                status: 'Connected',
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String status,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Map<String, dynamic> _calculateAdminStats(CourseState courseState, QuizState quizState) {
    // Get all users from mock data
    final totalUsers = MockData.users.length;
    
    // Get all courses
    final totalCourses = courseState.allCourses.length;
    
    // Get all quizzes
    final totalQuizzes = quizState.allQuizzes.length;
    
    // Get all quiz attempts
    final totalAttempts = MockData.attempts.length;
    
    return {
      'totalUsers': totalUsers,
      'totalCourses': totalCourses,
      'totalQuizzes': totalQuizzes,
      'totalAttempts': totalAttempts,
    };
  }
}
