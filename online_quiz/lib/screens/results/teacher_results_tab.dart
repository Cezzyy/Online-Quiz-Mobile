import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';
import '../../data/mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../quizzes/quiz_result_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(courseProvider.notifier).initializeCourses(user.userId);
        ref.read(quizProvider.notifier).initializeQuizzes(user.userId);
      }
    });
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(courseProvider.notifier).initializeCourses(authState.user!.userId);
                  ref.read(quizProvider.notifier).initializeQuizzes(authState.user!.userId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final teacherCourses = _getTeacherCourses(authState.user!.userId);
    final filteredResults = _getFilteredResults(teacherCourses);

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
                      const Text('No courses assigned to you.')
                    else
                      DropdownButtonFormField<Course>(
                    initialValue: _selectedCourse,
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
                        onChanged: (course) {
                          if (course != null) {
                            setState(() {
                              _selectedCourse = course;
                            });
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
              child: _selectedCourse == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select a course to view results',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : filteredResults.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.analytics_outlined,
                          title: 'No Results Available',
                          message: 'No quiz results found for this course',
                        )
                      : ListView(
                          children: [
                            // Show detailed results for selected course
                            ..._buildDetailedCourseResults(_selectedCourse!.courseId),
                            const SizedBox(height: 20),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Course> _getTeacherCourses(int teacherId) {
    return MockData.getCoursesByInstructor(teacherId);
  }



  List<dynamic> _getFilteredResults(List<Course> courses) {
    if (_selectedCourse == null) {
      return [];
    } else {
      final quizzes = MockData.getQuizzesByCourse(_selectedCourse!.courseId);
      return quizzes;
    }
  }

  List<Widget> _buildDetailedCourseResults(int courseId) {
    final quizzes = MockData.getQuizzesByCourse(courseId);
    final enrollments = MockData.getEnrollmentsByCourse(courseId);

    List<Widget> widgets = [];

    // Course header
    widgets.add(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                  child: Text(
                    '${enrollments.length} students enrolled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    widgets.add(const SizedBox(height: 20));

    // Quiz results
    if (quizzes.isEmpty) {
      widgets.add(
        EmptyStateWidget(
          icon: Icons.quiz_outlined,
          title: 'No Quizzes',
          message: 'No quizzes have been created for this course yet.',
        ),
      );
    } else {
      widgets.add(
        Text(
          'Quiz Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));

      for (final quiz in quizzes) {
        widgets.add(_buildQuizResultCard(quiz));
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }

  Widget _buildQuizResultCard(Quiz quiz) {
    final attempts = MockData.getAttemptsByQuiz(quiz.quizId)
        .where((a) => a.submittedAt != null)
        .toList();
    
    final questions = MockData.getQuestionsByQuiz(quiz.quizId);
    final totalPoints = questions.fold<double>(0.0, (sum, q) => sum + q.points);
    
    // Get all enrolled students for this course to calculate completion rate
    final course = MockData.getCourseById(quiz.courseId)!;
    final enrollments = MockData.getEnrollmentsByCourse(course.courseId);
    final totalStudents = enrollments.length;
    final completionRate = totalStudents > 0 ? (attempts.length / totalStudents) * 100 : 0.0;
    
    double averageScore = 0.0;
    double averagePercentage = 0.0;
    
    if (attempts.isNotEmpty) {
      averageScore = attempts.fold<double>(0, (sum, a) => sum + a.score) / attempts.length;
      averagePercentage = totalPoints > 0 ? (averageScore / totalPoints) * 100 : 0.0;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Icon(
            Icons.quiz_outlined,
            color: Colors.blue,
          ),
        ),
        title: Text(
          quiz.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${attempts.length} attempts'),
            Text('Avg Score: ${averagePercentage.toStringAsFixed(1)}%'),
            Text('Completion: ${completionRate.toStringAsFixed(1)}%'),
            if (quiz.dueAt != null)
              Text(
                'Due: ${_formatDate(quiz.dueAt!)}',
                style: TextStyle(
                  color: quiz.isOverdue ? Colors.red : null,
                ),
              ),
          ],
        ),
        onTap: () {
          // Navigate to detailed quiz results
          if (attempts.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizResultScreen(
                  quiz: quiz,
                  attempt: attempts.last,
                ),
              ),
            );
          }
        },
      ),
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