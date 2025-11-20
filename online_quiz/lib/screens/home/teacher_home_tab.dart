import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/info_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_profile_provider.dart';
import '../../services/teacher_service.dart';
import '../../services/quiz_service.dart';

class TeacherHomeTab extends ConsumerStatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const TeacherHomeTab({super.key, this.onNavigateToTab});

  @override
  ConsumerState<TeacherHomeTab> createState() => _TeacherHomeTabState();
}

class _TeacherHomeTabState extends ConsumerState<TeacherHomeTab> {
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoadingActivity = false;
  String? _activityError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null && mounted) {
        ref.read(teacherProfileProvider.notifier).loadTeacherData(currentUser.userId);
        _loadRecentActivityData(currentUser.userId);
      }
    });
  }

  Future<void> _loadRecentActivityData(int userId) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingActivity = true;
      _activityError = null;
    });

    try {
      final teacherService = TeacherService();
      final activity = await teacherService.getRecentActivity(userId, limit: 5);
      
      // Calculate percentage for each activity by fetching quiz details
      final quizService = QuizService();
      for (final item in activity) {
        try {
          final quizId = item['QuizId'] as int;
          final score = (item['TotalScore'] as num?)?.toDouble() ?? 0.0;
          
          // Get quiz questions to calculate total possible points
          final questions = await quizService.getQuizQuestions(quizId);
          final totalPoints = questions.fold<double>(0.0, (sum, q) => sum + q.points);
          
          // Calculate percentage
          item['ScorePercentage'] = totalPoints > 0 ? (score / totalPoints) * 100 : 0.0;
        } catch (e) {
          // If we can't calculate percentage, default to 0
          item['ScorePercentage'] = 0.0;
        }
      }
      
      if (mounted) {
        setState(() {
          _recentActivity = activity;
          _isLoadingActivity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activityError = e.toString();
          _isLoadingActivity = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final teacherState = ref.watch(teacherProfileProvider);
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (teacherState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (teacherState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  teacherState.error!,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(teacherProfileProvider.notifier).loadTeacherData(currentUser.userId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    final statistics = ref.watch(teacherStatisticsProvider);
    final courses = ref.watch(teacherCoursesProvider);
    final quizzes = ref.watch(teacherQuizzesProvider);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(teacherProfileProvider.notifier).refreshTeacherData(currentUser.userId);
          await _loadRecentActivityData(currentUser.userId);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Welcome Section
              _buildWelcomeSection(context, currentUser),
              const SizedBox(height: 30),
              
              // Statistics Cards
              _buildStatsSection(context, statistics, teacherState.totalStudents),
              const SizedBox(height: 30),
              
              // Course Overview
              _buildCourseOverview(context, courses, quizzes),
              const SizedBox(height: 30),
              
              // Recent Quiz Activity
              _buildRecentQuizActivity(context),
            ],
          ),
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
  
  Widget _buildStatsSection(BuildContext context, Map<String, num> stats, double totalStudents) {
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
                value: stats['courses'].toString(),
                color: AppTheme.getQuizTypeColor('course'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                icon: Icons.people_outline,
                title: 'Students',
                value: totalStudents.toInt().toString(),
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
                value: stats['quizzes'].toString(),
                color: AppTheme.getQuizTypeColor('quiz'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Quizzes',
                value: stats['quizzes'].toString(),
                color: AppTheme.getQuizTypeColor('system'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCourseOverview(BuildContext context, List<Course> courses, List<dynamic> allQuizzes) {
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
                // Navigate to courses tab (index 1)
                widget.onNavigateToTab?.call(1);
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
            children: courses.take(5).map((course) {
              final courseQuizzes = allQuizzes.where((q) => q.courseId == course.courseId).toList();
              final courseColor = AppTheme.getCourseColor(course.code);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InfoCard(
                  icon: Icons.book,
                  title: '${course.code} • ${courseQuizzes.length} Quizzes',
                  value: course.name,
                  iconColor: courseColor,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
  
  Widget _buildRecentQuizActivity(BuildContext context) {
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
        if (_isLoadingActivity)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_activityError != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Error loading activity: $_activityError',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          )
        else if (_recentActivity.isEmpty)
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
            child: const EmptyStateWidget(
              icon: Icons.quiz_outlined,
              title: 'No Recent Activity',
              message: 'No quiz submissions yet. Students will appear here once they start taking quizzes.',
              iconSize: 48,
              titleFontSize: 16,
              messageFontSize: 14,
              padding: EdgeInsets.all(16),
            ),
          )
        else
          Column(
            children: _recentActivity.map((activity) {
              final scorePercentage = (activity['ScorePercentage'] as num?)?.toDouble() ?? 0.0;
              final submittedAt = activity['SubmittedAt'] != null 
                  ? DateTime.parse(activity['SubmittedAt'] as String)
                  : DateTime.now();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.getDividerColor(context).withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.getDividerColor(context).withValues(alpha: 0.05),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Navigate to attempt details
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Icon with score color
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.getScoreColor(scorePercentage).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.assignment_turned_in,
                              color: AppTheme.getScoreColor(scorePercentage),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Student and quiz info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['StudentName'] as String? ?? 'Unknown Student',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.getTextColor(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activity['QuizName'] as String? ?? 'Quiz',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.getSecondaryTextColor(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.book_outlined,
                                      size: 14,
                                      color: AppTheme.getSecondaryTextColor(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      activity['CourseCode'] as String? ?? 'Course',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.getSecondaryTextColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Score and date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.getScoreColor(scorePercentage).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${scorePercentage.round()}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.getScoreColor(scorePercentage),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: AppTheme.getSecondaryTextColor(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(submittedAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.getSecondaryTextColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
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