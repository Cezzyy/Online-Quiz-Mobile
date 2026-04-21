import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attempt.dart';
import '../../models/attempt_answer.dart';
import '../../models/question.dart';
import '../../models/quiz.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';

class ManualGradingScreen extends ConsumerStatefulWidget {
  final Quiz quiz;
  final Attempt attempt;
  final Map<String, dynamic> userData;

  const ManualGradingScreen({
    super.key,
    required this.quiz,
    required this.attempt,
    required this.userData,
  });

  @override
  ConsumerState<ManualGradingScreen> createState() => _ManualGradingScreenState();
}

class _ManualGradingScreenState extends ConsumerState<ManualGradingScreen> {
  final QuizService _quizService = QuizService();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _textQuestions = [];
  final Map<int, TextEditingController> _pointsControllers = {};
  final Map<int, TextEditingController> _feedbackControllers = {};

  @override
  void initState() {
    super.initState();
    _loadTextQuestions();
  }

  @override
  void dispose() {
    for (final controller in _pointsControllers.values) {
      controller.dispose();
    }
    for (final controller in _feedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTextQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all questions for the quiz
      final questions = await _quizService.getQuizQuestions(widget.quiz.quizId);
      
      // Get all answers for this attempt
      final answers = await _quizService.getAttemptAnswers(widget.attempt.attemptId);

      // Filter for text questions only
      final textQuestions = <Map<String, dynamic>>[];
      for (final question in questions) {
        if (question.type == QuestionType.text) {
          final answer = answers.firstWhere(
            (a) => a.questionId == question.questionId,
            orElse: () => AttemptAnswer(
              attemptAnswerId: -1,
              attemptId: widget.attempt.attemptId,
              questionId: question.questionId,
            ),
          );

          textQuestions.add({
            'question': question,
            'answer': answer,
          });

          // Initialize controllers
          _pointsControllers[answer.attemptAnswerId] = TextEditingController(
            text: answer.pointsAwarded?.toStringAsFixed(1) ?? '',
          );
          _feedbackControllers[answer.attemptAnswerId] = TextEditingController(
            text: answer.feedback ?? '',
          );
        }
      }

      if (mounted) {
        setState(() {
          _textQuestions = textQuestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading questions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveGrades() async {
    setState(() {
      _isSaving = true;
    });

    try {
      for (final questionData in _textQuestions) {
        final answer = questionData['answer'] as AttemptAnswer;
        final question = questionData['question'] as Question;
        
        if (answer.attemptAnswerId == -1) continue; // Skip if no answer

        final pointsText = _pointsControllers[answer.attemptAnswerId]?.text ?? '';
        final feedback = _feedbackControllers[answer.attemptAnswerId]?.text ?? '';

        if (pointsText.isEmpty) {
          throw Exception('Please enter points for all questions');
        }

        final pointsAwarded = double.tryParse(pointsText);
        if (pointsAwarded == null) {
          throw Exception('Invalid points value');
        }

        if (pointsAwarded < 0 || pointsAwarded > question.points) {
          throw Exception('Points must be between 0 and ${question.points}');
        }

        await _quizService.gradeTextAnswer(
          attemptAnswerId: answer.attemptAnswerId,
          pointsAwarded: pointsAwarded,
          feedback: feedback.isNotEmpty ? feedback : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grades saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate grading was completed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving grades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.userData['user'] as Map<String, dynamic>;
    final student = widget.userData['student'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manual Grading',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Student Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              user['FullName'].toString()[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['FullName'] as String,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ID: ${student['StudentId']} • Section: ${student['Section'] ?? 'N/A'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quiz',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.quiz.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Submitted',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(widget.attempt.submittedAt!),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Questions List
                Expanded(
                  child: _textQuestions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Text Questions',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This quiz has no text questions to grade.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _textQuestions.length,
                          itemBuilder: (context, index) {
                            final questionData = _textQuestions[index];
                            final question = questionData['question'] as Question;
                            final answer = questionData['answer'] as AttemptAnswer;
                            
                            return _buildQuestionCard(
                              question,
                              answer,
                              index + 1,
                            );
                          },
                        ),
                ),

                // Save Button
                if (_textQuestions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveGrades,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Grades',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildQuestionCard(Question question, AttemptAnswer answer, int number) {
    final theme = Theme.of(context);
    final isGraded = answer.isGraded;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q$number',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.body,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${question.points} pts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Student Answer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Answer:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    answer.freeText ?? 'No answer provided',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Grading Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _pointsControllers[answer.attemptAnswerId],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Points Awarded',
                      hintText: '0.0 - ${question.points}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _feedbackControllers[answer.attemptAnswerId],
                    decoration: InputDecoration(
                      labelText: 'Feedback (Optional)',
                      hintText: 'Add feedback for student',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),

            if (isGraded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Previously graded: ${answer.pointsAwarded?.toStringAsFixed(1)} pts',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
