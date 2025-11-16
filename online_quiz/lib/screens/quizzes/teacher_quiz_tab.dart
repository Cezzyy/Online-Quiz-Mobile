import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/info_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/quiz_provider.dart';
import 'create_quiz_screen.dart';

class TeacherQuizTab extends ConsumerStatefulWidget {
  const TeacherQuizTab({super.key});

  @override
  ConsumerState<TeacherQuizTab> createState() => _TeacherQuizTabState();
}

class _TeacherQuizTabState extends ConsumerState<TeacherQuizTab> {
  Course? selectedCourse;
  List<Quiz> courseQuizzes = [];
  bool isLoading = false;
  bool isRefreshing = false;
  
  // Pagination variables
  int currentPage = 0;
  final int itemsPerPage = 10;
  
  List<Quiz> get paginatedQuizzes {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, courseQuizzes.length);
    return courseQuizzes.sublist(startIndex, endIndex);
  }
  
  int get totalPages => (courseQuizzes.length / itemsPerPage).ceil();
  bool get hasNextPage => currentPage < totalPages - 1;
  bool get hasPreviousPage => currentPage > 0;

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

  void _loadQuizzesForCourse(Course course) async {
    setState(() {
      selectedCourse = course;
      isLoading = true;
    });

    await ref.read(quizProvider.notifier).loadQuizzesForCourse(course.courseId);
    
    setState(() {
      courseQuizzes = ref.read(quizProvider).allQuizzes;
      currentPage = 0; // Reset to first page when loading new course
      isLoading = false;
    });
  }

  Future<void> _refreshQuizzes() async {
    if (selectedCourse == null) return;
    
    setState(() {
      isRefreshing = true;
    });
    
    await ref.read(quizProvider.notifier).loadQuizzesForCourse(selectedCourse!.courseId);
    
    setState(() {
      courseQuizzes = ref.read(quizProvider).allQuizzes;
      currentPage = 0; // Reset to first page after refresh
      isRefreshing = false;
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
          setState(() {
            currentPage = 0; // Reset to first page
          });
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
          setState(() {
            currentPage = 0; // Reset to first page
          });
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
            onPressed: () async {
              Navigator.pop(context);
              
              // Delete quiz using provider
              final success = await ref.read(quizProvider.notifier).deleteQuiz(quiz.quizId);
              
              if (success) {
                setState(() {
                  courseQuizzes = ref.read(quizProvider).allQuizzes;
                  currentPage = 0; // Reset to first page
                });
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Quiz "${quiz.title}" deleted successfully')),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ref.read(quizProvider).error ?? 'Failed to delete quiz'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _continueDraft(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateQuizScreen(
          course: selectedCourse!,
          quiz: quiz,
        ),
      ),
    ).then((_) {
      // Refresh the quiz list when returning from creation screen
      _loadQuizzesForCourse(selectedCourse!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final courseState = ref.watch(courseProvider);
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final teacherCourses = courseState.allCourses;

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
                      InfoCard(
                        icon: Icons.class_outlined,
                        title: 'Select Course',
                        value: 'No courses assigned to you.',
                        iconColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.all(16),
                        iconSize: 20,
                        titleFontSize: 12,
                        valueFontSize: 14,
                      )
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
                    onPressed: isRefreshing ? null : _refreshQuizzes,
                    icon: isRefreshing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(isRefreshing ? 'Refreshing...' : 'Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Quiz List
            Expanded(
              child: isRefreshing
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Refreshing courses...'),
                        ],
                      ),
                    )
                  : teacherCourses.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.class_outlined,
                      title: 'No Classes Assigned',
                      message: 'You don\'t have any classes assigned yet.',
                      subtitle: 'Contact your administrator to get courses assigned.',
                      showInfoCard: true,
                      infoCardText: 'If you recently received assignments, refresh to load them.',
                      action: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isRefreshing = true;
                          });
                          
                          await ref.read(courseProvider.notifier).initializeCourses(currentUser.userId);
                          
                          if (mounted) {
                            setState(() {
                              isRefreshing = false;
                            });
                          }
                        },
                        child: const Text('Refresh'),
                      ),
                    )
                  : selectedCourse == null
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
                          : isRefreshing
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Refreshing quizzes...'),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                // Pagination info
                                if (courseQuizzes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Showing ${currentPage * itemsPerPage + 1}-${((currentPage + 1) * itemsPerPage).clamp(0, courseQuizzes.length)} of ${courseQuizzes.length} quizzes',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        if (totalPages > 1)
                                          Text(
                                            'Page ${currentPage + 1} of $totalPages',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                
                                // Quiz list
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: paginatedQuizzes.length,
                                    itemBuilder: (context, index) {
                                      final quiz = paginatedQuizzes[index];
                                      // Question count will be fetched when needed
                                      
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
                                              FutureBuilder<int>(
                                                future: ref.read(quizProvider.notifier).getQuestionCount(quiz.quizId),
                                                builder: (context, snapshot) {
                                                  final count = snapshot.data ?? 0;
                                                  return Text('$count questions');
                                                },
                                              ),
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
                                                case 'continue_draft':
                                                  _continueDraft(quiz);
                                                  break;
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
                                              if (!quiz.isPublished)
                                                const PopupMenuItem(
                                                  value: 'continue_draft',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit_note, color: Colors.blue),
                                                      SizedBox(width: 8),
                                                      Text('Continue Draft', style: TextStyle(color: Colors.blue)),
                                                    ],
                                                  ),
                                                ),
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
                                
                                // Pagination controls
                                if (totalPages > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: hasPreviousPage
                                              ? () {
                                                  setState(() {
                                                    currentPage--;
                                                  });
                                                }
                                              : null,
                                          icon: const Icon(Icons.chevron_left),
                                          tooltip: 'Previous page',
                                        ),
                                        const SizedBox(width: 8),
                                        ...List.generate(totalPages, (index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  currentPage = index;
                                                });
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: currentPage == index
                                                      ? Theme.of(context).primaryColor
                                                      : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: currentPage == index
                                                        ? Theme.of(context).primaryColor
                                                        : Colors.grey.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: TextStyle(
                                                      color: currentPage == index
                                                          ? Colors.white
                                                          : Theme.of(context).textTheme.bodyMedium?.color,
                                                      fontWeight: currentPage == index
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: hasNextPage
                                              ? () {
                                                  setState(() {
                                                    currentPage++;
                                                  });
                                                }
                                              : null,
                                          icon: const Icon(Icons.chevron_right),
                                          tooltip: 'Next page',
                                        ),
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

  Future<void> _togglePublishStatus(Quiz quiz) async {
    // Toggle publish status using provider
    final success = await ref.read(quizProvider.notifier).togglePublishQuiz(
      quiz.quizId,
      !quiz.isPublished,
    );
    
    if (success) {
      setState(() {
        courseQuizzes = ref.read(quizProvider).allQuizzes;
        currentPage = 0; // Reset to first page
      });
    }
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quiz "${quiz.title}" ${!quiz.isPublished ? 'published' : 'unpublished'} successfully',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(quizProvider).error ?? 'Failed to toggle publish status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CreateQuizDialog extends ConsumerStatefulWidget {
  final Course course;
  final VoidCallback onQuizCreated;

  const _CreateQuizDialog({
    required this.course,
    required this.onQuizCreated,
  });

  @override
  ConsumerState<_CreateQuizDialog> createState() => _CreateQuizDialogState();
}

class _CreateQuizDialogState extends ConsumerState<_CreateQuizDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int? _selectedTimeLimit;
  DateTime? _dueDate;

  final List<Map<String, dynamic>> _timeLimitOptions = [
    {'label': '30 min', 'value': 30},
    {'label': '1 hour', 'value': 60},
    {'label': '1.5 hours', 'value': 90},
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

  Future<void> _createQuiz() async {
    // Check if all required fields are filled
    if (_dueDate == null) {
      setState(() {}); // Trigger rebuild to show error
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      // Create the quiz using provider
      final createdQuiz = await ref.read(quizProvider.notifier).createQuiz(
        courseId: widget.course.courseId,
        title: _titleController.text.trim(),
        createdBy: widget.course.instructorUserId,
        dueAt: _dueDate,
        timeLimitMinutes: _selectedTimeLimit,
        isPublished: false,
      );
      
      if (!mounted) return;
      
      if (createdQuiz == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(quizProvider).error ?? 'Failed to create quiz'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Close the dialog and navigate
      Navigator.pop(context);
      
      // Navigate to the quiz creation screen with the created quiz
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateQuizScreen(
            course: widget.course,
            quiz: createdQuiz,
          ),
        ),
      ).then((_) {
        // Refresh the quiz list when returning from creation screen
        widget.onQuizCreated();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}

class _EditQuizDialog extends ConsumerStatefulWidget {
  final Quiz quiz;
  final Course course;
  final VoidCallback onQuizUpdated;

  const _EditQuizDialog({
    required this.quiz,
    required this.course,
    required this.onQuizUpdated,
  });

  @override
  ConsumerState<_EditQuizDialog> createState() => _EditQuizDialogState();
}

class _EditQuizDialogState extends ConsumerState<_EditQuizDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late int? _selectedTimeLimit;
  late DateTime? _dueDate;
  late bool _isPublished;

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

  Future<void> _updateQuiz() async {
    // Check if all required fields are filled
    if (_dueDate == null) {
      setState(() {}); // Trigger rebuild to show error
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      // Update using provider
      final success = await ref.read(quizProvider.notifier).updateQuiz(
        quizId: widget.quiz.quizId,
        title: _titleController.text.trim(),
        dueAt: _dueDate,
        timeLimitMinutes: _selectedTimeLimit,
        isPublished: _isPublished,
      );
      
      if (!mounted) return;
      
      if (success) {
        widget.onQuizUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz "${_titleController.text}" updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(quizProvider).error ?? 'Failed to update quiz'),
            backgroundColor: Colors.red,
          ),
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