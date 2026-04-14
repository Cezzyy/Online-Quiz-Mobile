import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_profile_provider.dart';
import '../../providers/local_auth_provider.dart';
import '../../services/teacher_service.dart';
import '../../services/quiz_service.dart';
import '../../widgets/home_skeleton_loader.dart';
import '../courses/manage_course_screen.dart';

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
      final localAuthState = ref.read(localAuthProvider);
      
      if (currentUser != null && mounted) {
        // If app was just unlocked, reset to loading state first
        if (localAuthState.shouldReloadData) {
          ref.read(teacherProfileProvider.notifier).resetToLoading();
          // Also reset local state
          setState(() {
            _recentActivity = [];
            _isLoadingActivity = false;
            _activityError = null;
          });
        }
        
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
    final localAuthState = ref.watch(localAuthProvider);
    final theme = Theme.of(context);
    
    // Show loading indicator
    if (teacherState.isLoading || 
        currentUser == null || 
        localAuthState.shouldReloadData ||
        teacherState.user == null ||
        teacherState.user?.userId != currentUser.userId) {
      return const HomeSkeletonLoader();
    }

    if (teacherState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading data',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                teacherState.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header Section with Gradient
              _buildHeader(context, currentUser),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Cards
                    _buildStatsCard(context, statistics, teacherState.totalStudents),

                    const SizedBox(height: 16),

                    // Course Overview
                    if (courses.isNotEmpty)
                      _buildCoursesCard(context, courses, quizzes),

                    const SizedBox(height: 16),

                    // Recent Quiz Activity
                    _buildRecentActivityCard(context),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, User user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        screenWidth < 360 ? 16 : 24,
        screenWidth < 360 ? 50 : 60,
        screenWidth < 360 ? 16 : 24,
        screenWidth < 360 ? 30 : 40,
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                greetingIcon,
                color: Colors.white,
                size: screenWidth < 360 ? 24 : 28,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  greeting,
                  style: TextStyle(
                    fontSize: screenWidth < 360 ? 16 : 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Instructor ${user.fullName}',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Ready to inspire and educate your students',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 12 : 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    Map<String, num> stats,
    double totalStudents,
  ) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
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
                Icon(Icons.analytics, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Teaching Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.book,
                    label: 'Courses',
                    value: stats['courses'].toString(),
                    color: Colors.blue,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.people,
                    label: 'Students',
                    value: totalStudents.toInt().toString(),
                    color: Colors.green,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.quiz,
                    label: 'Quizzes',
                    value: stats['quizzes'].toString(),
                    color: Colors.orange,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.assignment_turned_in,
                    label: 'Submissions',
                    value: _recentActivity.length.toString(),
                    color: Colors.amber,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isSmallScreen = false,
  }) {
    final theme = Theme.of(context);
    final iconSize = isSmallScreen ? 24.0 : 28.0;
    final valueFontSize = isSmallScreen ? 20.0 : 24.0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 12 : 16,
        horizontal: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(height: isSmallScreen ? 6 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: isSmallScreen ? 11 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesCard(
    BuildContext context,
    List<Course> courses,
    List<dynamic> allQuizzes,
  ) {
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
                Icon(Icons.book, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Your Courses',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...courses.take(3).map((course) {
              final courseQuizzes = allQuizzes.where((q) => q.courseId == course.courseId).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCourseItem(context, course, courseQuizzes.length),
              );
            }),
            if (courses.length > 3)
              Center(
                child: TextButton(
                  onPressed: () {
                    widget.onNavigateToTab?.call(1);
                  },
                  child: const Text('View All Courses'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseItem(BuildContext context, Course course, int quizCount) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageCourseScreen(course: course),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.class_,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${course.code} • $quizCount Quizzes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context) {
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
                Icon(Icons.history, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recent Quiz Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingActivity)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_activityError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading activity',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_recentActivity.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_recentActivity.take(3).map((activity) {
                final scorePercentage = (activity['ScorePercentage'] as num?)?.toDouble() ?? 0.0;
                final submittedAt = activity['SubmittedAt'] != null 
                    ? DateTime.parse(activity['SubmittedAt'] as String)
                    : DateTime.now();
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildActivityItem(
                    context,
                    activity['StudentName'] as String? ?? 'Unknown Student',
                    activity['QuizName'] as String? ?? 'Quiz',
                    activity['CourseCode'] as String? ?? 'Course',
                    scorePercentage,
                    submittedAt,
                  ),
                );
              })),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String studentName,
    String quizName,
    String courseCode,
    double scorePercentage,
    DateTime submittedAt,
  ) {
    final theme = Theme.of(context);
    final scoreColor = scorePercentage >= 75 
        ? Colors.green 
        : scorePercentage >= 50 
            ? Colors.orange 
            : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.assignment_turned_in,
              color: scoreColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  quizName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  courseCode,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${scorePercentage.round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(submittedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
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