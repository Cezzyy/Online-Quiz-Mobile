import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Map<int, String?> _pointsErrors = {};

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
          _pointsErrors[answer.attemptAnswerId] = null;
          
          // Add listener for real-time validation
          _pointsControllers[answer.attemptAnswerId]!.addListener(() {
            _validatePoints(answer.attemptAnswerId, question.points);
          });
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

  void _validatePoints(int attemptAnswerId, double maxPoints) {
    final controller = _pointsControllers[attemptAnswerId];
    if (controller == null) return;
    
    final text = controller.text;
    
    if (text.isEmpty) {
      setState(() {
        _pointsErrors[attemptAnswerId] = null;
      });
      return;
    }

    final value = double.tryParse(text);
    
    if (value == null) {
      setState(() {
        _pointsErrors[attemptAnswerId] = 'Please enter a valid number';
      });
      return;
    }

    if (value < 0) {
      // Auto-correct to 0
      controller.value = TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
      setState(() {
        _pointsErrors[attemptAnswerId] = null;
      });
      return;
    }

    if (value > maxPoints) {
      // Auto-correct to max points
      final maxText = maxPoints.toStringAsFixed(1);
      controller.value = TextEditingValue(
        text: maxText,
        selection: TextSelection.collapsed(offset: maxText.length),
      );
      setState(() {
        _pointsErrors[attemptAnswerId] = null;
      });
      return;
    }

    setState(() {
      _pointsErrors[attemptAnswerId] = null;
    });
  }

  Future<void> _saveGrades() async {
    // Check for validation errors first
    bool hasErrors = false;
    for (final questionData in _textQuestions) {
      final answer = questionData['answer'] as AttemptAnswer;
      if (_pointsErrors[answer.attemptAnswerId] != null) {
        hasErrors = true;
        break;
      }
    }

    if (hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid points for all questions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
          throw Exception('Please enter valid points for all questions');
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
            content: Text('✓ Grades saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate grading was completed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save grades: ${e.toString().replaceAll('Exception: ', '')}'),
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
    final isDark = theme.brightness == Brightness.dark;
    final user = widget.userData['user'] as Map<String, dynamic>;
    final student = widget.userData['student'] as Map<String, dynamic>;
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight < 700 ? 260.0 : 300.0;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Gradient Header
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Gradient Background
                    Container(
                      height: headerHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
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
                      bottom: 30,
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
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 70,
                      left: 24,
                      right: 24,
                      child: Column(
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.rate_review,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            'Manual Grading',
                            style: TextStyle(
                              fontSize: screenHeight < 700 ? 26 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // View Information Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showInfoBottomSheet(context, user, student, isDark),
                      icon: const Icon(Icons.info_outline, size: 20),
                      label: const Text('View Information'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Questions List
                Expanded(
                  child: _textQuestions.isEmpty
                      ? _buildEmptyState(context, isDark)
                      : RefreshIndicator(
                          onRefresh: _loadTextQuestions,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _textQuestions.length,
                            itemBuilder: (context, index) {
                              final questionData = _textQuestions[index];
                              final question = questionData['question'] as Question;
                              final answer = questionData['answer'] as AttemptAnswer;
                              
                              return _buildQuestionCard(
                                question,
                                answer,
                                index + 1,
                                isDark,
                              );
                            },
                          ),
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
                          blurRadius: 8,
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
                            elevation: 0,
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
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Grades',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showInfoBottomSheet(BuildContext context, Map<String, dynamic> user, Map<String, dynamic> student, bool isDark) {
    final theme = Theme.of(context);
    
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
                          'Grading Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Quiz and student information',
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
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      Icons.quiz,
                      'Quiz',
                      widget.quiz.title,
                      isDark,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      Icons.person,
                      'Student Name',
                      user['FullName'] as String,
                      isDark,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      Icons.badge,
                      'Student ID',
                      student['StudentId'] as String,
                      isDark,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      Icons.class_,
                      'Section',
                      student['Section'] ?? 'N/A',
                      isDark,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      Icons.calendar_today,
                      'Submitted',
                      _formatDate(widget.attempt.submittedAt!),
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Text Questions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This quiz has no text questions that require manual grading.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question, AttemptAnswer answer, int number, bool isDark) {
    final theme = Theme.of(context);
    final isGraded = answer.isGraded;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                        AppTheme.secondaryColor.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Q$number',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.body,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${question.points}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Student Answer Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Student Answer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    answer.freeText ?? 'No answer provided',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: answer.freeText == null 
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                          : null,
                      fontStyle: answer.freeText == null ? FontStyle.italic : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Grading Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.grading,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Grading',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _pointsControllers[answer.attemptAnswerId],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Points',
                            hintText: '0 - ${question.points}',
                            prefixIcon: const Icon(Icons.star_border, size: 20),
                            errorText: _pointsErrors[answer.attemptAnswerId],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _pointsErrors[answer.attemptAnswerId] != null 
                                    ? Colors.red 
                                    : AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
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
                            hintText: 'Add feedback...',
                            prefixIcon: const Icon(Icons.comment_outlined, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isGraded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Previously graded: ${answer.pointsAwarded?.toStringAsFixed(1)} pts',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
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
