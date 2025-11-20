import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/app_theme.dart';

class AdminHomeTab extends ConsumerStatefulWidget {
  const AdminHomeTab({super.key});

  @override
  ConsumerState<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends ConsumerState<AdminHomeTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(adminDashboardProvider.notifier).loadDashboardData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Watch providers for reactive updates
    final dashboardState = ref.watch(adminDashboardProvider);
    
    // If loading, show loading indicator
    if (dashboardState.isLoading && dashboardState.statistics.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(adminDashboardProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Welcome Section
              _buildWelcomeSection(context, user),
              const SizedBox(height: 30),
              
              // Statistics Cards
              _buildStatsSection(context, dashboardState.statistics),
              const SizedBox(height: 30),
              
              // System Health
              _buildSystemHealth(context, dashboardState.systemHealth),
              const SizedBox(height: 30),
              
              // System Overview
              _buildSystemOverview(context),
            ],
          ),
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
  
  Widget _buildStatsSection(BuildContext context, Map<String, int> stats) {
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
                value: (stats['totalUsers'] ?? 0).toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.class_outlined,
                title: 'Total Courses',
                value: (stats['totalCourses'] ?? 0).toString(),
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
                value: (stats['totalQuizzes'] ?? 0).toString(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.analytics_outlined,
                title: 'Quiz Attempts',
                value: (stats['totalAttempts'] ?? 0).toString(),
                color: Colors.purple,
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
                icon: Icons.school_outlined,
                title: 'Active Students',
                value: (stats['activeStudents'] ?? 0).toString(),
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.person_outline,
                title: 'Active Teachers',
                value: (stats['activeTeachers'] ?? 0).toString(),
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSystemHealth(BuildContext context, Map<String, dynamic> health) {
    if (health.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Quiz Activity',
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
                icon: Icons.check_circle_outline,
                title: 'Completion Rate',
                value: '${health['completionRate'] ?? 0}%',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.star_outline,
                title: 'Average Score',
                value: '${health['averageScore'] ?? 0}%',
                color: Colors.amber,
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
                icon: Icons.trending_up,
                title: 'Active Courses',
                value: (health['activeCourses'] ?? 0).toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.publish,
                title: 'Published Quizzes',
                value: (health['publishedQuizzes'] ?? 0).toString(),
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
  
}
