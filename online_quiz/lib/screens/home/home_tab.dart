import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../data/mock_data.dart';
import '../../models/attempt.dart';
import '../../models/user.dart';
import '../../widgets/stat_card.dart';
import '../../utils/app_theme.dart';
import '../../providers/course_provider.dart';
import '../../providers/quiz_provider.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = MockData.users.firstWhere((u) => u.userId == 4); // Get first student for demo
    
    // Watch providers for reactive updates
    final courseState = ref.watch(courseProvider);
    
    // Initialize providers if not already loaded
    if (!courseState.isLoading && courseState.userCourses.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(courseProvider.notifier).initializeCourses(user.userId);
        ref.read(quizProvider.notifier).initializeQuizzes(user.userId);
      });
    }
    
    final userCourses = courseState.userCourses;
    final completedAttempts = _getCompletedAttempts(user.userId);
    final totalQuizzes = _getTotalQuizzes(userCourses);
    final averageScore = _calculateAverageScore(completedAttempts);
    
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
            _buildStatsSection(context, totalQuizzes, completedAttempts.length, averageScore),
            const SizedBox(height: 30),
            
            // Progress Chart Section
            _buildProgressSection(context, userCourses),
            const SizedBox(height: 30),
            
            // Recent Activity
            _buildRecentActivity(context, completedAttempts),
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
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.fullName.split(' ')[0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to continue your learning journey?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsSection(BuildContext context, int totalQuizzes, int completedQuizzes, double averageScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Statistics',
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
                icon: Icons.quiz_outlined,
                title: 'Total Quizzes',
                value: totalQuizzes.toString(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                icon: Icons.check_circle_outline,
                title: 'Completed',
                value: completedQuizzes.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.trending_up,
                title: 'Average Score',
                value: '${averageScore.toStringAsFixed(1)}%',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                icon: Icons.school_outlined,
                title: 'Courses',
                value: MockData.enrollments.where((e) => e.userId == 4).length.toString(),
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
  

  
  Widget _buildProgressSection(BuildContext context, List<Course> userCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Progress',
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: userCourses.take(3).map((course) {
              final courseQuizzes = MockData.quizzes.where((q) => q.courseId == course.courseId).toList();
              final completedAttempts = MockData.attempts.where((a) => 
                courseQuizzes.any((q) => q.quizId == a.quizId) && a.submittedAt != null
              ).length;
              final totalQuizzes = courseQuizzes.length;
              final progress = totalQuizzes > 0 ? completedAttempts / totalQuizzes : 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            course.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedAttempts of $totalQuizzes quizzes completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentActivity(BuildContext context, List<Attempt> recentAttempts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: recentAttempts.take(3).map((attempt) {
              final quiz = MockData.quizzes.firstWhere((q) => q.quizId == attempt.quizId);
              final score = attempt.score;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.quiz,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Score: ${score.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(attempt.submittedAt ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  

  
  List<Attempt> _getCompletedAttempts(int userId) {
    return MockData.attempts.where((a) => 
      a.userId == userId && a.submittedAt != null
    ).toList();
  }
  
  int _getTotalQuizzes(List<Course> userCourses) {
    int total = 0;
    for (var course in userCourses) {
      total += MockData.quizzes.where((q) => q.courseId == course.courseId).length;
    }
    return total;
  }
  
  double _calculateAverageScore(List<Attempt> completedAttempts) {
    if (completedAttempts.isEmpty) return 0.0;
    
    double totalScore = 0;
    for (var attempt in completedAttempts) {
      totalScore += attempt.score;
    }
    return totalScore / completedAttempts.length;
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