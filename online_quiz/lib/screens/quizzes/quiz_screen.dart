import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz.dart';
import '../../models/question.dart';
import '../../models/attempt.dart';
import '../../utils/app_theme.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/local_auth_provider.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final Quiz quiz;
  final int currentUserId;

  const QuizScreen({
    super.key,
    required this.quiz,
    this.currentUserId = 4,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> with TickerProviderStateMixin {
  late List<Question> questions;
  late PageController pageController;
  late AnimationController timerAnimationController;
  
  int currentQuestionIndex = 0;
  Map<int, dynamic> answers = {}; // questionId -> answer (choiceId, List<choiceId>, or String)
  DateTime? startTime;
  int timeRemainingSeconds = 0;
  bool isSubmitting = false;
  int? attemptId; // Track the current attempt ID
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    
    // Mark quiz as started - prevent app locking during quiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(localAuthProvider.notifier).startQuiz();
      }
    });
    
    questions = [];
    pageController = PageController();
    startTime = DateTime.now();
    
    // Load quiz details and initialize attempt through provider
    Future.microtask(() async {
      await ref.read(quizProvider.notifier).loadQuizDetails(widget.quiz.quizId);
      
      // Get questions from provider after loading
      final quizState = ref.read(quizProvider);
      if (mounted) {
        setState(() {
          questions = quizState.selectedQuizQuestions;
        });
      }
      
      // Start quiz attempt and store attemptId
      final attempt = await ref.read(quizProvider.notifier).startQuizAttempt(
        widget.quiz.quizId,
        widget.currentUserId,
      );
      
      if (attempt != null) {
        setState(() {
          attemptId = attempt.attemptId;
          isLoading = false; // Mark loading as complete
        });
        
        // Start timer after loading is complete
        if (widget.quiz.timeLimitMinutes != null && mounted) {
          _startTimer();
        }
      } else {
        // Failed to create attempt - show error
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          final quizState = ref.read(quizProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start quiz: ${quizState.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          Navigator.of(context).pop(); // Exit quiz screen
        }
      }
    });
    
    // Initialize timer controller but don't start it yet
    if (widget.quiz.timeLimitMinutes != null) {
      timeRemainingSeconds = widget.quiz.timeLimitMinutes! * 60;
      timerAnimationController = AnimationController(
        duration: Duration(seconds: timeRemainingSeconds),
        vsync: this,
      );
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
          final shouldSubmit = await _showExitConfirmation();
          if (shouldSubmit && context.mounted) {
            // Submit quiz and navigate to results
            _submitQuiz(autoSubmit: true, isEarlyExit: true);
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
              child: isLoading 
                  ? _buildSkeletonLoader()
                  : PageView.builder(
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
          final shouldSubmit = await _showExitConfirmation();
          if (shouldSubmit && context.mounted) {
            // Submit quiz and navigate to results
            _submitQuiz(autoSubmit: true, isEarlyExit: true);
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
            value: questions.isEmpty ? 0.0 : (currentQuestionIndex + 1) / questions.length,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
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
              // Question header skeleton
              Row(
                children: [
                  _buildShimmerBox(width: 120, height: 28, radius: 20),
                  const Spacer(),
                  _buildShimmerBox(width: 80, height: 28, radius: 20),
                ],
              ),
              const SizedBox(height: 24),
              // Question body skeleton
              _buildShimmerBox(width: double.infinity, height: 20, radius: 4),
              const SizedBox(height: 12),
              _buildShimmerBox(width: double.infinity, height: 20, radius: 4),
              const SizedBox(height: 12),
              _buildShimmerBox(width: 200, height: 20, radius: 4),
              const SizedBox(height: 24),
              // Answer section skeleton
              _buildShimmerBox(width: 150, height: 16, radius: 4),
              const SizedBox(height: 12),
              // Choice options skeleton
              ...List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildShimmerBox(
                  width: double.infinity,
                  height: 56,
                  radius: 12,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    if (widget.quiz.timeLimitMinutes == null) return const SizedBox.shrink();

    final hours = timeRemainingSeconds ~/ 3600;
    final minutes = (timeRemainingSeconds % 3600) ~/ 60;
    final seconds = timeRemainingSeconds % 60;
    final isLowTime = timeRemainingSeconds <= 300; // 5 minutes

    // Format time string based on duration
    String timeString;
    if (hours > 0) {
      timeString = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

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
            'Time Remaining: $timeString',
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
    final quizState = ref.watch(quizProvider);
    final choices = quizState.questionChoices[question.questionId] ?? [];
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
    final quizState = ref.watch(quizProvider);
    final choices = quizState.questionChoices[question.questionId] ?? [];
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
    // Disable navigation buttons while loading
    if (isLoading) {
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Loading...'),
          ),
        ),
      );
    }
    
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
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit Quiz',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unansweredCount > 0 
                              ? 'You have $unansweredCount unanswered question${unansweredCount == 1 ? '' : 's'}.'
                              : 'Are you sure you want to submit your quiz?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Warning content
            if (unansweredCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
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
              ),
            if (unansweredCount > 0) const SizedBox(height: 16),
            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Review'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _submitQuiz();
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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
            ),
          ],
        ),
      ),
    );
  }

  void _submitQuiz({bool autoSubmit = false, bool isEarlyExit = false}) async {
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

    Attempt? attempt;
    
    try {
      // Check if we have an attemptId
      if (attemptId == null) {
        throw Exception('Failed to submit: Quiz attempt was not properly initialized. Please try restarting the quiz.');
      }
      
      // Submit quiz through provider
      attempt = await ref.read(quizProvider.notifier).submitQuizAttempt(
        attemptId: attemptId!,
        quizId: widget.quiz.quizId,
        userId: widget.currentUserId,
        answers: answers,
        startTime: startTime!,
        autoSubmit: autoSubmit,
      );

      if (!mounted) return;
      
      navigator.pop(); // Close loading dialog
      
      // End quiz session
      ref.read(localAuthProvider.notifier).endQuiz();
      
      if (attempt == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Quiz submitted but result is unavailable. Please check your results later.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
        // Pop back to quiz list/course screen, removing quiz detail and quiz screen
        navigator.popUntil((route) => route.isFirst || route.settings.name == '/courses');
        return;
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            isEarlyExit
                ? 'Quiz submitted successfully!'
                : autoSubmit 
                    ? 'Quiz auto-submitted due to time limit'
                    : 'Quiz submitted successfully!',
          ),
          backgroundColor: autoSubmit && !isEarlyExit ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      // Get course from provider with timeout
      try {
        final course = await ref.read(quizProvider.notifier).getCourseForQuiz(widget.quiz.quizId)
            .timeout(const Duration(seconds: 10));
        
        if (!mounted) return;
        
        // Navigate to quiz result screen, replacing both quiz screen and quiz detail screen
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: widget.quiz,
              course: course,
              attempt: attempt!,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        // Navigate without course info if it fails to load
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: widget.quiz,
              course: null,
              attempt: attempt!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Close loading dialog
        
        // End quiz session
        ref.read(localAuthProvider.notifier).endQuiz();
        
        // Show error and exit quiz screen to prevent retaking
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to submit quiz: $e\nYour attempt has been recorded.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        // Exit quiz screen back to previous screen
        navigator.pop();
      }
    }
  }

  Future<bool> _showExitConfirmation() async {
    final unansweredCount = questions.length - _getAnsweredCount();
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit & Exit Quiz',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unansweredCount > 0
                              ? 'Exiting will submit your quiz. You have $unansweredCount unanswered question${unansweredCount == 1 ? '' : 's'}.'
                              : 'Exiting will submit your quiz. You cannot retake it.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Warning content
            if (unansweredCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
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
              ),
            if (unansweredCount > 0) const SizedBox(height: 16),
            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue Quiz'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.send),
                      label: const Text('Submit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  void _showInstructions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiz Instructions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How to take this quiz',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
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
            ),
            // Action button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Got it'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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


}