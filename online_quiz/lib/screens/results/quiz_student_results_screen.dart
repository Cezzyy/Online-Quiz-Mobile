import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/attempt.dart';
import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../models/quiz.dart';
import '../../models/student.dart';
import '../../models/user.dart';
import '../../providers/export_import_provider.dart';
import '../../providers/auth_provider.dart';
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
  String _searchQuery = '';
  String? _selectedSection;
  List<String> _sections = [];
  String _viewMode = 'all'; // 'all' or 'scores_only'
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSections() {
    // Get all enrollments for this course
    final enrollments = MockData.enrollments
        .where((e) => e.courseId == widget.course.courseId)
        .toList();
    
    // Get students for these enrollments and extract unique sections
    final sections = <String>{};
    for (final enrollment in enrollments) {
      final student = MockData.students
          .where((s) => s.userId == enrollment.userId)
          .firstOrNull;
      if (student?.section != null && student!.section!.isNotEmpty) {
        sections.add(student.section!);
      }
    }
    
    final sortedSections = sections.toList()..sort();
    
    setState(() {
      _sections = sortedSections;
    });
  }

  List<StudentQuizResult> _getFilteredResults() {
    // Get all attempts for this quiz
    final attempts = MockData.attempts
        .where((a) => a.quizId == widget.quiz.quizId && a.submittedAt != null)
        .toList();

    // Get all enrollments for this course
    final enrollments = MockData.enrollments
        .where((e) => e.courseId == widget.course.courseId)
        .toList();

    // Create student results
    List<StudentQuizResult> results = [];
    
    for (final enrollment in enrollments) {
      final student = MockData.students
          .where((s) => s.userId == enrollment.userId)
          .firstOrNull;
      
      final user = MockData.users
          .where((u) => u.userId == enrollment.userId)
          .firstOrNull;
      
      if (student != null && user != null) {
        final studentAttempts = attempts
            .where((a) => a.userId == student.userId)
            .toList();
        
        // Get the best attempt (highest score)
        Attempt? bestAttempt;
        if (studentAttempts.isNotEmpty) {
          bestAttempt = studentAttempts.reduce((a, b) => a.score > b.score ? a : b);
        }

        results.add(StudentQuizResult(
          student: student,
          user: user,
          enrollment: enrollment,
          attempt: bestAttempt,
          quiz: widget.quiz,
        ));
      }
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

  @override
  Widget build(BuildContext context) {
    final results = _getFilteredResults();
    final totalStudents = MockData.enrollments
        .where((e) => e.courseId == widget.course.courseId)
        .length;
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
                    value: '${averageScore.toStringAsFixed(1)}%',
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

  StudentQuizResult({
    required this.student,
    required this.user,
    required this.enrollment,
    required this.attempt,
    required this.quiz,
  });

  double getPercentage() {
    if (attempt == null) return 0.0;
    final totalPoints = getTotalPoints();
    return totalPoints > 0 ? (attempt!.score / totalPoints) * 100 : 0.0;
  }

  double getTotalPoints() {
    final questions = MockData.questions.where((q) => q.quizId == quiz.quizId).toList();
    return questions.fold(0.0, (sum, q) => sum + q.points);
  }
}

// Placeholder for detailed student result screen
class QuizStudentDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.fullName),
      ),
      body: const Center(
        child: Text('Detailed student result view - To be implemented'),
      ),
    );
  }
}