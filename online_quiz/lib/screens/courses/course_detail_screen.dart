import 'package:flutter/material.dart';
import '../../data/new_mock_data.dart';
import '../../models/new_course.dart';
import '../../models/new_quiz.dart';
import '../../models/new_teacher.dart';
import '../../models/new_user.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;
  
  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final courseQuizzes = NewMockData.quizzes.where((q) => q.courseId == course.courseId).toList();
    final completedQuizzes = courseQuizzes.where((quiz) => 
      NewMockData.attempts.any((a) => a.quizId == quiz.quizId && a.submittedAt != null)
    ).length;
    final totalQuizzes = courseQuizzes.length;
    final progress = totalQuizzes > 0 ? completedQuizzes / totalQuizzes : 0.0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          course.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _getCourseColor(course.code),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Course Header
            _buildCourseHeader(progress, completedQuizzes, totalQuizzes),
            
            // Quizzes List
            _buildQuizzesList(courseQuizzes),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCourseHeader(double progress, int completedQuizzes, int totalQuizzes) {
    final teacher = NewMockData.teachers.firstWhere(
      (t) => t.userId == course.instructorUserId,
      orElse: () => Teacher(
        userId: 0,
        department: 'Unknown Department',
      ),
    );
    final teacherUser = NewMockData.users.firstWhere(
      (u) => u.userId == teacher.userId,
      orElse: () => User(
        userId: 0,
        fullName: 'Unknown Teacher',
        email: '',
        passwordHash: '',
        status: 'Active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _getCourseColor(course.code),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.code,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                'Instructor: ${teacherUser.fullName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Course ID: ${course.courseId}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            
            // Progress Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Course Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completedQuizzes of $totalQuizzes quizzes completed',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuizzesList(List<Quiz> courseQuizzes) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Quizzes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courseQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = courseQuizzes[index];
              return _buildQuizCard(context, quiz);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuizCard(BuildContext context, Quiz quiz) {
    final attempt = NewMockData.attempts.where((a) => a.quizId == quiz.quizId).firstOrNull;
    final isCompleted = attempt?.submittedAt != null;
    final quizQuestions = NewMockData.questions.where((q) => q.quizId == quiz.quizId).toList();
    final totalQuestions = quizQuestions.length;
    final totalPossiblePoints = quizQuestions.fold(0.0, (sum, question) => sum + question.points);
    final score = attempt != null && attempt.submittedAt != null && totalPossiblePoints > 0
        ? (attempt.score / totalPossiblePoints * 100)
        : 0.0;
    
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to quiz screens when they support new models
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCompleted ? 'Quiz completed with ${score.toStringAsFixed(1)}% score' : 'Quiz: ${quiz.title}'),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiz Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.schedule,
                  color: isCompleted ? Colors.green : Colors.orange,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted ? 'Completed' : 'Not Started',
                      style: TextStyle(
                        fontSize: 14,
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${score.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(score),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Quiz Details
          Row(
            children: [
              Expanded(
                child: _buildQuizDetail(
                  icon: Icons.quiz_outlined,
                  label: 'Questions',
                  value: totalQuestions.toString(),
                ),
              ),
              Expanded(
                child: _buildQuizDetail(
                  icon: Icons.timer_outlined,
                  label: 'Time Limit',
                  value: quiz.timeLimitMinutes != null ? '${quiz.timeLimitMinutes} min' : 'No limit',
                ),
              ),
            ],
          ),
          
          ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  quiz.dueAt != null
                      ? 'Due: ${_formatDate(quiz.dueAt!)}'
                      : 'No due date',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Added: ${_formatDate(quiz.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
          
          if (isCompleted && attempt != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Completed on ${_formatDate(attempt.submittedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Text(
                    'Time: ${attempt.timeSpentMinutes} min',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
  
  Widget _buildQuizDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Color _getCourseColor(String courseCode) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[courseCode.hashCode % colors.length];
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}