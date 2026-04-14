import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz.dart';
import '../../models/course.dart';
import '../../models/attempt.dart';
import '../../models/question.dart';
import '../../models/attempt_answer.dart';
import '../../utils/app_theme.dart';
import '../../providers/quiz_provider.dart';

class QuizResultScreen extends ConsumerStatefulWidget {
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
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // Load quiz details and attempt details when screen opens
    Future.microtask(() async {
      await ref.read(quizProvider.notifier).loadQuizDetails(widget.quiz.quizId);
      await ref.read(quizProvider.notifier).getAttemptDetails(widget.attempt.attemptId);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final questions = quizState.selectedQuizQuestions;
    final totalQuestions = questions.length;
    final totalPoints = questions.fold<double>(0.0, (sum, q) => sum + q.points);
    final percentage = totalPoints > 0 ? (widget.attempt.score / totalPoints) * 100 : 0.0;
    
    Color scoreColor;
    String gradeText;
    IconData gradeIcon;
    
    if (percentage >= 90) {
      scoreColor = Colors.green;
      gradeText = 'Excellent';
      gradeIcon = Icons.emoji_events;
    } else if (percentage >= 75) {
      scoreColor = Colors.blue;
      gradeText = 'Good';
      gradeIcon = Icons.thumb_up;
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
      gradeText = 'Fair';
      gradeIcon = Icons.sentiment_satisfied;
    } else {
      scoreColor = Colors.red;
      gradeText = 'Needs Improvement';
      gradeIcon = Icons.sentiment_dissatisfied;
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildResultHeader(context, scoreColor, gradeText, gradeIcon, percentage),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildQuizTitleCard(context),
                        const SizedBox(height: 16),
                        _buildScoreStats(context, ref, totalQuestions),
                        const SizedBox(height: 16),
                        _buildQuizInfo(context),
                        const SizedBox(height: 16),
                        _buildAnswerDetails(context, ref),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildResultHeader(BuildContext context, Color scoreColor, String gradeText, IconData gradeIcon, double percentage) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Gradient Background
        Container(
          height: 340,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scoreColor, scoreColor.withValues(alpha: 0.7)],
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
                gradeIcon,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                '${percentage.round()}%',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                gradeText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizTitleCard(BuildContext context) {
    return _buildInfoCard(
      context,
      title: widget.quiz.title,
      icon: Icons.quiz,
      children: [
        if (widget.course != null)
          _buildInfoRow(
            context,
            'Course',
            '${widget.course!.code} - ${widget.course!.name}',
          ),
      ],
    );
  }

  Widget _buildScoreStats(BuildContext context, WidgetRef ref, int totalQuestions) {
    final correctAnswers = _getCorrectAnswersCount(ref);
    final incorrectAnswers = totalQuestions - correctAnswers;
    final timeSpent = _getTimeSpentMinutes();
    final totalPoints = _getTotalPoints();
    
    // Format score - show decimals only if needed
    final scoreStr = widget.attempt.score % 1 == 0 
        ? widget.attempt.score.toInt().toString()
        : widget.attempt.score.toStringAsFixed(1);
    final totalPointsStr = totalPoints % 1 == 0 
        ? totalPoints.toInt().toString()
        : totalPoints.toStringAsFixed(1);

    return _buildInfoCard(
      context,
      title: 'Score Summary',
      icon: Icons.assessment,
      children: [
        _buildInfoRow(
          context,
          'Score',
          '$scoreStr/$totalPointsStr points',
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Correct Answers',
          '$correctAnswers/$totalQuestions',
          valueColor: Colors.green,
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Incorrect Answers',
          '$incorrectAnswers/$totalQuestions',
          valueColor: Colors.red,
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Time Spent',
          _formatTimeSpent(timeSpent),
        ),
      ],
    );
  }

  Widget _buildQuizInfo(BuildContext context) {
    return _buildInfoCard(
      context,
      title: 'Quiz Information',
      icon: Icons.info_outline,
      children: [
        _buildInfoRow(
          context,
          'Completed On',
          _formatDateTime(widget.attempt.submittedAt!),
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Time Limit',
          widget.quiz.timeLimitMinutes != null 
              ? '${widget.quiz.timeLimitMinutes} minutes' 
              : 'No time limit',
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Date Added',
          _formatDateTime(widget.quiz.createdAt),
        ),
      ],
    );
  }

  Widget _buildAnswerDetails(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizProvider);
    final questions = quizState.selectedQuizQuestions;
    final attemptAnswers = quizState.attemptAnswers[widget.attempt.attemptId] ?? [];
    
    return _buildInfoCard(
      context,
      title: 'Answer Review',
      icon: Icons.assignment,
      children: [
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          final questionAnswers = attemptAnswers.where(
            (answer) => answer.questionId == question.questionId,
          ).toList();
          
          // Determine if the question is correct overall
          bool isQuestionCorrect = _isQuestionCorrect(ref, question, questionAnswers);
          
          return Column(
            children: [
              if (index > 0) _buildDivider(context),
              _buildAnswerItem(context, ref, question, questionAnswers, index, isQuestionCorrect),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAnswerItem(
    BuildContext context,
    WidgetRef ref,
    Question question,
    List<AttemptAnswer> answers,
    int index,
    bool isCorrect,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCorrect 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${question.points} pts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.body,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatUserAnswer(ref, question, answers),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor}) {
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

  bool _isQuestionCorrect(WidgetRef ref, Question question, List<AttemptAnswer> questionAnswers) {
    if (questionAnswers.isEmpty) return false;
    
    final quizState = ref.watch(quizProvider);
    
    if (question.type == QuestionType.multiple) {
      final choices = quizState.questionChoices[question.questionId] ?? [];
      final correctChoices = choices.where((c) => c.isCorrect).toList();
      final selectedCorrectChoices = questionAnswers.where((a) => a.isCorrect == true).toList();
      final selectedIncorrectChoices = questionAnswers.where((a) => a.isCorrect == false).toList();
      
      return selectedCorrectChoices.length == correctChoices.length && 
             selectedIncorrectChoices.isEmpty;
    } else {
      return questionAnswers.any((answer) => answer.isCorrect == true);
    }
  }

  int _getCorrectAnswersCount(WidgetRef ref) {
    final quizState = ref.watch(quizProvider);
    final questions = quizState.selectedQuizQuestions;
    final attemptAnswers = quizState.attemptAnswers[widget.attempt.attemptId] ?? [];
    
    int correctQuestionsCount = 0;
    
    for (final question in questions) {
      final questionAnswers = attemptAnswers.where(
        (answer) => answer.questionId == question.questionId,
      ).toList();
      
      if (_isQuestionCorrect(ref, question, questionAnswers)) {
        correctQuestionsCount++;
      }
    }
    
    return correctQuestionsCount;
  }

  double _getTotalPoints() {
    final quizState = ref.watch(quizProvider);
    final questions = quizState.selectedQuizQuestions;
    return questions.fold<double>(0.0, (sum, q) => sum + q.points);
  }

  int _getTimeSpentMinutes() {
    if (widget.attempt.timeSpentSeconds == null) return 0;
    return (widget.attempt.timeSpentSeconds! / 60).round();
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

  String _formatUserAnswer(WidgetRef ref, Question question, List<AttemptAnswer> answers) {
    if (answers.isEmpty) {
      return "Not answered";
    }

    final quizState = ref.watch(quizProvider);

    switch (question.type) {
      case QuestionType.single:
        final answer = answers.first;
        if (answer.choiceId != null) {
          final choices = quizState.questionChoices[question.questionId] ?? [];
          final choice = choices.firstWhere((c) => c.choiceId == answer.choiceId);
          return choice.body;
        }
        return "Not answered";

      case QuestionType.multiple:
        final choices = quizState.questionChoices[question.questionId] ?? [];
        final selectedChoices = answers
            .where((a) => a.choiceId != null)
            .map((a) => choices.firstWhere((c) => c.choiceId == a.choiceId!).body)
            .toList();
        return selectedChoices.isEmpty ? "Not answered" : selectedChoices.join(", ");

      case QuestionType.text:
        final answer = answers.first;
        return answer.freeText?.isNotEmpty == true ? answer.freeText! : "Not answered";
    }
  }
}
