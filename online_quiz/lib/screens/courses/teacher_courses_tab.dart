import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/stat_card.dart';
import '../../utils/app_theme.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';

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
      if (currentUser != null) {
        ref.read(courseProvider.notifier).initializeCourses(currentUser.userId);
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

    // Get teacher's courses
    final teacherCourses = MockData.getCoursesByInstructor(currentUser.userId);
    
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
                  ref.read(courseProvider.notifier).initializeCourses(currentUser.userId);
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
           'My Classes',
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
          if (currentUser != null) {
            ref.read(courseProvider.notifier).initializeCourses(currentUser.userId);
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
    final enrollments = MockData.getEnrollmentsByCourse(course.courseId);
    final quizzes = MockData.getQuizzesByCourse(course.courseId);
    final totalAttempts = _getTotalAttemptsForCourse(course.courseId);
    
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.people_outline,
                    title: 'Students',
                    value: enrollments.length.toString(),
                    color: AppTheme.successColor,
                    height: 110,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.quiz_outlined,
                    title: 'Quizzes',
                    value: quizzes.length.toString(),
                    color: AppTheme.getQuizTypeColor('quiz'),
                    height: 110,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Submissions',
                    value: totalAttempts.toString(),
                    color: AppTheme.getQuizTypeColor('system'),
                    height: 110,
                  ),
                ),
              ],
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
                    onPressed: () => _manageQuizzes(context, course),
                    icon: const Icon(Icons.quiz, size: 18),
                    label: const Text('Manage Quizzes'),
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
    final recentAttempts = _getRecentAttemptsForCourse(course.courseId);
    
    if (recentAttempts.isEmpty) {
      return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
           borderRadius: BorderRadius.circular(12),
         ),
         child: Row(
           children: [
             Icon(
               Icons.info_outline,
               color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
               size: 20,
             ),
             const SizedBox(width: 12),
             Text(
               'No recent quiz activity',
               style: TextStyle(
                 color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                 fontSize: 14,
               ),
             ),
           ],
         ),
       );
    }
    
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
                   '${recentAttempts.length} recent quiz ${recentAttempts.length == 1 ? 'submission' : 'submissions'}',
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
  
  int _getTotalAttemptsForCourse(int courseId) {
    final quizzes = MockData.getQuizzesByCourse(courseId);
    int totalAttempts = 0;
    
    for (final quiz in quizzes) {
      final attempts = MockData.getAttemptsByQuiz(quiz.quizId);
      totalAttempts += attempts.where((attempt) => attempt.submittedAt != null).length;
    }
    
    return totalAttempts;
  }
  
  List<dynamic> _getRecentAttemptsForCourse(int courseId) {
    final quizzes = MockData.getQuizzesByCourse(courseId);
    final recentAttempts = <dynamic>[];
    
    for (final quiz in quizzes) {
      final attempts = MockData.getAttemptsByQuiz(quiz.quizId)
          .where((attempt) => attempt.submittedAt != null)
          .toList();
      recentAttempts.addAll(attempts);
    }
    
    // Sort by submission date and take the most recent ones
    recentAttempts.sort((a, b) => b.submittedAt!.compareTo(a.submittedAt!));
    return recentAttempts.take(5).toList();
  }
  
  void _viewStudents(BuildContext context, Course course) {
    final enrollments = MockData.getEnrollmentsByCourse(course.courseId);
    final students = enrollments.map((enrollment) {
      return MockData.getUserById(enrollment.userId);
    }).where((user) => user != null).cast<User>().toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Students in ${course.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: students.isEmpty
              ? const Text('No students enrolled in this course.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(
                        student.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        student.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _manageQuizzes(BuildContext context, Course course) {
    final quizzes = MockData.getQuizzesByCourse(course.courseId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quizzes in ${course.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: quizzes.isEmpty
              ? const Text('No quizzes created for this course yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final attempts = MockData.getAttemptsByQuiz(quiz.quizId)
                        .where((attempt) => attempt.submittedAt != null)
                        .length;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.getQuizTypeColor('quiz').withValues(alpha: 0.1),
                        child: Icon(
                          Icons.quiz,
                          color: AppTheme.getQuizTypeColor('quiz'),
                        ),
                      ),
                      title: Text(
                        quiz.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '$attempts submissions • ${quiz.timeLimitMinutes} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: Icon(
                         quiz.isPublished ? Icons.visibility : Icons.visibility_off,
                         color: quiz.isPublished ? Colors.green : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                       ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Color _getCourseColor(String courseCode) {
    return AppTheme.getCourseColor(courseCode);
  }
}