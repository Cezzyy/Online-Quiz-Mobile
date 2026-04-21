import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attempt.dart';
import '../../models/attempt_answer.dart';
import '../../models/choice.dart';
import '../../models/course.dart';
import '../../models/question.dart';
import '../../models/quiz.dart';
import '../../models/student.dart';
import '../../models/user.dart';
import '../../services/quiz_service.dart';
import '../../utils/app_theme.dart';
// Detailed student result screen
class QuizStudentDetailScreen extends ConsumerStatefulWidget {
  final Quiz quiz;
  final Course course;
  final Student student;
  final User user;
  final Attempt attempt;

  const QuizStudentDetailScreen({
    super.key,
    required this.quiz,
    required this.course,
    required this.student,
    required this.user,
    required this.attempt,
  });

  @override
  ConsumerState<QuizStudentDetailScreen> createState() => _QuizStudentDetailScreenState();
}

class _QuizStudentDetailScreenState extends ConsumerState<QuizStudentDetailScreen> {
  final QuizService _quizService = QuizService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _questionResults = [];
  double _totalPoints = 0.0;

  @override
  void initState() {
    super.initState();
    _loadQuestionResults();
  }

  Future<void> _loadQuestionResults() async {
    try {
      // Load quiz questions
      final questions = await _quizService.getQuizQuestions(widget.quiz.quizId);
      _totalPoints = questions.fold(0.0, (sum, q) => sum + q.points);

      // Load attempt answers
      final answers = await _quizService.getAttemptAnswers(widget.attempt.attemptId);

      // Load choices for all questions
      final questionIds = questions.map((q) => q.questionId).toList();
      final choicesByQuestion = await _quizService.getChoicesForQuestions(questionIds);

      // Build question results
      final results = <Map<String, dynamic>>[];
      for (final question in questions) {
        final questionAnswers = answers.where((a) => a.questionId == question.questionId).toList();
        final choices = choicesByQuestion[question.questionId] ?? [];
        
        // Determine if question is correct and points earned
        bool isCorrect = false;
        double pointsEarned = 0.0;
        bool isPending = false;
        
        if (questionAnswers.isNotEmpty) {
          // For text questions, check if they need grading
          if (question.type == QuestionType.text) {
            final answer = questionAnswers.first;
            if (answer.needsGrading) {
              // Question is pending manual grading
              isPending = true;
              isCorrect = false; // Will be used to show pending state
              pointsEarned = 0.0;
            } else if (answer.isGraded) {
              // Question has been graded
              pointsEarned = answer.pointsAwarded ?? 0.0;
              isCorrect = pointsEarned > 0;
            }
          } else if (question.type == QuestionType.multiple) {
            final correctChoices = choices.where((c) => c.isCorrect).toList();
            final selectedCorrectChoices = questionAnswers.where((a) => a.isCorrect == true).toList();
            final selectedIncorrectChoices = questionAnswers.where((a) => a.isCorrect == false).toList();
            isCorrect = selectedCorrectChoices.length == correctChoices.length && selectedIncorrectChoices.isEmpty;
            if (isCorrect) {
              pointsEarned = question.points;
            }
          } else {
            // Single choice
            isCorrect = questionAnswers.any((a) => a.isCorrect == true);
            if (isCorrect) {
              pointsEarned = question.points;
            }
          }
        }

        results.add({
          'question': question,
          'answers': questionAnswers,
          'choices': choices,
          'isCorrect': isCorrect,
          'pointsEarned': pointsEarned,
          'isPending': isPending,
        });
      }

      if (mounted) {
        setState(() {
          _questionResults = results;
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
            content: Text('Error loading results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Check if there are any pending questions
    final hasPendingQuestions = _questionResults.any((r) => r['isPending'] == true);
    final percentage = _totalPoints > 0 ? (widget.attempt.score / _totalPoints) * 100 : 0.0;
    
    Color scoreColor;
    if (hasPendingQuestions) {
      // If there are pending questions, use orange color
      scoreColor = Colors.orange;
    } else if (percentage >= 90) {
      scoreColor = Colors.green;
    } else if (percentage >= 75) {
      scoreColor = Colors.blue;
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQuestionResults,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Header Section with Gradient
                    _buildHeader(context, percentage, scoreColor),
                    const SizedBox(height: 24),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Score Summary Card
                          _buildScoreSummaryCard(context, percentage, scoreColor),
                          
                          const SizedBox(height: 16),
                          
                          // Student & Quiz Info Button
                          _buildInfoButton(context, isDark),
                          
                          const SizedBox(height: 16),
                          
                          // Question Results
                          _buildQuestionResultsList(context, isDark),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, double percentage, Color scoreColor) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight < 700 ? 240.0 : 260.0;
    final correctCount = _questionResults.where((r) => r['isCorrect'] == true && r['isPending'] != true).length;
    final pendingCount = _questionResults.where((r) => r['isPending'] == true).length;
    final totalQuestions = _questionResults.length;
    final hasPending = pendingCount > 0;
    
    // Build status text
    String statusText;
    if (hasPending) {
      if (pendingCount == totalQuestions) {
        statusText = 'Pending Grading';
      } else {
        statusText = '$correctCount Correct • $pendingCount Pending';
      }
    } else {
      statusText = '${percentage.round()}% • $correctCount/$totalQuestions Correct';
    }
    
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Gradient Background
        Container(
          height: headerHeight,
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
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
        // Content
        Positioned(
          top: MediaQuery.of(context).padding.top + 40,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.grade,
                color: Colors.white,
                size: screenHeight < 700 ? 40 : 48,
              ),
              SizedBox(height: screenHeight < 700 ? 12 : 16),
              Text(
                widget.user.fullName,
                style: TextStyle(
                  fontSize: screenHeight < 700 ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        ),
      ],
    );
  }

  Widget _buildScoreSummaryCard(BuildContext context, double percentage, Color scoreColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasPending = _questionResults.any((r) => r['isPending'] == true);
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreStat(
                  context,
                  'Score',
                  hasPending ? 'Pending' : '${widget.attempt.score.toStringAsFixed(1)}',
                  hasPending ? 'Awaiting grading' : 'out of ${_totalPoints.toStringAsFixed(1)}',
                  scoreColor,
                  isDark,
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
                _buildScoreStat(
                  context,
                  'Percentage',
                  hasPending ? 'Pending' : '${percentage.toStringAsFixed(1)}%',
                  hasPending ? 'Awaiting grading' : _getGradeLabel(percentage),
                  scoreColor,
                  isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreStat(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  String _getGradeLabel(double percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 75) return 'Good';
    if (percentage >= 60) return 'Fair';
    return 'Needs Improvement';
  }

  Widget _buildInfoButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showInfoBottomSheet(context),
        icon: const Icon(Icons.info_outline),
        label: const Text('View Student & Quiz Info'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
          foregroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showInfoBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final submittedAt = widget.attempt.submittedAt;
    final timeSpent = widget.attempt.timeSpentSeconds;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.2),
                          AppTheme.secondaryColor.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Student and quiz information',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Information
                  Text(
                    'Student Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(context, Icons.person, 'Name', widget.user.fullName),
                        const Divider(height: 24),
                        _buildDetailRow(context, Icons.email, 'Email', widget.user.email),
                        const Divider(height: 24),
                        _buildDetailRow(context, Icons.badge, 'Student ID', widget.student.studentId),
                        if (widget.student.section != null && widget.student.section!.isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildDetailRow(context, Icons.class_, 'Section', widget.student.section!),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quiz Information
                  Text(
                    'Quiz Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(context, Icons.quiz, 'Quiz', widget.quiz.title),
                        const Divider(height: 24),
                        _buildDetailRow(context, Icons.book, 'Course', '${widget.course.code} - ${widget.course.name}'),
                        if (submittedAt != null) ...[
                          const Divider(height: 24),
                          _buildDetailRow(context, Icons.calendar_today, 'Submitted', _formatDateTime(submittedAt)),
                        ],
                        if (timeSpent != null) ...[
                          const Divider(height: 24),
                          _buildDetailRow(context, Icons.timer, 'Time Spent', _formatDuration(timeSpent)),
                        ],
                      ],
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

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionResultsList(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question Results',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._questionResults.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          return _buildQuestionCard(context, index + 1, result, isDark);
        }),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, int questionNumber, Map<String, dynamic> result, bool isDark) {
    final theme = Theme.of(context);
    final question = result['question'] as Question;
    final answers = result['answers'] as List<AttemptAnswer>;
    final choices = result['choices'] as List<Choice>;
    final isCorrect = result['isCorrect'] as bool;
    final pointsEarned = result['pointsEarned'] as double;
    final isPending = result['isPending'] as bool? ?? false;

    // Determine colors based on state
    Color statusColor;
    IconData statusIcon;
    if (isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    } else if (isCorrect) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Question $questionNumber',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPending 
                        ? 'Pending'
                        : '${pointsEarned.toStringAsFixed(1)}/${question.points.toStringAsFixed(1)} pts',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Question Body
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.body,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            
            // Answer Section
            _buildAnswerSection(context, question, answers, choices, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSection(BuildContext context, Question question, List<AttemptAnswer> answers, List<Choice> choices, bool isDark) {
    final theme = Theme.of(context);
    
    if (answers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text('Not answered', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
          ],
        ),
      );
    }

    if (question.type == QuestionType.text) {
      final answer = answers.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Answer:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              answer.freeText ?? 'No answer provided',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          // Show grading status
          if (answer.needsGrading) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.pending, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pending manual grading',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (answer.isGraded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Graded: ${answer.pointsAwarded?.toStringAsFixed(1)} / ${question.points.toStringAsFixed(1)} pts',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (answer.feedback != null && answer.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 16),
                    Text(
                      'Teacher Feedback:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      answer.feedback!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    }

    // For single and multiple choice
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choices:',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        ...choices.map((choice) {
          final isSelected = answers.any((a) => a.choiceId == choice.choiceId);
          final isCorrectChoice = choice.isCorrect;

          Color? backgroundColor;
          Color? borderColor;
          IconData? icon;

          if (isSelected && isCorrectChoice) {
            backgroundColor = Colors.green.withValues(alpha: 0.1);
            borderColor = Colors.green;
            icon = Icons.check_circle;
          } else if (isSelected && !isCorrectChoice) {
            backgroundColor = Colors.red.withValues(alpha: 0.1);
            borderColor = Colors.red;
            icon = Icons.cancel;
          } else if (!isSelected && isCorrectChoice) {
            backgroundColor = Colors.blue.withValues(alpha: 0.05);
            borderColor = Colors.blue;
            icon = Icons.check_circle_outline;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor ?? (isDark 
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected || isCorrectChoice ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: borderColor,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    choice.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}
