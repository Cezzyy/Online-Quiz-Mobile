import 'package:flutter/material.dart';
import '../../models/quiz.dart';
import '../../models/course.dart';
import '../../models/attempt.dart';
import '../../data/mock_data.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/info_card.dart';
import '../../widgets/dialog.dart';
import '../../utils/app_theme.dart';

class QuizDetailScreen extends StatelessWidget {
  final Quiz quiz;
  final Course? course;
  final int currentUserId;

  const QuizDetailScreen({
    super.key,
    required this.quiz,
    this.course,
    this.currentUserId = 4, // Default to student user
  });

  @override
  Widget build(BuildContext context) {
    final attempt = MockData.getAttemptsByQuiz(quiz.quizId)
        .where((a) => a.userId == currentUserId && a.submittedAt != null)
        .cast<Attempt?>()
        .firstOrNull;
    final isCompleted = attempt != null;
    final isOverdue = !isCompleted && quiz.isOverdue;
    final daysUntilDue = quiz.daysUntilDue;
    
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
          'Quiz Details',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildQuizHeader(context, isCompleted, isOverdue, daysUntilDue),
            _buildQuizInfo(context),
            _buildQuizStats(context),
            if (isCompleted) _buildResultSection(context, attempt),
            _buildInstructions(context, isCompleted),
            const SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: _buildActionButton(context, isCompleted, isOverdue),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildQuizHeader(BuildContext context, bool isCompleted, bool isOverdue, int daysUntilDue) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (isCompleted) {
      statusColor = Colors.green;
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'Overdue';
      statusIcon = Icons.error;
    } else {
      statusColor = Colors.orange;
      statusText = daysUntilDue == 0 ? 'Due Today' : 'Due in $daysUntilDue ${daysUntilDue == 1 ? 'day' : 'days'}';
      statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.8),
            statusColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: AppTheme.getCardColor(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (course != null)
                      Text(
                        '${course!.code} - ${course!.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInfo(BuildContext context) {
    final questions = MockData.getQuestionsByQuiz(quiz.quizId);
    final instructor = course != null ? MockData.getUserById(course!.instructorUserId) : null;
    
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
            'Quiz Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          InfoCardPresets.compact(
            icon: Icons.help_outline,
            title: 'Questions',
            value: '${questions.length} questions',
          ),
          const SizedBox(height: 12),
          InfoCardPresets.compact(
            icon: Icons.timer_outlined,
            title: 'Time Limit',
            value: quiz.hasTimeLimit ? '${quiz.timeLimitMinutes} minutes' : 'No limit',
          ),
          const SizedBox(height: 12),
          InfoCardPresets.compact(
            icon: Icons.calendar_today_outlined,
            title: 'Due Date',
            value: quiz.hasDueDate ? _formatDateTime(quiz.dueAt!) : 'No due date',
          ),
          const SizedBox(height: 12),
          InfoCardPresets.compact(
            icon: Icons.add_circle_outline,
            title: 'Date Added',
            value: _formatDateTime(quiz.createdAt),
          ),
          if (instructor != null) ...[
            const SizedBox(height: 12),
            InfoCardPresets.compact(
              icon: Icons.person_outline,
              title: 'Instructor',
              value: instructor.fullName,
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildQuizStats(BuildContext context) {
    final questions = MockData.getQuestionsByQuiz(quiz.quizId);
    final attempt = MockData.getAttemptsByQuiz(quiz.quizId)
        .where((a) => a.userId == currentUserId && a.submittedAt != null)
        .cast<Attempt?>()
        .firstOrNull;
    final isCompleted = attempt != null;
    
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
            'Quiz Statistics',
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
                child: StatCard(
                  icon: Icons.help_outline,
                  title: 'Questions',
                  value: questions.length.toString(),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.timer_outlined,
                  title: 'Time Limit',
                  value: quiz.hasTimeLimit ? '${quiz.timeLimitMinutes}m' : 'None',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: isCompleted ? Icons.check_circle : Icons.schedule,
                  title: 'Status',
                  value: isCompleted ? 'Done' : 'Pending',
                  color: isCompleted ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildResultSection(BuildContext context, Attempt attempt) {
    final questions = MockData.getQuestionsByQuiz(quiz.quizId);
    final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points.toInt());
    final percentage = totalPoints > 0 ? (attempt.score / totalPoints) * 100 : 0.0;
    
    Color scoreColor;
    if (percentage >= 90) {
      scoreColor = Colors.green;
    } else if (percentage >= 75) {
      scoreColor = Colors.blue;
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

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
          Row(
            children: [
              Icon(
                Icons.grade,
                color: scoreColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Result',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Score Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scoreColor.withValues(alpha: 0.1),
                  scoreColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        '${attempt.score.toInt()}/${totalPoints.toInt()} Points',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: AppTheme.getDividerColor(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${attempt.timeSpentMinutes}m',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      Text(
                        'Time Spent',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Text(
            'Completed on ${_formatDateTime(attempt.submittedAt!)}',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(BuildContext context, bool isCompleted) {
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
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionItem(context, 'Read each question carefully before answering'),
          _buildInstructionItem(context, quiz.hasTimeLimit ? 'You have ${quiz.timeLimitMinutes} minutes to complete the quiz' : 'No time limit for this quiz'),
          _buildInstructionItem(context, 'Make sure you have a stable internet connection'),
          _buildInstructionItem(context, 'Once submitted, you cannot change your answers'),
          if (!isCompleted)
            _buildInstructionItem(context, 'Click "Start Quiz" when you\'re ready to begin'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isCompleted, bool isOverdue) {
    if (isCompleted) {
      return const SizedBox.shrink(); // Hide the button when quiz is completed
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: isOverdue ? null : () {
          _showStartQuizDialog(context);
        },
        icon: Icon(
          isOverdue ? Icons.error : Icons.play_arrow,
          color: Colors.white,
        ),
        label: Text(
          isOverdue ? 'Quiz Overdue' : 'Start Quiz',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOverdue ? Colors.grey : Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  void _showStartQuizDialog(BuildContext context) {
    final questions = MockData.getQuestionsByQuiz(quiz.quizId);
    
    AppDialog.show(
      context: context,
      title: 'Start Quiz',
      subtitle: 'Are you ready to start "${quiz.title}"?',
      type: DialogType.confirmation,
      icon: Icons.quiz_outlined,
      iconColor: Colors.blue,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuizInfoRow(
             Icons.access_time,
             'Time Limit',
             '${quiz.timeLimitMinutes ?? 'No limit'} minutes',
             Colors.orange,
           ),
          const SizedBox(height: 12),
          _buildQuizInfoRow(
            Icons.quiz,
            'Questions',
            '${questions.length}',
            Colors.blue,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Important Notice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Once you start, the timer will begin and you cannot pause the quiz.',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        DialogAction.cancel(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogAction(
          text: 'Start Quiz',
          icon: Icons.play_arrow,
          color: Colors.green,
          flex: 2,
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Starting ${quiz.title}...'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuizInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}