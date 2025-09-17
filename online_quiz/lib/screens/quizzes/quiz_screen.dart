import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/quiz.dart';
import '../../models/question.dart';
import '../../models/attempt.dart';
import '../../models/attempt_answer.dart';
import '../../data/mock_data.dart';
import '../../utils/app_theme.dart';
import '../../widgets/dialog.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final int currentUserId;

  const QuizScreen({
    super.key,
    required this.quiz,
    this.currentUserId = 4,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late List<Question> questions;
  late PageController pageController;
  late AnimationController timerAnimationController;
  
  int currentQuestionIndex = 0;
  Map<int, dynamic> answers = {}; // questionId -> answer (choiceId, List<choiceId>, or String)
  DateTime? startTime;
  int timeRemainingSeconds = 0;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    questions = MockData.getQuestionsByQuiz(widget.quiz.quizId);
    pageController = PageController();
    startTime = DateTime.now();
    
    // Initialize timer
    if (widget.quiz.timeLimitMinutes != null) {
      timeRemainingSeconds = widget.quiz.timeLimitMinutes! * 60;
      timerAnimationController = AnimationController(
        duration: Duration(seconds: timeRemainingSeconds),
        vsync: this,
      );
      _startTimer();
    } else {
      timerAnimationController = AnimationController(vsync: this);
    }
  }

  void _startTimer() {
    timerAnimationController.addListener(() {
      setState(() {
        timeRemainingSeconds = ((1 - timerAnimationController.value) * 
            widget.quiz.timeLimitMinutes! * 60).round();
      });
      
      if (timeRemainingSeconds <= 0) {
        _autoSubmitQuiz();
      }
    });
    timerAnimationController.forward();
  }

  void _autoSubmitQuiz() {
    if (!isSubmitting) {
      _submitQuiz(autoSubmit: true);
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    timerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _showExitConfirmation();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildProgressIndicator(),
            _buildTimerSection(),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentQuestionIndex = index;
                  });
                },
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(questions[index], index);
                },
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          final navigator = Navigator.of(context);
          final shouldPop = await _showExitConfirmation();
          if (shouldPop && context.mounted) {
            navigator.pop();
          }
        },
      ),
      title: Text(
        widget.quiz.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showInstructions,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentQuestionIndex + 1} of ${questions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_getAnsweredCount()}/${questions.length} answered',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / questions.length,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    if (widget.quiz.timeLimitMinutes == null) return const SizedBox.shrink();

    final minutes = timeRemainingSeconds ~/ 60;
    final seconds = timeRemainingSeconds % 60;
    final isLowTime = timeRemainingSeconds <= 300; // 5 minutes

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLowTime ? Colors.red.shade50 : Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(
            color: isLowTime ? Colors.red.shade200 : Colors.blue.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            color: isLowTime ? Colors.red : Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Time Remaining: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: isLowTime ? Colors.red : Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionHeader(question),
              const SizedBox(height: 24),
              _buildQuestionBody(question),
              const SizedBox(height: 24),
              _buildAnswerSection(question),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(Question question) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getQuestionTypeColor(question.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getQuestionTypeColor(question.type).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            _getQuestionTypeLabel(question.type),
            style: TextStyle(
              color: _getQuestionTypeColor(question.type),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${question.points} ${question.points == 1 ? 'point' : 'points'}',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionBody(Question question) {
    return Text(
      question.body,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildAnswerSection(Question question) {
    switch (question.type) {
      case QuestionType.single:
        return _buildSingleChoiceAnswers(question);
      case QuestionType.multiple:
        return _buildMultipleChoiceAnswers(question);
      case QuestionType.text:
        return _buildTextAnswer(question);
    }
  }

  Widget _buildSingleChoiceAnswers(Question question) {
    final choices = MockData.getChoicesByQuestion(question.questionId);
    final selectedChoiceId = answers[question.questionId] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select one answer:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        ...choices.map((choice) {
          final isSelected = selectedChoiceId == choice.choiceId;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  answers[question.questionId] = choice.choiceId;
                });
                HapticFeedback.lightImpact();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected 
                      ? AppTheme.primaryColor.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
                          width: 2,
                        ),
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        choice.body,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMultipleChoiceAnswers(Question question) {
    final choices = MockData.getChoicesByQuestion(question.questionId);
    final selectedChoiceIds = (answers[question.questionId] as List<int>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select all correct answers:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        ...choices.map((choice) {
          final isSelected = selectedChoiceIds.contains(choice.choiceId);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  final currentAnswers = (answers[question.questionId] as List<int>?) ?? [];
                  if (isSelected) {
                    currentAnswers.remove(choice.choiceId);
                  } else {
                    currentAnswers.add(choice.choiceId);
                  }
                  answers[question.questionId] = currentAnswers;
                });
                HapticFeedback.lightImpact();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected 
                      ? AppTheme.primaryColor.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
                          width: 2,
                        ),
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        choice.body,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextAnswer(Question question) {
    final currentAnswer = answers[question.questionId] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type your answer:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: currentAnswer)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: currentAnswer.length),
            ),
          onChanged: (value) {
            answers[question.questionId] = value;
          },
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter your answer here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (currentQuestionIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: currentQuestionIndex == 0 ? 1 : 1,
            child: ElevatedButton.icon(
              onPressed: currentQuestionIndex < questions.length - 1
                  ? _nextQuestion
                  : _showSubmitConfirmation,
              icon: Icon(
                currentQuestionIndex < questions.length - 1
                    ? Icons.arrow_forward
                    : Icons.check,
              ),
              label: Text(
                currentQuestionIndex < questions.length - 1
                    ? 'Next'
                    : 'Submit Quiz',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentQuestionIndex < questions.length - 1
                    ? AppTheme.primaryColor
                    : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSubmitConfirmation() {
    final unansweredCount = questions.length - _getAnsweredCount();
    
    AppDialog.show(
      context: context,
      title: 'Submit Quiz',
      subtitle: unansweredCount > 0 
          ? 'You have $unansweredCount unanswered question${unansweredCount == 1 ? '' : 's'}.'
          : 'Are you sure you want to submit your quiz?',
      type: DialogType.confirmation,
      icon: Icons.send,
      iconColor: Colors.green,
      content: unansweredCount > 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Unanswered questions will be marked as incorrect.',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,
      actions: [
        DialogAction.cancel(
          text: 'Review',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogAction(
          text: 'Submit',
          icon: Icons.send,
          color: Colors.green,
          onPressed: () {
            Navigator.of(context).pop();
            _submitQuiz();
          },
        ),
      ],
    );
  }

  void _submitQuiz({bool autoSubmit = false}) {
    if (isSubmitting) return;
    
    setState(() {
      isSubmitting = true;
    });

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Submitting your quiz...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Calculate score and create attempt
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        navigator.pop(); // Close loading dialog
        
        // Calculate score and create attempt
        final attempt = _calculateScoreAndCreateAttempt(autoSubmit);
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              autoSubmit 
                  ? 'Quiz auto-submitted due to time limit'
                  : 'Quiz submitted successfully!',
            ),
            backgroundColor: autoSubmit ? Colors.orange : Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        // Navigate to quiz result screen
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: widget.quiz,
              course: MockData.getCourseById(widget.quiz.courseId),
              attempt: attempt,
            ),
          ),
        );
      }
    });
  }

  Future<bool> _showExitConfirmation() async {
    final result = await AppDialog.show<bool>(
      context: context,
      title: 'Exit Quiz',
      subtitle: 'Are you sure you want to exit? Your progress will be lost.',
      type: DialogType.confirmation,
      icon: Icons.exit_to_app,
      iconColor: Colors.red,
      actions: [
        DialogAction.cancel(
          text: 'Stay',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DialogAction(
          text: 'Exit',
          icon: Icons.exit_to_app,
          color: Colors.red,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    return result ?? false;
  }

  void _showInstructions() {
    AppDialog.show(
      context: context,
      title: 'Quiz Instructions',
      subtitle: 'How to take this quiz',
      type: DialogType.info,
      icon: Icons.help_outline,
      iconColor: Colors.blue,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInstructionItem('Navigate between questions using the Previous/Next buttons'),
          _buildInstructionItem('For single choice questions, select one answer'),
          _buildInstructionItem('For multiple choice questions, select all correct answers'),
          _buildInstructionItem('For text questions, type your answer in the text field'),
          _buildInstructionItem('You can review and change your answers before submitting'),
          if (widget.quiz.timeLimitMinutes != null)
            _buildInstructionItem('The quiz will auto-submit when time runs out'),
        ],
      ),
      actions: [
        DialogAction(
          text: 'Got it',
          icon: Icons.check,
          color: Colors.blue,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String text) {
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
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getAnsweredCount() {
    return answers.length;
  }

  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.single:
        return Colors.blue;
      case QuestionType.multiple:
        return Colors.green;
      case QuestionType.text:
        return Colors.orange;
    }
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.single:
        return 'Single Choice';
      case QuestionType.multiple:
        return 'Multiple Choice';
      case QuestionType.text:
        return 'Text Answer';
    }
  }

  Attempt _calculateScoreAndCreateAttempt(bool autoSubmit) {
    double totalScore = 0.0;
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime!);
    
    // Generate unique attempt ID
    final attemptId = DateTime.now().millisecondsSinceEpoch;
    List<AttemptAnswer> attemptAnswers = [];

    for (final question in questions) {
      final userAnswer = answers[question.questionId];
      double questionScore = 0.0;
      bool isCorrect = false;

      if (userAnswer != null) {
        switch (question.type) {
          case QuestionType.single:
            final choices = MockData.getChoicesByQuestion(question.questionId);
            final correctChoice = choices.firstWhere((c) => c.isCorrect);
            isCorrect = userAnswer == correctChoice.choiceId;
            if (isCorrect) {
              questionScore = question.points;
            }
            
            attemptAnswers.add(AttemptAnswer(
              attemptAnswerId: MockData.attemptAnswers.length + attemptAnswers.length + 1,
              attemptId: attemptId,
              questionId: question.questionId,
              choiceId: userAnswer as int,
              freeText: null,
              isCorrect: isCorrect,
            ));
            break;

          case QuestionType.multiple:
            final choices = MockData.getChoicesByQuestion(question.questionId);
            final correctChoiceIds = choices.where((c) => c.isCorrect).map((c) => c.choiceId).toSet();
            final selectedChoiceIds = (userAnswer as List<int>).toSet();
            
            if (correctChoiceIds.isNotEmpty && selectedChoiceIds.isNotEmpty) {
              final correctSelected = correctChoiceIds.intersection(selectedChoiceIds).length;
              final incorrectSelected = selectedChoiceIds.difference(correctChoiceIds).length;
              final totalCorrect = correctChoiceIds.length;
              
              // Check if all correct answers are selected and no incorrect ones
              isCorrect = correctSelected == totalCorrect && incorrectSelected == 0;
              
              if (isCorrect) {
                questionScore = question.points;
              } else {
                // Partial scoring: (correct selections - incorrect selections) / total correct
                final partialScore = (correctSelected - incorrectSelected) / totalCorrect;
                questionScore = (partialScore.clamp(0.0, 1.0) * question.points);
              }
            }
            
            // For multiple choice, we'll create separate answers for each selected choice
            for (final choiceId in userAnswer) {
              final choice = choices.firstWhere((c) => c.choiceId == choiceId);
              attemptAnswers.add(AttemptAnswer(
                attemptAnswerId: MockData.attemptAnswers.length + attemptAnswers.length + 1,
                attemptId: attemptId,
                questionId: question.questionId,
                choiceId: choiceId,
                freeText: null,
                isCorrect: choice.isCorrect,
              ));
            }
            break;

          case QuestionType.text:
            // For text questions, we'll give full points if there's an answer
            // In a real app, this would need manual grading or AI evaluation
            final textAnswer = userAnswer as String;
            isCorrect = textAnswer.trim().isNotEmpty;
            if (isCorrect) {
              questionScore = question.points;
            }
            
            attemptAnswers.add(AttemptAnswer(
              attemptAnswerId: MockData.attemptAnswers.length + attemptAnswers.length + 1,
              attemptId: attemptId,
              questionId: question.questionId,
              choiceId: null,
              freeText: textAnswer,
              isCorrect: isCorrect,
            ));
            break;
        }
      } else {
        // No answer provided
        attemptAnswers.add(AttemptAnswer(
          attemptAnswerId: MockData.attemptAnswers.length + attemptAnswers.length + 1,
          attemptId: attemptId,
          questionId: question.questionId,
          choiceId: null,
          freeText: null,
          isCorrect: false,
        ));
      }

      totalScore += questionScore;
    }

    // Create the attempt
    final attempt = Attempt(
      attemptId: attemptId,
      quizId: widget.quiz.quizId,
      userId: widget.currentUserId,
      startedAt: startTime!,
      submittedAt: endTime,
      score: totalScore,
      timeSpentSeconds: duration.inSeconds,
    );

    // Add to mock data
    MockData.attempts.add(attempt);
    MockData.attemptAnswers.addAll(attemptAnswers);

    return attempt;
  }
}