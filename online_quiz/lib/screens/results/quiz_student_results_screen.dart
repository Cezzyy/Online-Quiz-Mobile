import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attempt.dart';
import '../../models/attempt_answer.dart';
import '../../models/choice.dart';
import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../models/question.dart';
import '../../models/quiz.dart';
import '../../models/student.dart';
import '../../models/user.dart';
import '../../providers/export_import_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/quiz_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/stat_card.dart';

class QuizStudentResultsScreen extends ConsumerStatefulWidget {
  final Quiz quiz;
  final Course course;

  const QuizStudentResultsScreen({
    super.key,
    required this.quiz,
    required this.course,
  });

  @override
  ConsumerState<QuizStudentResultsScreen> createState() => _QuizStudentResultsScreenState();
}

class _QuizStudentResultsScreenState extends ConsumerState<QuizStudentResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final QuizService _quizService = QuizService();
  final AnalyticsService _analyticsService = AnalyticsService();
  String _searchQuery = '';
  String? _selectedSection;
  List<String> _sections = [];
  String _viewMode = 'all'; // 'all' or 'scores_only'
  bool _isTableView = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _enrolledStudents = [];
  List<Map<String, dynamic>> _quizAttempts = [];
  double _totalPoints = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courseNotifier = ref.read(courseProvider.notifier);
      
      // Load enrolled students with details
      final enrolled = await courseNotifier.getEnrolledStudentsWithDetails(widget.course.courseId);
      
      // Load quiz attempts
      final attempts = await _analyticsService.getAttemptsByQuiz(widget.quiz.quizId);
      
      // Load quiz questions and calculate total points
      final questions = await _quizService.getQuizQuestions(widget.quiz.quizId);
      final totalPoints = questions.fold(0.0, (sum, q) => sum + q.points);
      
      // Extract unique sections from enrolled students
      final sections = <String>{};
      for (final studentData in enrolled) {
        final student = studentData['student'] as Student?;
        if (student?.section != null && student!.section!.isNotEmpty) {
          sections.add(student.section!);
        }
      }
      
      final sortedSections = sections.toList()..sort();
      
      if (mounted) {
        setState(() {
          _enrolledStudents = enrolled;
          _quizAttempts = attempts;
          _totalPoints = totalPoints;
          _sections = sortedSections;
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
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<StudentQuizResult> _getFilteredResults() {
    // Create student results from loaded data
    List<StudentQuizResult> results = [];
    
    for (final studentData in _enrolledStudents) {
      final student = studentData['student'] as Student;
      final user = studentData['user'] as User;
      final enrollment = studentData['enrollment'] as Enrollment;
      
      // Find attempts for this student
      final studentAttempts = _quizAttempts
          .where((attemptData) {
            final attempt = attemptData['attempt'] as Attempt;
            return attempt.userId == student.userId;
          })
          .toList();
      
      // Get the best attempt (highest score)
      Attempt? bestAttempt;
      if (studentAttempts.isNotEmpty) {
        final bestAttemptData = studentAttempts.reduce((a, b) {
          final attemptA = a['attempt'] as Attempt;
          final attemptB = b['attempt'] as Attempt;
          return attemptA.score > attemptB.score ? a : b;
        });
        
        bestAttempt = bestAttemptData['attempt'] as Attempt;
      }

      results.add(StudentQuizResult(
        student: student,
        user: user,
        enrollment: enrollment,
        attempt: bestAttempt,
        quiz: widget.quiz,
        totalPoints: _calculateTotalPoints(),
      ));
    }

    // Apply filters
    if (_viewMode == 'scores_only') {
      results = results.where((r) => r.attempt != null).toList();
    }

    if (_selectedSection != null && _selectedSection!.isNotEmpty) {
      results = results.where((r) => r.student.section == _selectedSection).toList();
    }

    if (_searchQuery.isNotEmpty) {
      results = results.where((r) {
        final fullName = r.user.fullName.toLowerCase();
        final studentId = r.student.studentId.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return fullName.contains(query) || studentId.contains(query);
      }).toList();
    }

    // Sort by score (highest first), then by name
    results.sort((a, b) {
      if (a.attempt != null && b.attempt != null) {
        final scoreComparison = b.attempt!.score.compareTo(a.attempt!.score);
        if (scoreComparison != 0) return scoreComparison;
      } else if (a.attempt != null) {
        return -1;
      } else if (b.attempt != null) {
        return 1;
      }
      
      return a.user.fullName.compareTo(b.user.fullName);
    });

    return results;
  }

  Future<void> _exportToExcel() async {
    final results = _getFilteredResults().where((r) => r.attempt != null).toList();
    
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No scores available to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exporting to Excel...'),
          ],
        ),
      ),
    );

    try {
      // Convert StudentQuizResult objects to the map format expected by the provider
       final resultsData = results.map((result) => {
         'studentName': result.user.fullName,
         'studentId': result.student.studentId,
         'section': result.student.section ?? 'N/A',
         'score': result.attempt!.score,
         'totalPoints': result.getTotalPoints(),
         'percentage': result.getPercentage(),
         'submittedAt': result.attempt!.submittedAt,
         'hasAttempt': true, // Since we're filtering for results with attempts
       }).toList();

      // Get current user ID from auth provider
      final authState = ref.read(authProvider);
      final userId = authState.user?.userId;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use the export provider to create Excel file
      final exportProvider = ref.read(exportImportProvider.notifier);
      final filePath = await exportProvider.exportSimplifiedResultsToExcel(
          results: resultsData,
          quizTitle: widget.quiz.title,
          courseName: widget.course.name,
          userId: userId,
        );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (filePath != null) {
        // Show success message
        if (mounted) {
          final fileName = filePath.split('/').last;
          final isAndroid = Platform.isAndroid;
          final locationText = isAndroid ? 'Downloads folder' : 'Documents folder';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Excel file exported successfully!\nFile: $fileName\nLocation: $locationText'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        // Show error message
        final exportState = ref.read(exportImportProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(exportState.errorMessage ?? 'Failed to export Excel file'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting Excel file: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildTableView(List<StudentQuizResult> results) {
    final scoresOnly = results.where((r) => r.attempt != null).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
             headingRowColor: WidgetStateProperty.all(
               Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
             ),
             columns: const [
               DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
               DataColumn(label: Text('Section', style: TextStyle(fontWeight: FontWeight.bold))),
               DataColumn(label: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
             ],
            rows: scoresOnly.map((result) {
               return DataRow(
                 cells: [
                   DataCell(
                     Text(
                       result.user.fullName,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   DataCell(Text(result.student.section ?? 'N/A')),
                   DataCell(
                     Text(
                       result.attempt!.score.toStringAsFixed(1),
                       style: const TextStyle(fontWeight: FontWeight.bold),
                     ),
                   ),
                 ],
               );
            }).toList(),
          ),
        ),
      ),
    );
  }

  double _calculateTotalPoints() {
    return _totalPoints;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.quiz.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final results = _getFilteredResults();
    final totalStudents = _enrolledStudents.length;
    final completedStudents = results.where((r) => r.attempt != null).length;
    final averageScore = results.where((r) => r.attempt != null).isNotEmpty
        ? results
            .where((r) => r.attempt != null)
            .map((r) => r.getPercentage())
            .reduce((a, b) => a + b) / completedStudents
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Students',
                    value: totalStudents.toString(),
                    icon: Icons.people_outline,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Completed',
                    value: completedStudents.toString(),
                    icon: Icons.assignment_turned_in_outlined,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Avg Score',
                    value: '${averageScore.round()}%',
                    icon: Icons.analytics_outlined,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSection,
                        decoration: InputDecoration(
                          hintText: 'Section',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Sections', overflow: TextOverflow.ellipsis),
                          ),
                          ..._sections.map((section) {
                            return DropdownMenuItem<String>(
                              value: section,
                              child: Text(section, overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSection = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _viewMode,
                        decoration: InputDecoration(
                          labelText: 'View Mode',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'all',
                            child: Text('All Students'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'scores_only',
                            child: Text('Scores Only'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _viewMode = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _viewMode == 'scores_only' ? _exportToExcel : null,
                              icon: const Icon(Icons.file_download, size: 18),
                              label: const Text('Export Excel'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _viewMode == 'scores_only' ? () {
                        setState(() {
                          _isTableView = !_isTableView;
                        });
                      } : null,
                      icon: Icon(_isTableView ? Icons.view_list : Icons.table_chart),
                      tooltip: _isTableView ? 'List View' : 'Table View',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Results List
          Expanded(
            child: results.isEmpty
                ? EmptyStateWidget(
                    icon: _viewMode == 'scores_only' ? Icons.assignment_outlined : Icons.people_outline,
                    title: _viewMode == 'scores_only' ? 'No Scores Found' : 'No Students Found',
                    message: _viewMode == 'scores_only'
                        ? 'No students have submitted quiz attempts yet.'
                        : _searchQuery.isNotEmpty || _selectedSection != null
                            ? 'No students match your search criteria.'
                            : 'No students are enrolled in this course.',
                  )
                : _viewMode == 'scores_only' && _isTableView
                    ? _buildTableView(results)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return _buildStudentResultCard(result, index + 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentResultCard(StudentQuizResult result, int rank) {
    final hasAttempt = result.attempt != null;
    final percentage = hasAttempt ? result.getPercentage() : 0.0;
    
    Color scoreColor;
    IconData statusIcon;
    String statusText;
    
    if (!hasAttempt) {
      scoreColor = Colors.grey;
      statusIcon = Icons.pending_outlined;
      statusText = 'Not Attempted';
    } else if (percentage >= 90) {
      scoreColor = Colors.green;
      statusIcon = Icons.star;
      statusText = 'Excellent';
    } else if (percentage >= 75) {
      scoreColor = Colors.blue;
      statusIcon = Icons.thumb_up;
      statusText = 'Good';
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
      statusIcon = Icons.trending_up;
      statusText = 'Fair';
    } else {
      scoreColor = Colors.red;
      statusIcon = Icons.trending_down;
      statusText = 'Poor';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: scoreColor.withValues(alpha: 0.1),
          child: hasAttempt
              ? Text(
                  '#$rank',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              : Icon(
                  statusIcon,
                  color: scoreColor,
                  size: 20,
                ),
        ),
        title: Text(
          result.user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('ID: ${result.student.studentId}'),
            Text('Section: ${result.student.section ?? 'N/A'}'),
            if (hasAttempt) ...[
              Text('Score: ${result.attempt!.score.toStringAsFixed(1)} / ${result.getTotalPoints().toStringAsFixed(1)}'),
              Text('Submitted: ${_formatDate(result.attempt!.submittedAt!)}'),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasAttempt ? '${percentage.toStringAsFixed(1)}%' : statusText,
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (hasAttempt) ...[
              const SizedBox(height: 4),
              Text(
                statusText,
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        onTap: hasAttempt
            ? () {
                // Navigate to detailed student result
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizStudentDetailScreen(
                      quiz: widget.quiz,
                      course: widget.course,
                      student: result.student,
                      user: result.user,
                      attempt: result.attempt!,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class StudentQuizResult {
  final Student student;
  final User user;
  final Enrollment enrollment;
  final Attempt? attempt;
  final Quiz quiz;
  final double totalPoints;

  StudentQuizResult({
    required this.student,
    required this.user,
    required this.enrollment,
    required this.attempt,
    required this.quiz,
    required this.totalPoints,
  });

  double getPercentage() {
    if (attempt == null) return 0.0;
    return totalPoints > 0 ? (attempt!.score / totalPoints) * 100 : 0.0;
  }

  double getTotalPoints() {
    return totalPoints;
  }
}

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
        
        // Determine if question is correct
        bool isCorrect = false;
        double pointsEarned = 0.0;
        
        if (questionAnswers.isNotEmpty) {
          if (question.type == QuestionType.multiple) {
            final correctChoices = choices.where((c) => c.isCorrect).toList();
            final selectedCorrectChoices = questionAnswers.where((a) => a.isCorrect == true).toList();
            final selectedIncorrectChoices = questionAnswers.where((a) => a.isCorrect == false).toList();
            isCorrect = selectedCorrectChoices.length == correctChoices.length && selectedIncorrectChoices.isEmpty;
          } else {
            isCorrect = questionAnswers.any((a) => a.isCorrect == true);
          }
          
          if (isCorrect) {
            pointsEarned = question.points;
          }
        }

        results.add({
          'question': question,
          'answers': questionAnswers,
          'choices': choices,
          'isCorrect': isCorrect,
          'pointsEarned': pointsEarned,
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
    final percentage = _totalPoints > 0 ? (widget.attempt.score / _totalPoints) * 100 : 0.0;
    
    Color scoreColor;
    if (percentage >= 90) {
      scoreColor = Colors.green;
    } else if (percentage >= 75) {
      scoreColor = Colors.blue;
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Text(widget.user.fullName),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScoreHeader(context, percentage, scoreColor),
                  const SizedBox(height: 16),
                  _buildStudentInfo(context),
                  const SizedBox(height: 16),
                  _buildQuizInfo(context),
                  const SizedBox(height: 16),
                  _buildQuestionResults(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildScoreHeader(BuildContext context, double percentage, Color scoreColor) {
    final correctCount = _questionResults.where((r) => r['isCorrect'] == true).length;
    final totalQuestions = _questionResults.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withValues(alpha: 0.8), scoreColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.grade, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            '${percentage.round()}%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '${widget.attempt.score.round()} / ${_totalPoints.round()} points',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$correctCount out of $totalQuestions correct',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person, 'Name', widget.user.fullName),
          _buildInfoRow(Icons.email, 'Email', widget.user.email),
          _buildInfoRow(Icons.badge, 'Student ID', widget.student.studentId),
          if (widget.student.section != null && widget.student.section!.isNotEmpty)
            _buildInfoRow(Icons.class_, 'Section', widget.student.section!),
        ],
      ),
    );
  }

  Widget _buildQuizInfo(BuildContext context) {
    final submittedAt = widget.attempt.submittedAt;
    final timeSpent = widget.attempt.timeSpentSeconds;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.quiz, 'Quiz', widget.quiz.title),
          _buildInfoRow(Icons.book, 'Course', '${widget.course.code} - ${widget.course.name}'),
          if (submittedAt != null)
            _buildInfoRow(Icons.calendar_today, 'Submitted', _formatDateTime(submittedAt)),
          if (timeSpent != null)
            _buildInfoRow(Icons.timer, 'Time Spent', _formatDuration(timeSpent)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionResults(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question by Question Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ..._questionResults.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            return _buildQuestionCard(context, index + 1, result);
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, int questionNumber, Map<String, dynamic> result) {
    final question = result['question'] as Question;
    final answers = result['answers'] as List<AttemptAnswer>;
    final choices = result['choices'] as List<Choice>;
    final isCorrect = result['isCorrect'] as bool;
    final pointsEarned = result['pointsEarned'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Question $questionNumber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${pointsEarned.round()} / ${question.points.round()} pts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.body,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnswerSection(context, question, answers, choices),
        ],
      ),
    );
  }

  Widget _buildAnswerSection(BuildContext context, Question question, List<AttemptAnswer> answers, List<Choice> choices) {
    if (answers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text('Not answered', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    if (question.type == QuestionType.text) {
      final answer = answers.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Answer:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              answer.freeText ?? 'No answer provided',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      );
    }

    // For single and multiple choice
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choices:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor ?? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected || isCorrectChoice ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: borderColor,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    choice.body,
                    style: TextStyle(
                      fontSize: 14,
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