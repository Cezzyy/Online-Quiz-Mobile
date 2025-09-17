import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/course.dart';
import 'course_detail_screen.dart';
import '../../widgets/empty_state_widget.dart';
import '../../utils/app_theme.dart';

class CoursesTab extends StatelessWidget {
  const CoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.users.firstWhere((u) => u.userId == 4); // Get first student for demo
    final userCourses = _getUserCourses(user.userId);
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Header Section
            _buildHeader(context, userCourses),
            const SizedBox(height: 30),
            
            // Courses Grid
            Expanded(
              child: userCourses.isEmpty 
                  ? _buildEmptyState()
                  : _buildCoursesGrid(context, userCourses),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, List<Course> userCourses) {
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
          'You are enrolled in ${userCourses.length} courses',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return EmptyStatePresets.courses();
  }

  Widget _buildCoursesGrid(BuildContext context, List<Course> courses) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(context, course);
      },
    );
  }
  
  Widget _buildCourseCard(BuildContext context, Course course) {
    final courseQuizzes = MockData.quizzes.where((q) => q.courseId == course.courseId).toList();
    final completedAttempts = MockData.attempts.where((a) => 
      courseQuizzes.any((q) => q.quizId == a.quizId) && a.submittedAt != null
    ).length;
    final totalQuizzes = courseQuizzes.length;
    final progress = totalQuizzes > 0 ? completedAttempts / totalQuizzes : 0.0;
    final teacherUser = MockData.users.where((u) => u.userId == course.instructorUserId).firstOrNull;
    
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          course.code,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Course Info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructor: ${teacherUser?.fullName ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalQuizzes Quizzes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getProgressColor(progress).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(progress * 100).toInt()}% Complete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getProgressColor(progress),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Progress Bar
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
                minHeight: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Course> _getUserCourses(int userId) {
    final enrollments = MockData.enrollments.where((e) => e.userId == userId).toList();
    return enrollments.map((enrollment) => 
      MockData.courses.firstWhere((c) => c.courseId == enrollment.courseId)
    ).toList();
  }
  
  Color _getCourseColor(String courseCode) {
    return AppTheme.getCourseColor(courseCode);
  }
  
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return AppTheme.getScoreColor(85);
    if (progress >= 0.5) return AppTheme.getScoreColor(65);
    return AppTheme.getScoreColor(45);
  }
}