import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz.dart';
import '../../models/course.dart';
import '../../models/attempt.dart';
import '../../models/user.dart';
import '../../widgets/dialog.dart';
import '../../utils/app_theme.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/course_provider.dart';
import 'quiz_screen.dart';

class QuizDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends ConsumerState<QuizDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload quiz data when returning to this screen
    _loadQuizData();
  }

  void _loadQuizData() {
    // Load quiz details when screen opens
    Future.microtask(() {
      ref.read(quizProvider.notifier).loadQuizDetails(widget.quiz.quizId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get quiz data from provider
    final quizState = ref.watch(quizProvider);
    final attempt = quizState.quizAttempts[widget.quiz.quizId];
    final isCompleted = attempt != null;
    final isOverdue = !isCompleted && widget.quiz.isOverdue;
    final daysUntilDue = widget.quiz.daysUntilDue;
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildQuizHeader(context, isCompleted, isOverdue, daysUntilDue),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildQuizInfo(context),
                  const SizedBox(height: 16),
                  if (isCompleted) _buildResultSection(context, attempt),
                  if (isCompleted) const SizedBox(height: 16),
                  _buildInstructions(context, isCompleted),
                  const SizedBox(height: 24),
                  _buildActionButton(context, ref, isCompleted, isOverdue),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizHeader(BuildContext context, bool isCompleted, bool isOverdue, int daysUntilDue) {
    Color statusColor;
    IconData statusIcon;
    
    if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Gradient Background
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [statusColor, statusColor.withValues(alpha: 0.7)],
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
        // Back Button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Content
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                statusIcon,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                widget.quiz.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (widget.course != null)
                Text(
                  '${widget.course!.code} - ${widget.course!.name}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizInfo(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final questions = quizState.selectedQuizQuestions;
    final attempt = quizState.quizAttempts[widget.quiz.quizId];
    final isCompleted = attempt != null;
    final isOverdue = !isCompleted && widget.quiz.isOverdue;
    
    // Determine status display
    String statusValue;
    Color statusColor;
    
    if (isCompleted) {
      statusValue = 'Completed';
      statusColor = Colors.green;
    } else if (isOverdue) {
      statusValue = 'Overdue';
      statusColor = Colors.red;
    } else {
      statusValue = 'Pending';
      statusColor = Colors.orange;
    }
    
    return _buildInfoCard(
      context,
      title: 'Quiz Information',
      icon: Icons.quiz,
      children: [
        _buildInfoRow(context, 'Questions', '${questions.length} questions'),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Time Limit',
          widget.quiz.hasTimeLimit ? '${widget.quiz.timeLimitMinutes} minutes' : 'No limit',
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Due Date',
          widget.quiz.hasDueDate ? _formatDateTime(widget.quiz.dueAt!) : 'No due date',
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Date Added',
          _formatDateTime(widget.quiz.createdAt),
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Status',
          statusValue,
          valueColor: statusColor,
        ),
        if (widget.course != null)
          FutureBuilder<User?>(
            future: ref.read(courseProvider.notifier).getCourseInstructor(widget.course!.courseId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Column(
                  children: [
                    _buildDivider(context),
                    _buildInfoRow(
                      context,
                      'Instructor',
                      snapshot.data!.fullName,
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }





  Widget _buildResultSection(BuildContext context, Attempt attempt) {
    final quizState = ref.watch(quizProvider);
    final questions = quizState.selectedQuizQuestions;
    final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points.toInt());
    final percentage = totalPoints > 0 ? (attempt.score / totalPoints) * 100 : 0.0;
    
    Color scoreColor;
    String performanceLabel;
    if (percentage >= 90) {
      scoreColor = Colors.green;
      performanceLabel = 'Excellent';
    } else if (percentage >= 75) {
      scoreColor = Colors.blue;
      performanceLabel = 'Good';
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
      performanceLabel = 'Fair';
    } else {
      scoreColor = Colors.red;
      performanceLabel = 'Needs Improvement';
    }

    return _buildInfoCard(
      context,
      title: 'Your Result',
      icon: Icons.grade,
      children: [
        _buildInfoRow(
          context,
          'Score',
          '${attempt.score.toInt()}/${totalPoints.toInt()} Points',
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Percentage',
          '${percentage.toStringAsFixed(1)}%',
          valueColor: scoreColor,
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Performance',
          performanceLabel,
          valueColor: scoreColor,
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Time Spent',
          _formatTimeSpent(attempt.timeSpentMinutes),
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Completed On',
          _formatDateTime(attempt.submittedAt!),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context, bool isCompleted) {
    return _buildInfoCard(
      context,
      title: 'Instructions',
      icon: Icons.info_outline,
      children: [
        _buildInstructionItem(context, 'Read each question carefully before answering'),
        _buildInstructionItem(context, widget.quiz.hasTimeLimit ? 'You have ${widget.quiz.timeLimitMinutes} minutes to complete the quiz' : 'No time limit for this quiz'),
        _buildInstructionItem(context, 'Make sure you have a stable internet connection'),
        _buildInstructionItem(context, 'Once submitted, you cannot change your answers'),
        if (!isCompleted)
          _buildInstructionItem(context, 'Click "Start Quiz" when you\'re ready to begin'),
      ],
    );
  }

  Widget _buildInstructionItem(BuildContext context, String text) {
    final theme = Theme.of(context);
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
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, bool isCompleted, bool isOverdue) {
    if (isCompleted) {
      return const SizedBox.shrink(); // Hide the button when quiz is completed
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isOverdue ? null : () {
          _showStartQuizDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isOverdue ? Colors.grey : Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOverdue ? Icons.error : Icons.play_arrow,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isOverdue ? 'Quiz Overdue' : 'Start Quiz',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStartQuizDialog(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final questions = quizState.selectedQuizQuestions;
    
    AppDialog.show(
      context: context,
      title: 'Start Quiz',
      subtitle: 'Are you ready to start "${widget.quiz.title}"?',
      type: DialogType.confirmation,
      icon: Icons.quiz_outlined,
      iconColor: Colors.blue,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuizInfoRow(
             context,
             Icons.access_time,
             'Time Limit',
             '${widget.quiz.timeLimitMinutes ?? 'No limit'} minutes',
             Theme.of(context).colorScheme.primary,
           ),
          const SizedBox(height: 12),
          _buildQuizInfoRow(
            context,
            Icons.quiz,
            'Questions',
            '${questions.length}',
            Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Important Notice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Once you start, the timer will begin and you cannot pause the quiz.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => QuizScreen(
                  quiz: widget.quiz,
                  currentUserId: widget.currentUserId,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuizInfoRow(BuildContext context, IconData icon, String label, String value, Color color) {
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
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      height: 16,
    );
  }

  String _formatTimeSpent(int minutes) {
    if (minutes == 0) {
      return 'Less than 1 minute';
    } else if (minutes < 60) {
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes ${remainingMinutes == 1 ? 'minute' : 'minutes'}';
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}