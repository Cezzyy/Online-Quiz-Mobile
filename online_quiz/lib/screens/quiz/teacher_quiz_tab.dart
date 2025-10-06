import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/stat_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';

class TeacherQuizTab extends ConsumerStatefulWidget {
  const TeacherQuizTab({super.key});

  @override
  ConsumerState<TeacherQuizTab> createState() => _TeacherQuizTabState();
}

class _TeacherQuizTabState extends ConsumerState<TeacherQuizTab> {
  Course? selectedCourse;
  List<Quiz> courseQuizzes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.read(courseProvider.notifier).initializeCourses(currentUser.userId);
      }
    });
  }

  void _loadQuizzesForCourse(Course course) {
    setState(() {
      selectedCourse = course;
      courseQuizzes = MockData.getQuizzesByCourse(course.courseId);
    });
  }

  void _showCreateQuizDialog() {
    if (selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _CreateQuizDialog(
        course: selectedCourse!,
        onQuizCreated: () {
          _loadQuizzesForCourse(selectedCourse!);
        },
      ),
    );
  }

  void _showEditQuizDialog(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => _EditQuizDialog(
        quiz: quiz,
        course: selectedCourse!,
        onQuizUpdated: () {
          _loadQuizzesForCourse(selectedCourse!);
        },
      ),
    );
  }

  void _deleteQuiz(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove quiz from mock data
              MockData.quizzes.removeWhere((q) => q.quizId == quiz.quizId);
              // Remove associated questions
              MockData.questions.removeWhere((q) => q.quizId == quiz.quizId);
              // Remove associated choices
              final questionIds = MockData.questions
                  .where((q) => q.quizId == quiz.quizId)
                  .map((q) => q.questionId)
                  .toList();
              MockData.choices.removeWhere((c) => questionIds.contains(c.questionId));
              
              Navigator.pop(context);
              _loadQuizzesForCourse(selectedCourse!);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Quiz "${quiz.title}" deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final teacherCourses = MockData.getCoursesByInstructor(currentUser.userId);

    return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Course Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Course',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (teacherCourses.isEmpty)
                      const Text('No courses assigned to you.')
                    else
                      DropdownButtonFormField<Course>(
                        initialValue: selectedCourse,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Choose a course',
                        ),
                        items: teacherCourses.map((course) {
                          return DropdownMenuItem(
                            value: course,
                            child: Text(
                              '${course.code} - ${course.name}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (course) {
                          if (course != null) {
                            _loadQuizzesForCourse(course);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quiz Stats
            if (selectedCourse != null) ...[
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Quizzes',
                      value: courseQuizzes.length.toString(),
                      icon: Icons.quiz_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Published',
                      value: courseQuizzes.where((q) => q.isPublished).length.toString(),
                      icon: Icons.publish,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Draft',
                      value: courseQuizzes.where((q) => !q.isPublished).length.toString(),
                      icon: Icons.edit_document,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showCreateQuizDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _loadQuizzesForCourse(selectedCourse!);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Quiz List
            Expanded(
              child: selectedCourse == null
                  ? EmptyStateWidget(
                      icon: Icons.school,
                      title: 'Select a Course',
                      message: 'Choose a course from the dropdown above to manage its quizzes.',
                    )
                  : courseQuizzes.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.quiz_outlined,
                          title: 'No Quizzes Yet',
                          message: 'Create your first quiz for ${selectedCourse!.name}.',
                          action: ElevatedButton.icon(
                            onPressed: _showCreateQuizDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Quiz'),
                          ),
                        )
                      : ListView.builder(
                          itemCount: courseQuizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = courseQuizzes[index];
                            final questions = MockData.getQuestionsByQuiz(quiz.quizId);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: quiz.isPublished 
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  child: Icon(
                                   quiz.isPublished ? Icons.publish : Icons.edit_document,
                                   color: quiz.isPublished ? Colors.green : Colors.orange,
                                 ),
                                ),
                                title: Text(
                                  quiz.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${questions.length} questions'),
                                    if (quiz.dueAt != null)
                                      Text(
                                        'Due: ${_formatDate(quiz.dueAt!)}',
                                        style: TextStyle(
                                          color: quiz.isOverdue ? Colors.red : null,
                                        ),
                                      ),
                                    if (quiz.timeLimitMinutes != null)
                                      Text('Time limit: ${quiz.timeLimitMinutes} minutes'),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _showEditQuizDialog(quiz);
                                        break;
                                      case 'toggle_publish':
                                        _togglePublishStatus(quiz);
                                        break;
                                      case 'delete':
                                        _deleteQuiz(quiz);
                                        break;
                                    }
                                  },
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
                                    PopupMenuItem(
                                      value: 'toggle_publish',
                                      child: Row(
                                        children: [
                                          Icon(quiz.isPublished ? Icons.unpublished : Icons.publish),
                                          const SizedBox(width: 8),
                                          Text(quiz.isPublished ? 'Unpublish' : 'Publish'),
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
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePublishStatus(Quiz quiz) {
    final updatedQuiz = quiz.copyWith(
      isPublished: !quiz.isPublished,
      updatedAt: DateTime.now(),
    );
    
    // Update in mock data
    final index = MockData.quizzes.indexWhere((q) => q.quizId == quiz.quizId);
    if (index != -1) {
      MockData.quizzes[index] = updatedQuiz;
      _loadQuizzesForCourse(selectedCourse!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quiz "${quiz.title}" ${updatedQuiz.isPublished ? 'published' : 'unpublished'} successfully',
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CreateQuizDialog extends StatefulWidget {
  final Course course;
  final VoidCallback onQuizCreated;

  const _CreateQuizDialog({
    required this.course,
    required this.onQuizCreated,
  });

  @override
  State<_CreateQuizDialog> createState() => _CreateQuizDialogState();
}

class _CreateQuizDialogState extends State<_CreateQuizDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int? _selectedTimeLimit;
  DateTime? _dueDate;
  bool _isPublished = false;

  final List<Map<String, dynamic>> _timeLimitOptions = [
    {'label': '30 minutes', 'value': 30},
    {'label': '1 hour', 'value': 60},
    {'label': '1 hour 30 minutes', 'value': 90},
    {'label': '2 hours', 'value': 120},
    {'label': '3 hours', 'value': 180},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Quiz'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              DropdownButtonFormField<int>(
                value: _selectedTimeLimit,
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
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
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
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Publish immediately'),
                value: _isPublished,
                onChanged: (value) {
                  setState(() {
                    _isPublished = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createQuiz,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createQuiz() {
    // Check if all required fields are filled
    if (_dueDate == null) {
      setState(() {}); // Trigger rebuild to show error
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      final newQuiz = Quiz(
        quizId: DateTime.now().millisecondsSinceEpoch,
        courseId: widget.course.courseId,
        title: _titleController.text.trim(),
        dueAt: _dueDate!,
        timeLimitMinutes: _selectedTimeLimit!,
        isPublished: _isPublished,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      MockData.quizzes.add(newQuiz);
      widget.onQuizCreated();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz "${newQuiz.title}" created successfully')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}

class _EditQuizDialog extends StatefulWidget {
  final Quiz quiz;
  final Course course;
  final VoidCallback onQuizUpdated;

  const _EditQuizDialog({
    required this.quiz,
    required this.course,
    required this.onQuizUpdated,
  });

  @override
  State<_EditQuizDialog> createState() => _EditQuizDialogState();
}

class _EditQuizDialogState extends State<_EditQuizDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late int? _selectedTimeLimit;
  late DateTime? _dueDate;
  late bool _isPublished;

  final List<Map<String, dynamic>> _timeLimitOptions = [
    {'label': '30 minutes', 'value': 30},
    {'label': '1 hour', 'value': 60},
    {'label': '1 hour 30 minutes', 'value': 90},
    {'label': '2 hours', 'value': 120},
    {'label': '3 hours', 'value': 180},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz.title);
    _selectedTimeLimit = widget.quiz.timeLimitMinutes;
    _dueDate = widget.quiz.dueAt;
    _isPublished = widget.quiz.isPublished;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Quiz'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              DropdownButtonFormField<int>(
                value: _selectedTimeLimit,
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
              const SizedBox(height: 16),
              InkWell(
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
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Published'),
                value: _isPublished,
                onChanged: (value) {
                  setState(() {
                    _isPublished = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateQuiz,
          child: const Text('Update'),
        ),
      ],
    );
  }

  void _updateQuiz() {
    // Check if all required fields are filled
    if (_dueDate == null) {
      setState(() {}); // Trigger rebuild to show error
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      final updatedQuiz = widget.quiz.copyWith(
        title: _titleController.text.trim(),
        dueAt: _dueDate!,
        timeLimitMinutes: _selectedTimeLimit!,
        isPublished: _isPublished,
        updatedAt: DateTime.now(),
      );

      // Update in mock data
      final index = MockData.quizzes.indexWhere((q) => q.quizId == widget.quiz.quizId);
      if (index != -1) {
        MockData.quizzes[index] = updatedQuiz;
        widget.onQuizUpdated();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz "${updatedQuiz.title}" updated successfully')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}