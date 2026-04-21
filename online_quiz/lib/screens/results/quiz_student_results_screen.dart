import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attempt.dart';
import '../../models/attempt_answer.dart';
import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../models/quiz.dart';
import '../../models/student.dart';
import '../../models/user.dart';
import '../../providers/export_import_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/quiz_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/app_theme.dart';
import 'quiz_student_detail_screen.dart';

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

  double _calculateTotalPoints() {
    return _totalPoints;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header Section with Gradient
              _buildHeader(context, totalStudents, completedStudents, averageScore),
              const SizedBox(height: 24),
              
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Filters Section
                    _buildFiltersSection(context, isDark),
                    
                    const SizedBox(height: 16),
                    
                    // View Analytics Button
                    _buildViewAnalyticsButton(context, totalStudents, completedStudents, averageScore),
                    
                    const SizedBox(height: 16),
                    
                    // Results List
                    results.isEmpty
                        ? _buildEmptyState(context)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student Results',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...results.asMap().entries.map((entry) {
                                return _buildStudentResultCard(entry.value, entry.key + 1, isDark);
                              }),
                            ],
                          ),
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

  Widget _buildHeader(BuildContext context, int totalStudents, int completedStudents, double averageScore) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight < 700 ? 240.0 : 260.0;
    
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
        // Content
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
        Positioned(
          top: MediaQuery.of(context).padding.top + 40,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz,
                color: Colors.white,
                size: screenHeight < 700 ? 40 : 48,
              ),
              SizedBox(height: screenHeight < 700 ? 12 : 16),
              Text(
                widget.quiz.title,
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
                  '$completedStudents/$totalStudents Completed • Avg: ${averageScore.round()}%',
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

  Widget _buildViewAnalyticsButton(BuildContext context, int totalStudents, int completedStudents, double averageScore) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAnalyticsBottomSheet(context, totalStudents, completedStudents, averageScore),
        icon: const Icon(Icons.analytics_outlined),
        label: const Text('View Analytics'),
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

  void _showAnalyticsBottomSheet(BuildContext context, int totalStudents, int completedStudents, double averageScore) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pendingStudents = totalStudents - completedStudents;
    final completionRate = totalStudents > 0 ? (completedStudents / totalStudents) * 100 : 0.0;
    
    // Calculate grade distribution
    final results = _getFilteredResults().where((r) => r.attempt != null).toList();
    int excellentCount = 0;
    int goodCount = 0;
    int fairCount = 0;
    int poorCount = 0;
    
    for (final result in results) {
      final percentage = result.getPercentage();
      if (percentage >= 90) {
        excellentCount++;
      } else if (percentage >= 75) {
        goodCount++;
      } else if (percentage >= 60) {
        fairCount++;
      } else {
        poorCount++;
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
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
                        Icons.analytics,
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
                            'Quiz Analytics',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Detailed performance overview',
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
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Stats Cards
                      Text(
                        'Overview',
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildOverviewRow(
                              context,
                              Icons.people,
                              'Total Students',
                              totalStudents.toString(),
                              Colors.blue,
                            ),
                            const Divider(height: 24),
                            _buildOverviewRow(
                              context,
                              Icons.check_circle,
                              'Completed',
                              completedStudents.toString(),
                              Colors.green,
                            ),
                            const Divider(height: 24),
                            _buildOverviewRow(
                              context,
                              Icons.pending,
                              'Pending',
                              pendingStudents.toString(),
                              Colors.orange,
                            ),
                            const Divider(height: 24),
                            _buildOverviewRow(
                              context,
                              Icons.star,
                              'Average Score',
                              '${averageScore.toStringAsFixed(1)}%',
                              averageScore >= 75 ? Colors.green : (averageScore >= 50 ? Colors.blue : Colors.red),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Completion Progress
                      Text(
                        'Completion Progress',
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Completion Rate',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${completionRate.toStringAsFixed(1)}%',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: completionRate >= 80 ? Colors.green : (completionRate >= 50 ? Colors.blue : Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: completionRate / 100,
                                minHeight: 12,
                                backgroundColor: isDark 
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  completionRate >= 80 ? Colors.green : (completionRate >= 50 ? Colors.blue : Colors.orange),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$completedStudents completed',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  '$pendingStudents pending',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Grade Distribution
                      if (results.isNotEmpty) ...[
                        Text(
                          'Grade Distribution',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildGradeDistributionBar(
                          context,
                          'Excellent (90-100%)',
                          excellentCount,
                          completedStudents,
                          Colors.green,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildGradeDistributionBar(
                          context,
                          'Good (75-89%)',
                          goodCount,
                          completedStudents,
                          Colors.blue,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildGradeDistributionBar(
                          context,
                          'Fair (60-74%)',
                          fairCount,
                          completedStudents,
                          Colors.orange,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildGradeDistributionBar(
                          context,
                          'Poor (<60%)',
                          poorCount,
                          completedStudents,
                          Colors.red,
                          isDark,
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                      
                      // Additional Stats
                      Text(
                        'Additional Statistics',
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              context,
                              Icons.quiz,
                              'Quiz Title',
                              widget.quiz.title,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              context,
                              Icons.book,
                              'Course',
                              '${widget.course.code} - ${widget.course.name}',
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              context,
                              Icons.assignment,
                              'Total Points',
                              _totalPoints.toStringAsFixed(1),
                            ),
                            if (widget.quiz.dueAt != null) ...[
                              const Divider(height: 24),
                              _buildDetailRow(
                                context,
                                Icons.calendar_today,
                                'Due Date',
                                _formatDateTime(widget.quiz.dueAt!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGradeDistributionBar(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
    bool isDark,
  ) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count students (${percentage.toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
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

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildFiltersSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filters & Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search
            TextField(
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
            const SizedBox(height: 12),
            // Section and View Mode
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSection,
                    decoration: InputDecoration(
                      labelText: 'Section',
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
                const SizedBox(width: 12),
                Expanded(
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
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.file_download, size: 18),
                    label: const Text('Export Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                _viewMode == 'scores_only' ? Icons.assignment_outlined : Icons.people_outline,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _viewMode == 'scores_only' ? 'No Scores Found' : 'No Students Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _viewMode == 'scores_only'
                  ? 'No students have submitted quiz attempts yet.'
                  : _searchQuery.isNotEmpty || _selectedSection != null
                      ? 'No students match your search criteria.'
                      : 'No students are enrolled in this course.',
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

  Widget _buildStudentResultCard(StudentQuizResult result, int rank, bool isDark) {
    final theme = Theme.of(context);
    final hasAttempt = result.attempt != null;

    if (!hasAttempt) {
      // No attempt - show N/A
      return Card(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pending_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.user.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          result.student.studentId,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        if (result.student.section != null && result.student.section!.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            result.student.section!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'N/A',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      );
    }

    // Has attempt - use FutureBuilder to check for pending questions
    return FutureBuilder<List<AttemptAnswer>>(
      future: _quizService.getAttemptAnswers(result.attempt!.attemptId),
      builder: (context, snapshot) {
        final percentage = result.getPercentage();
        bool needsGrading = false;
        
        if (snapshot.hasData) {
          needsGrading = snapshot.data!.any((a) => a.needsGrading);
        }
        
        // Determine status based on pending grading or score
        Color scoreColor;
        IconData statusIcon;
        String statusBadge;
        
        if (needsGrading) {
          // Has pending questions - show orange pending status
          scoreColor = Colors.orange;
          statusIcon = Icons.pending;
          statusBadge = 'Pending';
        } else if (percentage >= 90) {
          scoreColor = Colors.green;
          statusIcon = Icons.trending_up;
          statusBadge = '${percentage.toStringAsFixed(0)}%';
        } else if (percentage >= 75) {
          scoreColor = Colors.blue;
          statusIcon = Icons.trending_flat;
          statusBadge = '${percentage.toStringAsFixed(0)}%';
        } else if (percentage >= 60) {
          scoreColor = Colors.orange;
          statusIcon = Icons.trending_flat;
          statusBadge = '${percentage.toStringAsFixed(0)}%';
        } else {
          scoreColor = Colors.red;
          statusIcon = Icons.trending_down;
          statusBadge = '${percentage.toStringAsFixed(0)}%';
        }

        return Card(
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
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
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Status Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusIcon,
                      color: scoreColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Student Info
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.user.fullName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                result.student.studentId,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (result.student.section != null && result.student.section!.isNotEmpty) ...[
                              Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.5),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  result.student.section!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark 
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : Colors.black.withValues(alpha: 0.5),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '${result.attempt!.score.toStringAsFixed(1)}/${result.getTotalPoints().toStringAsFixed(1)} pts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Score Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scoreColor,
                      ),
                    ),
                  ),
                  
                  // Arrow
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
