import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz.dart';
import '../../models/course.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/filter_tab_widget.dart';
import '../../utils/app_theme.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';
import 'quiz_detail_screen.dart';

class QuizTab extends ConsumerStatefulWidget {
  const QuizTab({super.key});

  @override
  ConsumerState<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends ConsumerState<QuizTab> {
  final List<String> _filterOptions = ['All', 'Pending', 'Overdue', 'Completed'];

  @override
  void initState() {
    super.initState();
    // Initialize quizzes when the widget is first created
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref.read(quizProvider.notifier).initializeQuizzes(authState.user!.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isLoading = ref.watch(quizLoadingProvider);
    final error = ref.watch(quizErrorProvider);
    final allQuizzes = ref.watch(allQuizzesProvider);
    final paginatedQuizzes = ref.watch(paginatedQuizzesProvider);
    final selectedFilter = ref.watch(quizFilterProvider);
    final quizStats = ref.watch(quizStatsProvider);

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading quizzes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (user != null) {
                    ref.read(quizProvider.notifier).refreshQuizzes(user.userId);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await ref.read(quizProvider.notifier).refreshQuizzes(user.userId);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildHeader(quizStats),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (allQuizzes.isNotEmpty) _buildFilterTabs(selectedFilter),
                    if (allQuizzes.isNotEmpty) const SizedBox(height: 16),
                    allQuizzes.isEmpty
                        ? _buildEmptyState()
                        : _buildQuizList(paginatedQuizzes),
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

  Widget _buildHeader(Map<String, int> stats) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight < 700 ? 200.0 : 220.0;
    
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
                Icons.quiz,
                color: Colors.white,
                size: screenHeight < 700 ? 40 : 48,
              ),
              SizedBox(height: screenHeight < 700 ? 12 : 16),
              Text(
                'All Quizzes',
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
                  '${stats['total']} ${stats['total'] == 1 ? 'Quiz' : 'Quizzes'} - ${stats['completed']} Completed',
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
  
  Widget _buildFilterTabs(String selectedFilter) {
    return FilterTabPresets.quizStyle(
      context: context,
      options: _filterOptions,
      selectedFilter: selectedFilter,
      onFilterChanged: (filter) {
        ref.read(quizProvider.notifier).setFilter(filter);
      },
    );
  }

  Widget _buildQuizList(List<Quiz> quizzes) {
    final selectedFilter = ref.watch(quizFilterProvider);
    final paginationInfo = ref.watch(quizPaginationProvider);
    final filteredQuizzes = ref.watch(filteredQuizzesProvider);
    
    if (quizzes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No ${selectedFilter.toLowerCase()} quizzes found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for new quizzes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return FutureBuilder<Course?>(
              future: ref.read(quizProvider.notifier).getCourseForQuiz(quiz.quizId),
              builder: (context, snapshot) {
                final course = snapshot.data;
                return _buildQuizCard(quiz, course);
              },
            );
          },
        ),
        if (filteredQuizzes.length > paginationInfo['itemsPerPage']!) 
          _buildPaginationControls(paginationInfo),
      ],
    );
  }

  Widget _buildQuizCard(Quiz quiz, Course? course) {
    final quizState = ref.watch(quizProvider);
    final completedAttempt = quizState.quizAttempts[quiz.quizId];
    final isCompleted = completedAttempt != null && completedAttempt.submittedAt != null;
    final isOverdue = !isCompleted && quiz.isOverdue;
    final daysUntilDue = quiz.daysUntilDue;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (isCompleted) {
      statusColor = Colors.green;
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'Overdue';
      statusIcon = Icons.error;
    } else {
      statusColor = Colors.orange;
      statusText = daysUntilDue == 0 ? 'Due Today' : 'Due in $daysUntilDue ${daysUntilDue == 1 ? 'day' : 'days'}';
      statusIcon = Icons.schedule;
    }

    return GestureDetector(
      onTap: () => _navigateToQuizDetail(quiz, course),
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
              // Quiz Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
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
                        if (course != null) ...[
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
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Quiz Info
              _buildInfoRow(
                context,
                'Status',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              _buildDivider(context),
              _buildInfoRow(
                context,
                'Time Limit',
                Text(
                  quiz.hasTimeLimit ? '${quiz.timeLimitMinutes} minutes' : 'No limit',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildDivider(context),
              _buildInfoRow(
                context,
                'Due Date',
                Text(
                  quiz.hasDueDate ? _formatDate(quiz.dueAt!) : 'No due date',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              if (isCompleted) ...[
                _buildDivider(context),
                _buildInfoRow(
                  context,
                  'Score',
                  Text(
                    '${completedAttempt.score.toInt()} points (${quizState.quizScores[quiz.quizId]?.round() ?? 0}%)',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(BuildContext context, String label, Widget valueWidget) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(child: valueWidget),
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

  Widget _buildEmptyState() {
    return EmptyStatePresets.quizzes();
  }

  Widget _buildPaginationControls(Map<String, int> paginationInfo) {
    final currentPage = paginationInfo['currentPage']!;
    final totalPages = paginationInfo['totalPages']!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 0 ? () {
              ref.read(quizProvider.notifier).setPage(currentPage - 1);
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
              '${currentPage + 1} / $totalPages',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          IconButton(
            onPressed: currentPage < totalPages - 1 ? () {
              ref.read(quizProvider.notifier).setPage(currentPage + 1);
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



  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1) {
      return 'In $difference ${difference == 1 ? 'day' : 'days'}';
    } else {
      return '${difference.abs()} ${difference.abs() == 1 ? 'day' : 'days'} ago';
    }
  }

  void _navigateToQuizDetail(Quiz quiz, Course? course) {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizDetailScreen(
           quiz: quiz,
           course: course,
           currentUserId: authState.user!.userId,
         ),
      ),
    );
  }
}