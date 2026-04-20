import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/quiz.dart';
import '../../models/course.dart';
import '../../models/question.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/empty_state_widget.dart';

class CreateQuizScreen extends ConsumerStatefulWidget {
  final Course course;
  final Quiz quiz;

  const CreateQuizScreen({
    super.key,
    required this.course,
    required this.quiz,
  });

  @override
  ConsumerState<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends ConsumerState<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int? _selectedTimeLimit;
  DateTime? _dueDate;
  
  final List<QuestionData> _questions = [];

  final List<Map<String, dynamic>> _timeLimitOptions = [
    {'label': '30 minutes', 'value': 30},
    {'label': '1 hour', 'value': 60},
    {'label': '90 minutes', 'value': 90},
    {'label': '2 hours', 'value': 120},
    {'label': '3 hours', 'value': 180},
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.quiz.title;
    _selectedTimeLimit = widget.quiz.timeLimitMinutes;
    _dueDate = widget.quiz.dueAt;
    
    // Load existing questions if this is an existing quiz
    _loadExistingQuestions();
  }

  void _loadExistingQuestions() {
    // Delay the loading to avoid modifying provider during build
    Future.microtask(() async {
      try {
        // Load quiz details which includes questions and choices
        await ref.read(quizProvider.notifier).loadQuizDetails(widget.quiz.quizId);
        
        final quizState = ref.read(quizProvider);
        final existingQuestions = quizState.selectedQuizQuestions;
        final questionChoices = quizState.questionChoices;
        
        for (final question in existingQuestions) {
          final choices = questionChoices[question.questionId] ?? [];
          final choiceDataList = choices.map((choice) => ChoiceData(
            text: choice.body,
            isCorrect: choice.isCorrect,
          )).toList();
          
          if (mounted) {
            setState(() {
              _questions.add(QuestionData(
                type: question.type,
                body: question.body,
                points: question.points,
                choices: choiceDataList,
              ));
            });
          }
        }
      } catch (e) {
        // If loading fails, start with empty questions (new quiz)
        // This is expected for newly created quizzes
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _saveAsDraft,
            icon: const Icon(Icons.save, size: 18, color: Colors.white),
            label: const Text(
              'Draft',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: _publishQuiz,
            icon: const Icon(Icons.publish, size: 18),
            label: const Text(
              'Publish',
              style: TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz Details Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quiz Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildQuizDetailsForm(),
                  ],
                ),
              ),
              
              // Questions Section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.quiz,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Questions (${_questions.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _questions.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.quiz_outlined,
                            title: 'No Questions Yet',
                            message: 'Add questions to your quiz to get started.',
                            action: ElevatedButton.icon(
                              onPressed: _addQuestion,
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Question'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          )
                        : Column(
                            children: _questions.asMap().entries.map((entry) {
                              return _buildQuestionCard(entry.key);
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizDetailsForm() {
    return Column(
      children: [
        // Course Code Display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${widget.course.code} - ${widget.course.name}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.course.section != null && widget.course.section!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.course.section!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Quiz Title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a quiz title';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _selectedTimeLimit,
                decoration: InputDecoration(
                  labelText: 'Time Limit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.timer),
                ),
                items: _timeLimitOptions.map((option) {
                  return DropdownMenuItem<int>(
                    value: option['value'],
                    child: Text(option['label']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTimeLimit = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a time limit';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _dueDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDate != null
                        ? DateFormat('MMM d, yyyy').format(_dueDate!)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _dueDate != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: isDark ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getQuestionTypeColor(question.type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question.type.value,
                    style: TextStyle(
                      color: _getQuestionTypeColor(question.type),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${question.points.toInt()} pts',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editQuestion(index);
                      } else if (value == 'delete') {
                        _deleteQuestion(index);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question.body,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            if (question.choices.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...question.choices.asMap().entries.map((entry) {
                final choiceIndex = entry.key;
                final choice = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: choice.isCorrect 
                        ? Colors.green.withValues(alpha: 0.08)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: choice.isCorrect 
                          ? Colors.green.withValues(alpha: 0.3)
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: choice.isCorrect 
                              ? Colors.green.withValues(alpha: 0.15)
                              : theme.colorScheme.surface,
                          border: Border.all(
                            color: choice.isCorrect 
                                ? Colors.green 
                                : theme.colorScheme.outline.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + choiceIndex), // A, B, C, D
                            style: TextStyle(
                              color: choice.isCorrect 
                                  ? Colors.green 
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          choice.text,
                          style: TextStyle(
                            color: choice.isCorrect 
                                ? Colors.green.shade800
                                : theme.colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: choice.isCorrect ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (choice.isCorrect)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            if (question.correctAnswer != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Correct Answer:',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            question.correctAnswer!,
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.single:
        return Colors.blue;
      case QuestionType.multiple:
        return Colors.orange;
      case QuestionType.text:
        return Colors.purple;
    }
  }

  void _addQuestion() {
    _showQuestionDialog();
  }

  void _editQuestion(int index) {
    _showQuestionDialog(questionData: _questions[index], index: index);
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _questions.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showQuestionDialog({QuestionData? questionData, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionBottomSheet(
        questionData: questionData,
        onSave: (newQuestionData) {
          setState(() {
            if (index != null) {
              _questions[index] = newQuestionData;
            } else {
              _questions.add(newQuestionData);
            }
          });
        },
      ),
    );
  }

  Future<void> _saveAsDraft() async {
    if (!_validateQuiz()) {
      return;
    }

    // Show confirmation bottom sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmationBottomSheet(
        title: 'Save as Draft',
        message: 'Save "${_titleController.text}" as draft?\n\nYou can publish it later when ready.',
        icon: Icons.save_outlined,
        iconColor: Colors.blue,
        confirmText: 'Save Draft',
        confirmColor: Colors.blue,
      ),
    );

    if (confirmed == true) {
      await _saveQuiz(false);
    }
  }

  Future<void> _publishQuiz() async {
    if (!_validateQuiz()) {
      return;
    }

    // Show confirmation bottom sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmationBottomSheet(
        title: 'Publish Quiz',
        message: 'Publish "${_titleController.text}"?\n\nStudents will be able to see and take this quiz immediately.',
        icon: Icons.publish,
        iconColor: AppTheme.primaryColor,
        confirmText: 'Publish',
        confirmColor: AppTheme.primaryColor,
      ),
    );

    if (confirmed == true) {
      await _saveQuiz(true);
    }
  }

  bool _validateQuiz() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return false;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveQuiz(bool publish) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Prepare questions with choices in the format expected by updateCompleteQuiz
      final questionsWithChoices = <Map<String, dynamic>>[];
      
      for (int i = 0; i < _questions.length; i++) {
        final questionData = _questions[i];
        
        final questionMap = {
          'type': questionData.type.value,
          'text': questionData.body,
          'points': questionData.points,
          'sortOrder': i + 1,
          'correctAnswer': questionData.correctAnswer,
          'choices': questionData.choices.map((choice) => {
            'text': choice.text,
            'isCorrect': choice.isCorrect,
          }).toList(),
        };
        
        questionsWithChoices.add(questionMap);
      }

      // Update quiz with questions and choices using provider
      final success = await ref.read(quizProvider.notifier).updateCompleteQuiz(
        quizId: widget.quiz.quizId,
        title: _titleController.text.trim(),
        dueAt: _dueDate,
        timeLimitMinutes: _selectedTimeLimit,
        isPublished: publish,
        questionsWithChoices: questionsWithChoices,
      );

      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Reload quiz details to ensure questions are loaded
        await ref.read(quizProvider.notifier).loadQuizDetails(widget.quiz.quizId);
        
        if (!mounted) return;
        
        // Close the quiz editor
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publish 
                  ? 'Quiz "${_titleController.text}" published successfully!'
                  : 'Quiz "${_titleController.text}" saved as draft.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(quizProvider).error ?? 'Failed to save quiz'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving quiz: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}

// Data classes for managing questions
class QuestionData {
  final QuestionType type;
  final String body;
  final double points;
  final List<ChoiceData> choices;
  final String? correctAnswer; // For text-type questions

  QuestionData({
    required this.type,
    required this.body,
    required this.points,
    required this.choices,
    this.correctAnswer,
  });
}

class ChoiceData {
  final String text;
  final bool isCorrect;

  ChoiceData({
    required this.text,
    required this.isCorrect,
  });
}

// Question Bottom Sheet for adding/editing questions
class _QuestionBottomSheet extends StatefulWidget {
  final QuestionData? questionData;
  final Function(QuestionData) onSave;

  const _QuestionBottomSheet({
    this.questionData,
    required this.onSave,
  });

  @override
  State<_QuestionBottomSheet> createState() => _QuestionBottomSheetState();
}

class _QuestionBottomSheetState extends State<_QuestionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
  final _correctAnswerController = TextEditingController(); // For text questions
  double _selectedPoints = 1.0;
  QuestionType _selectedType = QuestionType.single;
  List<ChoiceController> _choiceControllers = [];
  
  static const List<double> _availablePoints = [1.0, 3.0, 5.0, 10.0];

  @override
  void initState() {
    super.initState();
    
    if (widget.questionData != null) {
      _bodyController.text = widget.questionData!.body;
      _selectedPoints = widget.questionData!.points;
      _selectedType = widget.questionData!.type;
      
      if (widget.questionData!.correctAnswer != null) {
        _correctAnswerController.text = widget.questionData!.correctAnswer!;
      }
      
      _choiceControllers = widget.questionData!.choices.map((choice) {
        return ChoiceController(
          controller: TextEditingController(text: choice.text),
          isCorrect: choice.isCorrect,
        );
      }).toList();
    } else {
      _selectedPoints = 1.0;
      if (_selectedType != QuestionType.text) {
        _addChoice();
        _addChoice();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.questionData != null ? 'Edit Question' : 'Add Question',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      DropdownButtonFormField<QuestionType>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Question Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        items: QuestionType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                            _choiceControllers.clear();
                            if (_selectedType != QuestionType.text) {
                              _addChoice();
                              _addChoice();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bodyController,
                        decoration: InputDecoration(
                          labelText: 'Question',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.help_outline),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a question';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<double>(
                        initialValue: _selectedPoints,
                        decoration: InputDecoration(
                          labelText: 'Points',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.star_outline),
                        ),
                        items: _availablePoints.map((points) {
                          return DropdownMenuItem<double>(
                            value: points,
                            child: Text('${points.round()} pt${points > 1 ? 's' : ''}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPoints = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select points';
                          }
                          return null;
                        },
                      ),
                      if (_selectedType == QuestionType.text) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Correct Answer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _correctAnswerController,
                          decoration: InputDecoration(
                            labelText: 'Expected Answer',
                            hintText: 'Enter the correct answer for validation',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            helperText: 'Student answers will be compared to this (case-insensitive)',
                            prefixIcon: const Icon(Icons.check_circle_outline),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the correct answer';
                            }
                            return null;
                          },
                        ),
                      ],
                      if (_selectedType != QuestionType.text) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Answer Choices',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: _addChoice,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Choice'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._choiceControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final choiceController = entry.value;
                          return _buildChoiceField(index, choiceController);
                        }),
                      ],
                      const SizedBox(height: 80), // Extra space for bottom buttons
                    ],
                  ),
                ),
              ),
              // Bottom action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saveQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Save Question'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChoiceField(int index, ChoiceController choiceController) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: choiceController.isCorrect 
                ? Colors.green.withValues(alpha: 0.5)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: choiceController.isCorrect ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: choiceController.isCorrect 
              ? Colors.green.withValues(alpha: 0.05)
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: choiceController.isCorrect 
                        ? Colors.green.withValues(alpha: 0.15)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: choiceController.isCorrect 
                          ? Colors.green 
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: choiceController.isCorrect 
                            ? Colors.green 
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choice ${String.fromCharCode(65 + index)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Correct',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Checkbox(
                      value: choiceController.isCorrect,
                      onChanged: (value) {
                        setState(() {
                          if (_selectedType == QuestionType.single) {
                            // For single choice, uncheck all others
                            for (var controller in _choiceControllers) {
                              controller.isCorrect = false;
                            }
                          }
                          choiceController.isCorrect = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
                if (_choiceControllers.length > 2)
                  IconButton(
                    onPressed: () => _removeChoice(index),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: choiceController.controller,
              decoration: InputDecoration(
                hintText: 'Enter choice text',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter choice text';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addChoice() {
    setState(() {
      _choiceControllers.add(ChoiceController(
        controller: TextEditingController(),
        isCorrect: false,
      ));
    });
  }

  void _removeChoice(int index) {
    setState(() {
      _choiceControllers[index].controller.dispose();
      _choiceControllers.removeAt(index);
    });
  }

  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType != QuestionType.text) {
      // Validate choices
      if (_choiceControllers.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least 2 choices')),
        );
        return;
      }

      final correctAnswersCount = _choiceControllers.where((c) => c.isCorrect).length;
      
      if (_selectedType == QuestionType.multiple) {
        // Multiple choice must have at least 2 correct answers
        if (correctAnswersCount < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Multiple choice questions must have at least 2 correct answers'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      } else {
        // Single choice must have exactly 1 correct answer
        if (correctAnswersCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please mark at least one correct answer')),
          );
          return;
        }
      }
    }

    final questionData = QuestionData(
      type: _selectedType,
      body: _bodyController.text.trim(),
      points: _selectedPoints,
      choices: _choiceControllers.map((controller) {
        return ChoiceData(
          text: controller.controller.text.trim(),
          isCorrect: controller.isCorrect,
        );
      }).toList(),
      correctAnswer: _selectedType == QuestionType.text 
          ? _correctAnswerController.text.trim() 
          : null,
    );

    widget.onSave(questionData);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _correctAnswerController.dispose();
    for (var controller in _choiceControllers) {
      controller.controller.dispose();
    }
    super.dispose();
  }
}

class ChoiceController {
  final TextEditingController controller;
  bool isCorrect;

  ChoiceController({
    required this.controller,
    required this.isCorrect,
  });
}


// Confirmation Bottom Sheet
class _ConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String confirmText;
  final Color confirmColor;

  const _ConfirmationBottomSheet({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.confirmText,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Message
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(confirmText),
                ),
              ),
            ],
          ),
          // Add bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
