import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz.dart';
import '../../models/course.dart';
import '../../models/attempt.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../quizzes/quiz_result_screen.dart';
import '../../widgets/filter_tab_widget.dart';
import '../../widgets/results_skeleton_loader.dart';

class ResultsTab extends ConsumerStatefulWidget {
  const ResultsTab({super.key});

  @override
  ConsumerState<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends ConsumerState<ResultsTab> {
  String _selectedFilter = 'All';
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  List<QuizResultWithDetails> _allResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load results once when the widget is first created
    Future.microtask(() async {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        // Ensure quiz data is initialized
        await ref.read(quizProvider.notifier).initializeQuizzes(authState.user!.userId);
        // Load all results once
        final results = await _getAllQuizResults();
        if (mounted) {
          setState(() {
            _allResults = results;
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _refreshResults() async {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      setState(() {
        _isLoading = true;
      });
      
      // Refresh quiz data
      await ref.read(quizProvider.notifier).refreshQuizzes(authState.user!.userId);
      
      // Reload results
      final results = await _getAllQuizResults();
      
      if (mounted) {
        setState(() {
          _allResults = results;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while data is being fetched
    if (_isLoading) {
      return const ResultsSkeletonLoader();
    }

    // Filter results locally without reloading
    final filteredResults = _getFilteredResults(_allResults);
    final totalPages = filteredResults.isEmpty ? 1 : (filteredResults.length / _itemsPerPage).ceil();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshResults,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildHeader(_allResults),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (_allResults.isNotEmpty) _buildFilterTabs(),
                    if (_allResults.isNotEmpty) const SizedBox(height: 16),
                    _allResults.isEmpty
                        ? _buildEmptyState()
                        : _buildResultsList(filteredResults, totalPages),
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

  Widget _buildHeader(List<QuizResultWithDetails> allResults) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight < 700 ? 200.0 : 220.0;
    
    final totalQuizzes = allResults.length;
    final averageScore = totalQuizzes > 0 
        ? allResults.map((r) => r.percentage).reduce((a, b) => a + b) / totalQuizzes
        : 0.0;
    
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
          top: MediaQuery.of(context).padding.top + 30,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics,
                color: Colors.white,
                size: screenHeight < 700 ? 40 : 48,
              ),
              SizedBox(height: screenHeight < 700 ? 12 : 16),
              Text(
                'Quiz Results',
                style: TextStyle(
                  fontSize: screenHeight < 700 ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalQuizzes ${totalQuizzes == 1 ? 'Result' : 'Results'} - ${averageScore.round()}% Average',
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

  Widget _buildFilterTabs() {
    final filters = ['All', 'Excellent', 'Good', 'Fair', 'Poor'];
    
    return FilterTabPresets.quizStyle(
      context: context,
      options: filters,
      selectedFilter: _selectedFilter,
      onFilterChanged: (filter) {
        setState(() {
          _selectedFilter = filter;
          _currentPage = 0;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No quiz results yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete quizzes to see your results here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List<QuizResultWithDetails> results, int totalPages) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No ${_selectedFilter.toLowerCase()} results found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try selecting a different filter',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final paginatedResults = _getPaginatedResults(results);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: paginatedResults.length,
          itemBuilder: (context, index) {
            return _buildResultCard(paginatedResults[index]);
          },
        ),
        if (results.length > _itemsPerPage) _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildResultCard(QuizResultWithDetails resultDetails) {
    final attempt = resultDetails.attempt;
    final quiz = resultDetails.quiz;
    final course = resultDetails.course;
    final percentage = resultDetails.percentage;
    
    Color scoreColor;
    String grade;
    IconData gradeIcon;
    
    if (percentage >= 90) {
      scoreColor = Colors.green;
      grade = 'Excellent';
      gradeIcon = Icons.star;
    } else if (percentage >= 75) {
      scoreColor = Colors.blue;
      grade = 'Good';
      gradeIcon = Icons.thumb_up;
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
      grade = 'Fair';
      gradeIcon = Icons.trending_up;
    } else {
      scoreColor = Colors.red;
      grade = 'Poor';
      gradeIcon = Icons.trending_down;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: quiz,
              course: course,
              attempt: attempt,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with score
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      gradeIcon,
                      color: scoreColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.code} - ${course.name}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        grade,
                        style: TextStyle(
                          fontSize: 12,
                          color: scoreColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Score details
              _buildInfoRow(
                Icons.check_circle_outline,
                'Score',
                '${resultDetails.correctAnswers}/${resultDetails.totalQuestions}',
              ),
              _buildDivider(context),
              _buildInfoRow(
                Icons.access_time,
                'Time',
                _formatTimeSpent((attempt.timeSpentSeconds ?? 0) ~/ 60),
              ),
              _buildDivider(context),
              _buildInfoRow(
                Icons.calendar_today,
                'Completed',
                _formatDate(attempt.submittedAt!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      height: 16,
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? () {
              setState(() {
                _currentPage--;
              });
            } : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${_currentPage + 1} / $totalPages',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          IconButton(
            onPressed: _currentPage < totalPages - 1 ? () {
              setState(() {
                _currentPage++;
              });
            } : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  List<QuizResultWithDetails> _getPaginatedResults(List<QuizResultWithDetails> results) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, results.length);
    return results.sublist(startIndex, endIndex);
  }

  Future<List<QuizResultWithDetails>> _getAllQuizResults() async {
    final quizState = ref.read(quizProvider);
    final quizNotifier = ref.read(quizProvider.notifier);
    final completedAttempts = quizState.userAttempts.where((attempt) => attempt.isCompleted).toList();
    
    final results = <QuizResultWithDetails>[];
    
    for (final attempt in completedAttempts) {
      try {
        // Get quiz result details from Supabase
        final resultData = await quizNotifier.getQuizResultDetails(attempt);
        
        if (resultData != null) {
          results.add(QuizResultWithDetails(
            attempt: resultData['attempt'],
            quiz: resultData['quiz'],
            course: resultData['course'],
            percentage: resultData['percentage'],
            correctAnswers: resultData['correctAnswers'],
            totalQuestions: resultData['totalQuestions'],
          ));
        }
      } catch (e) {
        // Skip this attempt if there's an error loading its details
        continue;
      }
    }
    
    // Sort by submission date (newest first)
    results.sort((a, b) => b.attempt.submittedAt!.compareTo(a.attempt.submittedAt!));
    return results;
  }

  List<QuizResultWithDetails> _getFilteredResults(List<QuizResultWithDetails> allResults) {
    switch (_selectedFilter) {
      case 'Excellent':
        return allResults.where((r) => r.percentage >= 90).toList();
      case 'Good':
        return allResults.where((r) => r.percentage >= 75 && r.percentage < 90).toList();
      case 'Fair':
        return allResults.where((r) => r.percentage >= 60 && r.percentage < 75).toList();
      case 'Poor':
        return allResults.where((r) => r.percentage < 60).toList();
      default:
        return allResults;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference ${difference == 1 ? 'day' : 'days'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTimeSpent(int minutes) {
    if (minutes == 0) {
      return 'Less than 1 minute';
    } else if (minutes < 60) {
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes ${remainingMinutes == 1 ? 'minute' : 'minutes'}';
      }
    }
  }
}

class QuizResultWithDetails {
  final Attempt attempt;
  final Quiz quiz;
  final Course course;
  final double percentage;
  final int correctAnswers;
  final int totalQuestions;

  QuizResultWithDetails({
    required this.attempt,
    required this.quiz,
    required this.course,
    required this.percentage,
    required this.correctAnswers,
    required this.totalQuestions,
  });
}