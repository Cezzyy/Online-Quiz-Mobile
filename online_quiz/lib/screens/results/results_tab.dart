import 'package:flutter/material.dart';
import '../../models/new_quiz.dart';
import '../../models/new_course.dart';
import '../../models/new_attempt.dart';
import '../../data/new_mock_data.dart';
import '../quizzes/quiz_result_screen.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/filter_tab_widget.dart';

class ResultsTab extends StatefulWidget {
  const ResultsTab({super.key});

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  String _selectedFilter = 'All';
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final allQuizResults = _getAllQuizResults();
    final filteredResults = _getFilteredResults(allQuizResults);
    final totalPages = (filteredResults.length / _itemsPerPage).ceil();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiz Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'View your quiz performance and scores',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Filter Tabs
            _buildFilterTabs(),
            // Stats Overview
            _buildStatsOverview(allQuizResults),
            // Results List
            Expanded(
              child: _buildResultsList(filteredResults, totalPages),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Excellent', 'Good', 'Fair', 'Poor'];
    
    return FilterTabPresets.resultsStyle(
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

  Widget _buildStatsOverview(List<QuizResultWithDetails> allResults) {
    final totalQuizzes = allResults.length;
    final averageScore = totalQuizzes > 0 
        ? allResults.map((r) => r.percentage).reduce((a, b) => a + b) / totalQuizzes
        : 0.0;
    final excellentCount = allResults.where((r) => r.percentage >= 90).length;
    final goodCount = allResults.where((r) => r.percentage >= 75 && r.percentage < 90).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(totalQuizzes.toString(), 'Total', Colors.blue),
          _buildStatItem('${averageScore.toStringAsFixed(1)}%', 'Average', Colors.green),
          _buildStatItem(excellentCount.toString(), 'Excellent', Colors.purple),
          _buildStatItem(goodCount.toString(), 'Good', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<QuizResultWithDetails> results, int totalPages) {
    if (results.isEmpty) {
      return EmptyStatePresets.quizResults();
    }

    final paginatedResults = _getPaginatedResults(results);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: paginatedResults.length,
            itemBuilder: (context, index) {
              return _buildResultCard(paginatedResults[index]);
            },
          ),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${course.code} - ${course.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: 16),
            // Score details
            Row(
              children: [
                _buildDetailItem(
                  Icons.check_circle_outline,
                  'Score',
                  '${resultDetails.correctAnswers}/${resultDetails.totalQuestions}',
                ),
                _buildDetailItem(
                   Icons.access_time,
                   'Time',
                   '${(attempt.timeSpentSeconds ?? 0) ~/ 60} min',
                 ),
                _buildDetailItem(
                  Icons.calendar_today,
                  'Completed',
                  _formatDate(attempt.submittedAt!),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
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

  List<QuizResultWithDetails> _getAllQuizResults() {
    final List<QuizResultWithDetails> allResults = [];
    const int currentUserId = 4; // Default student user
    
    // Get all completed attempts for the current user
    final completedAttempts = NewMockData.getAttemptsByUser(currentUserId)
        .where((attempt) => attempt.submittedAt != null)
        .toList();
    
    for (final attempt in completedAttempts) {
      final quiz = NewMockData.getQuizById(attempt.quizId);
      final course = quiz != null ? NewMockData.getCourseById(quiz.courseId) : null;
      
      if (quiz != null && course != null) {
        // Calculate quiz results
        final questions = NewMockData.getQuestionsByQuiz(quiz.quizId);
        final totalQuestions = questions.length;
        final totalPoints = questions.fold<double>(0.0, (sum, q) => sum + q.points);
        final percentage = totalPoints > 0 ? (attempt.score / totalPoints) * 100 : 0.0;
        
        // Calculate correct answers
        final attemptAnswers = NewMockData.getAnswersByAttempt(attempt.attemptId);
        final correctAnswers = attemptAnswers.where((answer) => answer.isCorrect == true).length;
        
        allResults.add(QuizResultWithDetails(
          attempt: attempt,
          quiz: quiz,
          course: course,
          percentage: percentage,
          correctAnswers: correctAnswers,
          totalQuestions: totalQuestions,
        ));
      }
    }
    
    // Sort by completion date (most recent first)
    allResults.sort((a, b) => b.attempt.submittedAt!.compareTo(a.attempt.submittedAt!));
    
    return allResults;
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