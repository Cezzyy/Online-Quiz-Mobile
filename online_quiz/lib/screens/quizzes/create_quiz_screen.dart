import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz.dart';
import '../../models/course.dart';
import '../../models/question.dart';
import '../../providers/quiz_provider.dart';
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
    {'label': '30 min', 'value': 30},
    {'label': '1 hour', 'value': 60},
    {'label': '1.5 hours', 'value': 90},
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
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _saveAsDraft,
            child: const Text(
              'Draft',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: _publishQuiz,
            child: const Text(
              'Publish',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Quiz Details Section
            Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuizDetailsForm(),
                ],
              ),
            ),
            
            // Questions Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Questions (${_questions.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Question'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _questions.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.quiz_outlined,
                              title: 'No Questions Yet',
                              message: 'Add questions to your quiz to get started.',
                              action: ElevatedButton.icon(
                                onPressed: _addQuestion,
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Question'),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _questions.length,
                              itemBuilder: (context, index) {
                                return _buildQuestionCard(index);
                              },
                            ),
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

  Widget _buildQuizDetailsForm() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Quiz Title',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a quiz title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _selectedTimeLimit,
                decoration: const InputDecoration(
                  labelText: 'Time Limit',
                  border: OutlineInputBorder(),
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
            const SizedBox(width: 16),
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
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                    errorText: _dueDate == null ? 'Please select a due date' : null,
                  ),
                  child: Text(
                    _dueDate != null
                        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                        : 'Select due date',
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getQuestionTypeColor(question.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question.type.value,
                    style: TextStyle(
                      color: _getQuestionTypeColor(question.type),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${question.points} pts',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
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
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.body,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (question.choices.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...question.choices.asMap().entries.map((entry) {
                final choiceIndex = entry.key;
                final choice = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: choice.isCorrect 
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          border: Border.all(
                            color: choice.isCorrect ? Colors.green : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + choiceIndex), // A, B, C, D
                            style: TextStyle(
                              color: choice.isCorrect ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                                ? Colors.green 
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (choice.isCorrect)
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    ],
                  ),
                );
              }),
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
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
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
    if (_validateQuiz()) {
      await _saveQuiz(false);
    }
  }

  Future<void> _publishQuiz() async {
    if (_validateQuiz()) {
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

  QuestionData({
    required this.type,
    required this.body,
    required this.points,
    required this.choices,
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

// Question Dialog for adding/editing questions
class _QuestionDialog extends StatefulWidget {
  final QuestionData? questionData;
  final Function(QuestionData) onSave;

  const _QuestionDialog({
    this.questionData,
    required this.onSave,
  });

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
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
    return AlertDialog(
      title: Text(widget.questionData != null ? 'Edit Question' : 'Add Question'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<QuestionType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Question Type',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveQuestion,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildChoiceField(int index, ChoiceController choiceController) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index), // A, B, C, D
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: choiceController.controller,
              decoration: const InputDecoration(
                hintText: 'Enter choice text',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter choice text';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
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
          IconButton(
            onPressed: _choiceControllers.length > 2 
                ? () => _removeChoice(index)
                : null,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
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
    );

    widget.onSave(questionData);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _bodyController.dispose();
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