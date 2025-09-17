import 'package:flutter/material.dart';
import '../../models/quiz.dart';
import '../../models/course.dart';
import '../../models/attempt.dart';
import '../../data/mock_data.dart';
import '../../widgets/info_card.dart';
import '../../utils/app_theme.dart';

class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final Course? course;
  final Attempt attempt;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    this.course,
    required this.attempt,
  });

  @override
  Widget build(BuildContext context) {
    final questions = MockData.getQuestionsByQuiz(quiz.quizId);
    final totalQuestions = questions.length;
    final totalPoints = questions.fold<double>(0.0, (sum, q) => sum + q.points);
    final percentage = totalPoints > 0 ? (attempt.score / totalPoints) * 100 : 0.0;
    
    Color scoreColor;
    String gradeText;
    if (percentage >= 90) {
      scoreColor = Colors.green;
      gradeText = 'Excellent';
    } else if (percentage >= 75) {
      scoreColor = Colors.blue;
      gradeText = 'Good';
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
      gradeText = 'Fair';
    } else {
      scoreColor = Colors.red;
      gradeText = 'Poor';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quiz Results',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildResultHeader(scoreColor, gradeText, percentage),
            _buildQuizInfo(context, totalQuestions),
            _buildDetailedResults(context, totalQuestions, totalPoints),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader(Color scoreColor, String gradeText, double percentage) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.8),
            scoreColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.grade,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            gradeText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            quiz.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (course != null)
            Text(
              '${course!.code} - ${course!.name}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildQuizInfo(BuildContext context, int totalQuestions) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Quiz Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Correct Answers',
                  '${_getCorrectAnswersCount()}/$totalQuestions',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Time Spent',
                  '${_getTimeSpentMinutes()} min',
                  Icons.timer,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoCardPresets.compact(
            icon: Icons.calendar_today,
            title: 'Completed On',
            value: _formatDateTime(attempt.submittedAt!),
          ),
          const SizedBox(height: 8),
          InfoCardPresets.compact(
            icon: Icons.schedule,
            title: 'Time Limit',
            value: quiz.timeLimitMinutes != null ? '${quiz.timeLimitMinutes} minutes' : 'No time limit',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedResults(BuildContext context, int totalQuestions, double totalPoints) {
    final correctAnswers = _getCorrectAnswersCount();
    final incorrectAnswers = totalQuestions - correctAnswers;
    final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Detailed Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildResultBar(context, 'Correct', correctAnswers, totalQuestions, Colors.green),
          const SizedBox(height: 12),
          _buildResultBar(context, 'Incorrect', incorrectAnswers, totalQuestions, Colors.red),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Accuracy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                Text(
                  '${accuracy.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBar(BuildContext context, String label, int value, int total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '$value/$total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value / total,
          backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }





  int _getCorrectAnswersCount() {
    final attemptAnswers = MockData.getAnswersByAttempt(attempt.attemptId);
    return attemptAnswers.where((answer) => answer.isCorrect == true).length;
  }

  int _getTimeSpentMinutes() {
    if (attempt.timeSpentSeconds == null) return 0;
    return (attempt.timeSpentSeconds! / 60).round();
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}