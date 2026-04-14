import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/local_auth_provider.dart';
import '../../widgets/home_skeleton_loader.dart';
import '../courses/course_detail_screen.dart';
import '../quizzes/quiz_detail_screen.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
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

    // Show loading indicator
    if (profileState.isLoading || authState.user == null || localAuthState.shouldReloadData) {
      return const HomeSkeletonLoader();
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
                'Error loading data',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profileState.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
    final stats = profileState.statistics ?? {};
    final userCourses = profileState.enrolledCourses;
    final courseProgress = profileState.courseProgress;

    final totalQuizzes = stats['totalQuizzes'] as int? ?? 0;
    final completedAttempts = stats['completedAttempts'] as int? ?? 0;
    final averageScore = stats['averageScore'] as double? ?? 0.0;
    final recentAttempts = stats['recentAttempts'] as List? ?? [];

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
              // Header Section with Gradient
              _buildHeader(context, user),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Cards
                    _buildStatsCard(
                      context,
                      totalQuizzes,
                      completedAttempts,
                      averageScore,
                      userCourses.length,
                    ),

                    const SizedBox(height: 16),

                    // Enrolled Courses
                    if (userCourses.isNotEmpty)
                      _buildCoursesCard(context, userCourses, courseProgress),

                    const SizedBox(height: 16),

                    // Recent Activity
                    _buildRecentActivityCard(context, recentAttempts),

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

  Widget _buildHeader(BuildContext context, user) {
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
            user.fullName,
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
            'Welcome back to your learning dashboard',
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
    int totalQuizzes,
    int completedAttempts,
    double averageScore,
    int enrolledCourses,
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
                  'Your Statistics',
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
                    icon: Icons.quiz,
                    label: 'Quizzes',
                    value: totalQuizzes.toString(),
                    color: Colors.blue,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: completedAttempts.toString(),
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
                    icon: Icons.school,
                    label: 'Courses',
                    value: enrolledCourses.toString(),
                    color: Colors.orange,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.star,
                    label: 'Avg Score',
                    value: '${averageScore.toStringAsFixed(1)}%',
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
    Map<int, double> courseProgress,
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
                  'Enrolled Courses',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...courses.take(3).map((course) {
              final progress = courseProgress[course.courseId] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCourseItem(context, course, progress),
              );
            }),
            if (courses.length > 3)
              Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to courses tab
                  },
                  child: const Text('View All Courses'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseItem(BuildContext context, Course course, double progress) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(course: course),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        course.code,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context, List recentAttempts) {
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
                  'Recent Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentAttempts.isEmpty)
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
              ...recentAttempts.take(3).map((attempt) {
                final attemptMap = attempt as Map<String, dynamic>;
                final quizTitle = attemptMap['quizTitle'] as String;
                final quizId = attemptMap['quizId'] as int;
                final submittedAt = attemptMap['submittedAt'] as DateTime;
                final rawScore = attemptMap['score'] as double?;
                final totalPoints = attemptMap['totalPoints'] as double?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildActivityItem(
                    context,
                    quizId,
                    quizTitle,
                    rawScore,
                    totalPoints,
                    submittedAt,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    int quizId,
    String quizTitle,
    double? rawScore,
    double? totalPoints,
    DateTime submittedAt,
  ) {
    final theme = Theme.of(context);
    
    // Format score - show decimals only if needed
    String scoreText = 'N/A';
    if (rawScore != null && totalPoints != null) {
      final scoreStr = rawScore % 1 == 0 
          ? rawScore.toInt().toString()
          : rawScore.toStringAsFixed(1);
      final totalStr = totalPoints % 1 == 0 
          ? totalPoints.toInt().toString()
          : totalPoints.toStringAsFixed(1);
      scoreText = '$scoreStr/$totalStr';
    } else if (rawScore != null) {
      scoreText = rawScore % 1 == 0 
          ? rawScore.toInt().toString()
          : rawScore.toStringAsFixed(1);
    }

    return GestureDetector(
      onTap: () async {
        // Load quiz details and navigate
        final quizState = ref.read(quizProvider);
        final quiz = quizState.allQuizzes.firstWhere(
          (q) => q.quizId == quizId,
          orElse: () => throw Exception('Quiz not found'),
        );
        
        // Get course for the quiz
        final course = await ref.read(quizProvider.notifier).getCourseForQuiz(quizId);
        
        if (context.mounted) {
          final authState = ref.read(authProvider);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizDetailScreen(
                quiz: quiz,
                course: course,
                currentUserId: authState.user?.userId ?? 0,
              ),
            ),
          );
        }
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
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
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
                    quizTitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Score: $scoreText',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(submittedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
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
