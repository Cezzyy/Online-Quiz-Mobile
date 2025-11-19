import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/stat_card.dart';
import '../../utils/app_theme.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import 'view_students_screen.dart';
import 'manage_course_screen.dart';

class TeacherCoursesTab extends ConsumerStatefulWidget {
  const TeacherCoursesTab({super.key});

  @override
  ConsumerState<TeacherCoursesTab> createState() => _TeacherCoursesTabState();
}

class _TeacherCoursesTabState extends ConsumerState<TeacherCoursesTab> {
  @override
  void initState() {
    super.initState();
    // Initialize courses when the tab is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      final userRole = ref.read(currentUserRoleProvider);
      if (currentUser != null) {
        ref.read(courseProvider.notifier).initializeCourses(currentUser.userId, userRole: userRole);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get teacher's courses from Supabase
    final teacherCourses = courseState.allCourses;
    
    // Show loading indicator while courses are being loaded
    if (courseState.isLoading && teacherCourses.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Show error if there's an error
    if (courseState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading courses',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                courseState.error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final userRole = ref.read(currentUserRoleProvider);
                  ref.read(courseProvider.notifier).initializeCourses(currentUser.userId, userRole: userRole);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header Section
            _buildHeader(context, teacherCourses),
            const SizedBox(height: 30),
            
            // Courses List
            Expanded(
              child: teacherCourses.isEmpty 
                  ? _buildEmptyState()
                  : _buildCoursesList(context, teacherCourses),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, List<Course> teacherCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
           'My Courses',
           style: TextStyle(
             fontSize: 28,
             fontWeight: FontWeight.bold,
             color: Theme.of(context).colorScheme.onSurface,
           ),
         ),
         const SizedBox(height: 8),
         Text(
           'You are teaching ${teacherCourses.length} ${teacherCourses.length == 1 ? 'course' : 'courses'}',
           style: TextStyle(
             fontSize: 16,
             color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
           ),
         ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.school_outlined,
      title: 'No Classes Assigned',
      message: 'You don\'t have any classes assigned yet.\nContact your administrator to get courses assigned.',
      action: ElevatedButton(
        onPressed: () {
          final currentUser = ref.read(currentUserProvider);
          final userRole = ref.read(currentUserRoleProvider);
          if (currentUser != null) {
            ref.read(courseProvider.notifier).initializeCourses(currentUser.userId, userRole: userRole);
          }
        },
        child: const Text('Refresh'),
      ),
    );
  }

  Widget _buildCoursesList(BuildContext context, List<Course> courses) {
    return ListView.builder(
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCourseCard(context, course),
        );
      },
    );
  }
  
  Widget _buildCourseCard(BuildContext context, Course course) {
    // Data will be loaded dynamically in the UI
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCourseColor(course.code).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.class_,
                    color: _getCourseColor(course.code),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: TextStyle(
                           fontSize: 20,
                           fontWeight: FontWeight.bold,
                           color: Theme.of(context).colorScheme.onSurface,
                         ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.code,
                        style: TextStyle(
                           fontSize: 16,
                           color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                           fontWeight: FontWeight.w500,
                         ),
                      ),
                      if (course.category != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Category: ${course.category}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Status: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(course.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Statistics Row - Load dynamically from Supabase
            FutureBuilder<Map<String, int>>(
              future: _getCourseStatistics(course.courseId),
              builder: (context, snapshot) {
                final enrollmentCount = snapshot.data?['enrollments'] ?? 0;
                final quizCount = snapshot.data?['quizzes'] ?? 0;
                final submissionCount = snapshot.data?['submissions'] ?? 0;
                
                return Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.people_outline,
                        title: 'Students',
                        value: snapshot.connectionState == ConnectionState.waiting 
                            ? '...' 
                            : enrollmentCount.toString(),
                        color: AppTheme.successColor,
                        height: 150,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: Icons.quiz_outlined,
                        title: 'Quizzes',
                        value: snapshot.connectionState == ConnectionState.waiting 
                            ? '...' 
                            : quizCount.toString(),
                        color: AppTheme.getQuizTypeColor('quiz'),
                        height: 150,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Submissions',
                        value: snapshot.connectionState == ConnectionState.waiting 
                            ? '...' 
                            : submissionCount.toString(),
                        color: AppTheme.getQuizTypeColor('system'),
                        height: 150,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            
            // Recent Activity
            _buildRecentActivity(context, course),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewStudents(context, course),
                    icon: const Icon(Icons.people, size: 18),
                    label: const Text('View Students'),
                    style: OutlinedButton.styleFrom(
                       foregroundColor: Theme.of(context).colorScheme.onSurface,
                       side: BorderSide(color: Theme.of(context).dividerColor),
                       padding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _manageCourse(context, course),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Manage Course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getCourseColor(course.code),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  

  
  Widget _buildRecentActivity(BuildContext context, Course course) {
    // Simplified: Just show that quiz activity exists
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
           'Recent Activity',
           style: TextStyle(
             fontSize: 16,
             fontWeight: FontWeight.w600,
             color: Theme.of(context).colorScheme.onSurface,
           ),
         ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.successColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                   'View detailed activity in Results tab',
                   style: TextStyle(
                     color: Theme.of(context).colorScheme.onSurface,
                     fontSize: 14,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Future<Map<String, int>> _getCourseStatistics(int courseId) async {
    try {
      final enrollments = await ref.read(courseProvider.notifier).getEnrolledStudentsWithDetails(courseId);
      final quizzes = await ref.read(courseProvider.notifier).getCourseQuizzes(courseId);
      
      int totalSubmissions = 0;
      for (final quiz in quizzes) {
        final attempts = await ref.read(courseProvider.notifier).getQuizAttempts(quiz.quizId);
        totalSubmissions += attempts.where((attempt) => attempt.submittedAt != null).length;
      }
      
      return {
        'enrollments': enrollments.length,
        'quizzes': quizzes.length,
        'submissions': totalSubmissions,
      };
    } catch (e) {
      return {
        'enrollments': 0,
        'quizzes': 0,
        'submissions': 0,
      };
    }
  }  void _viewStudents(BuildContext context, Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewStudentsScreen(course: course),
      ),
    );
  }
  
  void _manageCourse(BuildContext context, Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageCourseScreen(course: course),
      ),
    );
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