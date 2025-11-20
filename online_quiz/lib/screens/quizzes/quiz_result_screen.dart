import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz.dart';
import '../../models/course.dart';
import '../../models/attempt.dart';
import '../../models/question.dart';
import '../../models/attempt_answer.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/info_card.dart';
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildResultHeader(scoreColor, gradeText, percentage),
                  _buildQuizInfo(context, ref, totalQuestions),
                  _buildDetailedResults(context, ref, totalQuestions, totalPoints),
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
            '${percentage.round()}%',
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
            widget.quiz.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
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
    );
  }

  Widget _buildQuizInfo(BuildContext context, WidgetRef ref, int totalQuestions) {
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
                child: StatCard(
                  icon: Icons.check_circle,
                  title: 'Correct Answers',
                  value: '${_getCorrectAnswersCount(ref)}/$totalQuestions',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.timer,
                  title: 'Time Spent',
                  value: '${_getTimeSpentMinutes()} min',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoCardPresets.compact(
            icon: Icons.calendar_today,
            title: 'Completed On',
            value: _formatDateTime(widget.attempt.submittedAt!),
          ),
          const SizedBox(height: 8),
          InfoCardPresets.compact(
            icon: Icons.schedule,
            title: 'Time Limit',
            value: widget.quiz.timeLimitMinutes != null ? '${widget.quiz.timeLimitMinutes} minutes' : 'No time limit',
          ),
        ],
      ),
    );
  }



  Widget _buildDetailedResults(BuildContext context, WidgetRef ref, int totalQuestions, double totalPoints) {
    final correctAnswers = _getCorrectAnswersCount(ref);
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
                  '${accuracy.round()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildAnswerDetails(context),
        ],
      ),
    );
  }

  Widget _buildResultBar(BuildContext context, String label, int value, int total, Color color) {
    final progress = total > 0 ? value / total : 0.0;
    
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
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
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
      
      if (questionAnswers.isEmpty) continue;
      
      bool isQuestionCorrect = false;
      
      if (question.type == QuestionType.multiple) {
        // For multiple choice, check if all correct answers are selected and no incorrect ones
        final choices = quizState.questionChoices[question.questionId] ?? [];
        final correctChoices = choices.where((c) => c.isCorrect).toList();
        final selectedCorrectChoices = questionAnswers.where((a) => a.isCorrect == true).toList();
        final selectedIncorrectChoices = questionAnswers.where((a) => a.isCorrect == false).toList();
        
        isQuestionCorrect = selectedCorrectChoices.length == correctChoices.length && 
                           selectedIncorrectChoices.isEmpty;
      } else {
        // For single choice and text questions, check if any answer is correct
        isQuestionCorrect = questionAnswers.any((answer) => answer.isCorrect == true);
      }
      
      if (isQuestionCorrect) {
        correctQuestionsCount++;
      }
    }
    
    return correctQuestionsCount;
  }

  int _getTimeSpentMinutes() {
    if (widget.attempt.timeSpentSeconds == null) return 0;
    return (widget.attempt.timeSpentSeconds! / 60).round();
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAnswerDetails(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final questions = quizState.selectedQuizQuestions;
    final attemptAnswers = quizState.attemptAnswers[widget.attempt.attemptId] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Answers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          final questionAnswers = attemptAnswers.where(
            (answer) => answer.questionId == question.questionId,
          ).toList();
          
          // Determine if the question is correct overall
          bool isQuestionCorrect = questionAnswers.isNotEmpty && 
              questionAnswers.any((answer) => answer.isCorrect == true);
          
          // For multiple choice questions, check if all correct answers are selected
          if (question.type == QuestionType.multiple) {
            final choices = quizState.questionChoices[question.questionId] ?? [];
            final correctChoices = choices.where((c) => c.isCorrect).toList();
            final selectedCorrectChoices = questionAnswers.where((a) => a.isCorrect == true).toList();
            final selectedIncorrectChoices = questionAnswers.where((a) => a.isCorrect == false).toList();
            
            isQuestionCorrect = selectedCorrectChoices.length == correctChoices.length && 
                               selectedIncorrectChoices.isEmpty;
          }
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isQuestionCorrect
                  ? Colors.green.withValues(alpha: 0.05)
                  : Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isQuestionCorrect
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isQuestionCorrect
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: isQuestionCorrect
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Question ${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${question.points} pts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                const SizedBox(height: 8),
                Text(
                  'Your answer: ${_formatUserAnswer(ref, question, questionAnswers)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isQuestionCorrect
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
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