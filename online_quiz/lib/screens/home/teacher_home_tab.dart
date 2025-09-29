import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/attempt.dart';
import '../../models/user.dart';
import '../../data/mock_data.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/info_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/app_theme.dart';
import '../../providers/course_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';

class TeacherHomeTab extends ConsumerWidget {
  const TeacherHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Watch providers for reactive updates
    final courseState = ref.watch(courseProvider);
    
    // Initialize providers if not already loaded
    if (!courseState.isLoading && courseState.allCourses.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(courseProvider.notifier).initializeCourses(currentUser.userId);
        ref.read(quizProvider.notifier).initializeQuizzes(currentUser.userId);
      });
    }
    
    // Get teacher's courses
    final teacherCourses = MockData.getCoursesByInstructor(currentUser.userId);
    final teacherStats = _calculateTeacherStats(teacherCourses);
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Welcome Section
            _buildWelcomeSection(context, currentUser),
            const SizedBox(height: 30),
            
            // Statistics Cards
            _buildStatsSection(context, teacherStats),
            const SizedBox(height: 30),
            
            // Course Overview
            _buildCourseOverview(context, teacherCourses),
            const SizedBox(height: 30),
            
            // Recent Quiz Activity
            _buildRecentQuizActivity(context, teacherCourses),
            const SizedBox(height: 30),
            
            // Quick Actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWelcomeSection(BuildContext context, User user) {
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
    final primaryColor = AppTheme.secondaryColor;
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
            'Instructor ${user.fullName.split(' ')[0]}',
            style: TextStyle(
              color: onPrimaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to inspire and educate your students?',
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
          'Teaching Overview',
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
              child: StatCard(
                icon: Icons.book_outlined,
                title: 'Courses',
                value: stats['totalCourses'].toString(),
                color: AppTheme.getQuizTypeColor('course'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                icon: Icons.people_outline,
                title: 'Students',
                value: stats['totalStudents'].toString(),
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.quiz_outlined,
                title: 'Quizzes',
                value: stats['totalQuizzes'].toString(),
                color: AppTheme.getQuizTypeColor('quiz'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Submissions',
                value: stats['totalSubmissions'].toString(),
                color: AppTheme.getQuizTypeColor('system'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCourseOverview(BuildContext context, List<Course> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Courses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to courses tab
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (courses.isEmpty)
          EmptyStateWidget(
            icon: Icons.book_outlined,
            title: 'No Courses Yet',
            message: 'You haven\'t been assigned to any courses yet.',
            iconSize: 64,
            titleFontSize: 18,
            messageFontSize: 14,
            padding: const EdgeInsets.all(24),
          )
        else
          Column(
            children: courses.map((course) {
              final courseQuizzes = MockData.getQuizzesByCourse(course.courseId);
              final enrolledStudents = MockData.getEnrollmentsByCourse(course.courseId);
              final totalAttempts = _getTotalAttemptsForCourse(course.courseId);
              final courseColor = AppTheme.getCourseColor(course.code);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InfoCard(
                  icon: Icons.book,
                  title: '${enrolledStudents.length} Students • ${courseQuizzes.length} Quizzes',
                  value: course.name,
                  iconColor: courseColor,
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalAttempts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Submissions',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to course details
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
  
  Widget _buildRecentQuizActivity(BuildContext context, List<Course> courses) {
    final recentAttempts = _getRecentAttempts(courses);
    
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
        if (recentAttempts.isEmpty)
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
            child: EmptyStateWidget(
              icon: Icons.quiz_outlined,
              title: 'No Recent Activity',
              message: 'No quiz submissions yet. Students will appear here once they start taking quizzes.',
              iconSize: 48,
              titleFontSize: 16,
              messageFontSize: 14,
              padding: const EdgeInsets.all(16),
            ),
          )
        else
          Column(
            children: recentAttempts.take(5).map((attempt) {
              final quiz = MockData.getQuizById(attempt.quizId);
              final student = MockData.getUserById(attempt.userId);
              final course = courses.firstWhere((c) => 
                MockData.getQuizzesByCourse(c.courseId).any((q) => q.quizId == attempt.quizId)
              );
              
              if (quiz == null || student == null) return const SizedBox.shrink();
              
              // Calculate percentage score
              final questions = MockData.getQuestionsByQuiz(attempt.quizId);
              final totalPoints = questions.fold<double>(0.0, (sum, q) => sum + q.points);
              final scorePercentage = totalPoints > 0 ? (attempt.score / totalPoints) * 100 : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InfoCard(
                  icon: Icons.assignment_turned_in,
                  title: student.fullName,
                  value: '${quiz.title} • ${course.code}',
                  iconColor: AppTheme.getScoreColor(scorePercentage),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${scorePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getScoreColor(scorePercentage),
                        ),
                      ),
                      Text(
                        _formatDate(attempt.submittedAt ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to attempt details
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
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
                context,
                icon: Icons.add_circle_outline,
                title: 'Create Quiz',
                subtitle: 'Add new quiz',
                color: AppTheme.primaryColor,
                onTap: () {
                  // Navigate to create quiz
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.people_outline,
                title: 'Manage Students',
                subtitle: 'View enrollments',
                color: AppTheme.secondaryColor,
                onTap: () {
                  // Navigate to student management
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.analytics_outlined,
                title: 'View Analytics',
                subtitle: 'Course insights',
                color: AppTheme.accentColor,
                onTap: () {
                  // Navigate to analytics
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Course settings',
                color: AppTheme.getSecondaryTextColor(context),
                onTap: () {
                  // Navigate to settings
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.getDividerColor(context).withValues(alpha: 0.2),
          ),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Map<String, dynamic> _calculateTeacherStats(List<Course> courses) {
    int totalStudents = 0;
    int totalQuizzes = 0;
    int totalSubmissions = 0;
    
    for (var course in courses) {
      // Count enrolled students
      final enrollments = MockData.getEnrollmentsByCourse(course.courseId);
      totalStudents += enrollments.length;
      
      // Count quizzes
      final quizzes = MockData.getQuizzesByCourse(course.courseId);
      totalQuizzes += quizzes.length;
      
      // Count submissions
      for (var quiz in quizzes) {
        final attempts = MockData.getAttemptsByQuiz(quiz.quizId);
        totalSubmissions += attempts.where((a) => a.submittedAt != null).length;
      }
    }
    
    return {
      'totalCourses': courses.length,
      'totalStudents': totalStudents,
      'totalQuizzes': totalQuizzes,
      'totalSubmissions': totalSubmissions,
    };
  }
  
  int _getTotalAttemptsForCourse(int courseId) {
    final quizzes = MockData.getQuizzesByCourse(courseId);
    int totalAttempts = 0;
    
    for (var quiz in quizzes) {
      final attempts = MockData.getAttemptsByQuiz(quiz.quizId);
      totalAttempts += attempts.where((a) => a.submittedAt != null).length;
    }
    
    return totalAttempts;
  }
  
  List<Attempt> _getRecentAttempts(List<Course> courses) {
    List<Attempt> allAttempts = [];
    
    for (var course in courses) {
      final quizzes = MockData.getQuizzesByCourse(course.courseId);
      for (var quiz in quizzes) {
        final attempts = MockData.getAttemptsByQuiz(quiz.quizId);
        allAttempts.addAll(attempts.where((a) => a.submittedAt != null));
      }
    }
    
    // Sort by submission date (most recent first)
    allAttempts.sort((a, b) => (b.submittedAt ?? DateTime.now()).compareTo(a.submittedAt ?? DateTime.now()));
    
    return allAttempts;
  }
  

  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${difference}d ago';
    }
  }
}