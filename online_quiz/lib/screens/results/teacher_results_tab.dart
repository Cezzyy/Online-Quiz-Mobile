import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/info_card.dart';
import 'quiz_student_results_screen.dart';

class TeacherResultsTab extends ConsumerStatefulWidget {
  const TeacherResultsTab({super.key});

  @override
  ConsumerState<TeacherResultsTab> createState() => _TeacherResultsTabState();
}

class _TeacherResultsTabState extends ConsumerState<TeacherResultsTab> {
  Course? _selectedCourse;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final user = ref.read(authProvider).user;
      if (user != null) {
        await ref.read(courseProvider.notifier).initializeCourses(user.userId);
        // Load quizzes for all teacher's courses
        await _loadTeacherQuizzes();
      }
    });
  }

  Future<void> _loadTeacherQuizzes() async {
    // For teacher results, we'll load quizzes on-demand when a course is selected
    // This avoids loading all quizzes upfront
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final courseState = ref.watch(courseProvider);
    final quizState = ref.watch(quizProvider);

    if (authState.user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view results')),
      );
    }

    if (courseState.isLoading || quizState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                'Error loading data',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                courseState.error!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final userRole = ref.read(currentUserRoleProvider);
                  ref
                      .read(courseProvider.notifier)
                      .initializeCourses(
                        authState.user!.userId,
                        userRole: userRole,
                      );
                  ref
                      .read(quizProvider.notifier)
                      .initializeQuizzes(authState.user!.userId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter to only show active courses
    final allCourses = courseState.allCourses;
    final teacherCourses = allCourses
        .where((course) => course.isActive)
        .toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Course Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Course',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (teacherCourses.isEmpty)
                      InfoCard(
                        icon: Icons.class_outlined,
                        title: 'Select Course',
                        value: 'No courses assigned to you.',
                        iconColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.all(16),
                        iconSize: 20,
                        titleFontSize: 12,
                        valueFontSize: 14,
                      )
                    else
                      DropdownButtonFormField<Course>(
                        initialValue: _selectedCourse,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Choose a course',
                        ),
                        items: teacherCourses.map((course) {
                          return DropdownMenuItem(
                            value: course,
                            child: Text(
                              '${course.code} - ${course.name}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (course) async {
                          if (course != null) {
                            setState(() {
                              _selectedCourse = course;
                            });
                            // Load quizzes for this specific course
                            await ref
                                .read(quizProvider.notifier)
                                .loadQuizzesForCourse(course.courseId);
                            // Trigger data load for the selected course
                            ref
                                .read(analyticsProvider.notifier)
                                .getCourseStatistics(course.courseId);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Results Content
            Expanded(
              child: teacherCourses.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.class_outlined,
                      title: 'No Classes Assigned',
                      message: 'You don\'t have any classes assigned yet.',
                      subtitle:
                          'Contact your administrator to get courses assigned.',
                      showInfoCard: true,
                      infoCardText:
                          'If you recently received assignments, refresh to load them.',
                      action: ElevatedButton(
                        onPressed: () async {
                          final user = ref.read(authProvider).user;
                          final userRole = ref.read(currentUserRoleProvider);
                          if (user != null) {
                            await ref
                                .read(courseProvider.notifier)
                                .initializeCourses(
                                  user.userId,
                                  userRole: userRole,
                                );
                            if (mounted) {
                              setState(() {});
                            }
                          }
                        },
                        child: const Text('Refresh'),
                      ),
                    )
                  : _selectedCourse == null
                  ? EmptyStateWidget(
                      icon: Icons.analytics_outlined,
                      title: 'Select a Course',
                      message:
                          'Choose a course from the dropdown above to view results and analytics.',
                    )
                  : _buildCourseResults(_selectedCourse!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseResults(Course course) {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(course.courseId), // Force rebuild when course changes
      future: ref
          .read(analyticsProvider.notifier)
          .getCourseStatistics(course.courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text('Error loading course statistics'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final statistics = snapshot.data!;
        final allQuizzes = ref.read(quizProvider).allQuizzes;
        final quizzes = allQuizzes
            .where((q) => q.courseId == course.courseId)
            .toList();

        if (quizzes.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.quiz_outlined,
            title: 'No Quizzes Yet',
            message: 'Create quizzes for this course to see analytics',
          );
        }

        return ListView(
          children: [
            _buildCourseStatisticsCard(course, statistics),
            const SizedBox(height: 20),
            _buildQuizzesList(quizzes),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildCourseStatisticsCard(
    Course course,
    Map<String, dynamic> statistics,
  ) {
    final totalStudents = statistics['totalStudents'] as int;
    final totalQuizzes = statistics['totalQuizzes'] as int;
    final publishedQuizzes = statistics['publishedQuizzes'] as int;
    final averageScore = statistics['averageScore'] as double;
    final completionRate = statistics['completionRate'] as double;
    final activeStudents = statistics['activeStudents'] as int;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: Theme.of(context).colorScheme.primary,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      course.code,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people_outline,
                  label: 'Total Students',
                  value: totalStudents.toString(),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_outline,
                  label: 'Active Students',
                  value: activeStudents.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.quiz_outlined,
                  label: 'Quizzes',
                  value: '$publishedQuizzes/$totalQuizzes',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up,
                  label: 'Avg Score',
                  value: '${averageScore.round()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            icon: Icons.task_alt,
            label: 'Completion Rate',
            value: '${completionRate.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizzesList(List<Quiz> quizzes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiz Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...quizzes.map((quiz) => _buildQuizResultCard(quiz)),
      ],
    );
  }

  Widget _buildQuizResultCard(Quiz quiz) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref
          .read(analyticsProvider.notifier)
          .getQuizAnalytics(quiz.quizId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: const ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: CircularProgressIndicator(),
              title: Text('Loading...'),
            ),
          );
        }

        final analytics = snapshot.data!;
        final completedAttempts = analytics['completedAttempts'] as int;
        final averagePercentage = analytics['averagePercentage'] as double;
        final completionRate = analytics['completionRate'] as double;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: const Icon(Icons.quiz_outlined, color: Colors.blue),
            ),
            title: Text(
              quiz.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('$completedAttempts attempts'),
                Text('Avg Score: ${averagePercentage.round()}%'),
                Text('Completion: ${completionRate.toStringAsFixed(1)}%'),
                if (quiz.dueAt != null)
                  Text(
                    'Due: ${_formatDate(quiz.dueAt!)}',
                    style: TextStyle(color: quiz.isOverdue ? Colors.red : null),
                  ),
              ],
            ),
            onTap: () {
              // Navigate to quiz student results screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizStudentResultsScreen(
                    quiz: quiz,
                    course: _selectedCourse!,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else {
      return '${difference.inMinutes} minutes left';
    }
  }
}
