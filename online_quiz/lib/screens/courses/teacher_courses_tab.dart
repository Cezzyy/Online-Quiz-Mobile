import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../utils/app_theme.dart';
import '../../widgets/courses_skeleton_loader.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/local_auth_provider.dart';
import 'view_students_screen.dart';
import 'manage_course_screen.dart';

class TeacherCoursesTab extends ConsumerStatefulWidget {
  const TeacherCoursesTab({super.key});

  @override
  ConsumerState<TeacherCoursesTab> createState() => _TeacherCoursesTabState();
}

class _TeacherCoursesTabState extends ConsumerState<TeacherCoursesTab> {
  // Cache for course statistics to avoid showing "Loading..." on refresh
  final Map<int, Map<String, int>> _statisticsCache = {};

  @override
  void initState() {
    super.initState();
    // Initialize courses when the tab is first loaded
    Future.microtask(() {
      final currentUser = ref.read(currentUserProvider);
      final userRole = ref.read(currentUserRoleProvider);
      final localAuthState = ref.read(localAuthProvider);
      
      if (currentUser != null) {
        // If app was just unlocked, clear cache and reload data
        if (localAuthState.shouldReloadData) {
          _statisticsCache.clear();
        }
        
        ref
            .read(courseProvider.notifier)
            .initializeCourses(currentUser.userId, userRole: userRole);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseProvider);
    final currentUser = ref.watch(currentUserProvider);
    final localAuthState = ref.watch(localAuthProvider);
    final theme = Theme.of(context);

    // Show loading skeleton
    if (currentUser == null || localAuthState.shouldReloadData || courseState.isLoading) {
      return const CoursesSkeletonLoader();
    }

    // Get teacher's courses from Supabase and filter to only show active courses
    final allTeacherCourses = courseState.allCourses;
    final teacherCourses = allTeacherCourses
        .where((course) => course.isActive)
        .toList();

    // Show error if there's an error
    if (courseState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading courses',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                courseState.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final userRole = ref.read(currentUserRoleProvider);
                  ref
                      .read(courseProvider.notifier)
                      .initializeCourses(
                        currentUser.userId,
                        userRole: userRole,
                      );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final userRole = ref.read(currentUserRoleProvider);
          await ref
              .read(courseProvider.notifier)
              .initializeCourses(currentUser.userId, userRole: userRole);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header Section with Gradient
              _buildHeader(context, teacherCourses),
              const SizedBox(height: 24),
              
              // Courses List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    teacherCourses.isEmpty 
                        ? _buildEmptyState()
                        : _buildCoursesList(context, teacherCourses),
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

  Widget _buildHeader(BuildContext context, List<Course> teacherCourses) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight < 700 ? 200.0 : 220.0;
    
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Gradient Background
        Container(
          height: headerHeight,
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
        // Content
        Positioned(
          top: MediaQuery.of(context).padding.top + 40,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                color: Colors.white,
                size: screenHeight < 700 ? 40 : 48,
              ),
              SizedBox(height: screenHeight < 700 ? 12 : 16),
              Text(
                'My Courses',
                style: TextStyle(
                  fontSize: screenHeight < 700 ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${teacherCourses.length} ${teacherCourses.length == 1 ? 'Course' : 'Courses'} Teaching',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Courses Assigned',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any courses assigned yet.\nContact your administrator to get courses assigned.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final currentUser = ref.read(currentUserProvider);
                final userRole = ref.read(currentUserRoleProvider);
                if (currentUser != null) {
                  ref
                      .read(courseProvider.notifier)
                      .initializeCourses(currentUser.userId, userRole: userRole);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList(BuildContext context, List<Course> courses) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return TeacherCourseCard(
          course: course,
          statisticsCache: _statisticsCache,
        );
      },
    );
  }
}

// Standalone widget for proper theme reactivity
class TeacherCourseCard extends ConsumerWidget {
  final Course course;
  final Map<int, Map<String, int>> statisticsCache;

  const TeacherCourseCard({
    super.key,
    required this.course,
    required this.statisticsCache,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCourseColor(course.code).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.book,
                      color: _getCourseColor(course.code),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.code,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Course Info
              FutureBuilder<Map<String, int>>(
                future: _getCourseStatistics(ref, course.courseId),
                builder: (context, snapshot) {
                  // Use cached data if available, otherwise use snapshot data
                  Map<String, int>? stats = statisticsCache[course.courseId];
                  
                  if (snapshot.hasData && snapshot.data != null) {
                    // Update cache with new data
                    stats = snapshot.data!;
                    statisticsCache[course.courseId] = stats;
                  }
                  
                  final enrollmentCount = stats?['enrollments'] ?? 0;
                  final quizCount = stats?['quizzes'] ?? 0;
                  final submissionCount = stats?['submissions'] ?? 0;

                  return Column(
                    children: [
                      _buildInfoRow(
                        context,
                        isDark,
                        'Students Enrolled',
                        Text(
                          enrollmentCount.toString(),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Divider(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        height: 16,
                      ),
                      _buildInfoRow(
                        context,
                        isDark,
                        'Total Quizzes',
                        Text(
                          quizCount.toString(),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Divider(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        height: 16,
                      ),
                      _buildInfoRow(
                        context,
                        isDark,
                        'Submissions',
                        Text(
                          submissionCount.toString(),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Divider(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        height: 16,
                      ),
                      _buildInfoRow(
                        context,
                        isDark,
                        'Status',
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(course.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            course.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(course.status),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewStudentsScreen(course: course),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people, size: 18),
                      label: const Text('Students'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _getCourseColor(course.code),
                        side: BorderSide(color: _getCourseColor(course.code)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageCourseScreen(course: course),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Manage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getCourseColor(course.code),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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
  
  Widget _buildInfoRow(BuildContext context, bool isDark, String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(child: valueWidget),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getCourseStatistics(WidgetRef ref, int courseId) async {
    try {
      final enrollments = await ref
          .read(courseProvider.notifier)
          .getEnrolledStudentsWithDetails(courseId);
      final quizzes = await ref
          .read(courseProvider.notifier)
          .getCourseQuizzes(courseId);

      int totalSubmissions = 0;
      for (final quiz in quizzes) {
        final attempts = await ref
            .read(courseProvider.notifier)
            .getQuizAttempts(quiz.quizId);
        totalSubmissions += attempts
            .where((attempt) => attempt.submittedAt != null)
            .length;
      }

      return {
        'enrollments': enrollments.length,
        'quizzes': quizzes.length,
        'submissions': totalSubmissions,
      };
    } catch (e) {
      return {'enrollments': 0, 'quizzes': 0, 'submissions': 0};
    }
  }
  
  Color _getCourseColor(String courseCode) {
    return AppTheme.getCourseColor(courseCode);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
