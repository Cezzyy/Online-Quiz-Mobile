import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';
import '../../models/user.dart';
import '../quizzes/quiz_detail_screen.dart';
import '../../utils/app_theme.dart';
import '../../providers/course_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';


class CourseDetailScreen extends ConsumerStatefulWidget {
  final Course course;
  
  const CourseDetailScreen({super.key, required this.course});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load course details when screen is opened
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref.read(courseProvider.notifier).loadCourseDetails(widget.course.courseId);
        ref.read(quizProvider.notifier).initializeQuizzes(authState.user!.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseProvider);
    final quizState = ref.watch(quizProvider);
    
    // Use course data from provider if available, otherwise use the passed course
    final course = courseState.selectedCourse ?? widget.course;
    final courseQuizzes = courseState.selectedCourseQuizzes;
    
    // Calculate progress from quiz provider state
    final totalQuizzes = courseQuizzes.length;
    final completedQuizzes = courseQuizzes.where((quiz) => 
        quizState.isQuizCompleted(quiz.quizId)).length;
    final progress = totalQuizzes > 0 ? completedQuizzes / totalQuizzes : 0.0;
    
    return Scaffold(
      body: courseState.isLoadingCourseDetails
          ? const Center(child: CircularProgressIndicator())
          : courseState.error != null
              ? Center(
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
                        'Error loading course details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        courseState.error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(courseProvider.notifier).loadCourseDetails(course.courseId);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(courseProvider.notifier).loadCourseDetails(course.courseId);
                  },
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Course Header with gradient
                        _buildCourseHeader(context, course, progress, completedQuizzes, totalQuizzes),
                        SizedBox(height: MediaQuery.of(context).size.height < 700 ? 20 : 24),
                        
                        // Course Information Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildCourseInfo(context, course),
                              const SizedBox(height: 16),
                              _buildProgressCard(context, progress, completedQuizzes, totalQuizzes),
                              SizedBox(height: MediaQuery.of(context).size.height < 700 ? 20 : 24),
                              
                              // Quizzes Section
                              _buildQuizzesList(context, courseQuizzes, course),
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
  
  Widget _buildCourseHeader(BuildContext context, Course course, double progress, int completedQuizzes, int totalQuizzes) {
    final courseColor = _getCourseColor(course.code);
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
              colors: [courseColor, courseColor.withValues(alpha: 0.7)],
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
        // Back Button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Content
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                color: Colors.white,
                size: screenHeight < 700 ? 40 : 48,
              ),
              SizedBox(height: screenHeight < 700 ? 12 : 16),
              Text(
                course.name,
                style: TextStyle(
                  fontSize: screenHeight < 700 ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                course.code,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuizzesList(BuildContext context, List<Quiz> courseQuizzes, Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.quiz, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Quizzes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (courseQuizzes.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No quizzes available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: courseQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = courseQuizzes[index];
              return _buildQuizCard(context, quiz, course);
            },
          ),
      ],
    );
  }
  
  Widget _buildQuizCard(BuildContext context, Quiz quiz, Course course) {
    final quizState = ref.watch(quizProvider);
    
    final completedAttempt = quizState.quizAttempts[quiz.quizId];
    final isCompleted = completedAttempt != null && completedAttempt.submittedAt != null;
    final isOverdue = !isCompleted && quiz.isOverdue;
    
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
      statusText = 'Pending';
      statusIcon = Icons.schedule;
    }
    
    return GestureDetector(
      onTap: () {
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
      },
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(top: 0, bottom: 12),
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
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
              
              // Quiz Details
              Row(
                children: [
                  Expanded(
                    child: FutureBuilder<int>(
                      future: ref.read(quizProvider.notifier).getQuestionCount(quiz.quizId),
                      builder: (context, snapshot) {
                        final questionCount = snapshot.data ?? 0;
                        return _buildQuizDetailItem(
                          context,
                          icon: Icons.quiz_outlined,
                          label: 'Questions',
                          value: questionCount.toString(),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildQuizDetailItem(
                      context,
                      icon: Icons.timer_outlined,
                      label: 'Time',
                      value: quiz.timeLimitMinutes != null ? '${quiz.timeLimitMinutes}m' : 'No limit',
                    ),
                  ),
                  if (isCompleted) ...[
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _buildQuizDetailItem(
                        context,
                        icon: Icons.grade,
                        label: 'Score',
                        value: '${(quizState.quizScores[quiz.quizId] ?? 0.0).round()}%',
                        valueColor: _getScoreColor(quizState.quizScores[quiz.quizId] ?? 0.0),
                      ),
                    ),
                  ],
                ],
              ),
              
              if (quiz.dueAt != null || isCompleted) ...[
                const SizedBox(height: 12),
                Divider(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  height: 1,
                ),
                const SizedBox(height: 12),
              ],
              
              if (quiz.dueAt != null)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Due: ${_formatDate(quiz.dueAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              
              if (isCompleted && completedAttempt.submittedAt != null) ...[
                if (quiz.dueAt != null) const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Completed: ${_formatDate(completedAttempt.submittedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuizDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Color _getCourseColor(String courseCode) {
    return AppTheme.getCourseColor(courseCode);
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  Color _getScoreColor(double score) {
    return AppTheme.getScoreColor(score);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Widget _buildCourseInfo(BuildContext context, Course course) {
    return _buildInfoCard(
      context,
      title: 'Course Information',
      icon: Icons.info_outline,
      children: [
        FutureBuilder<User?>(
          future: ref.read(courseProvider.notifier).getCourseInstructor(course.instructorUserId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Column(
                children: [
                  _buildInfoRow(
                    context,
                    'Instructor',
                    snapshot.data!.fullName,
                  ),
                  _buildDivider(context),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        _buildInfoRow(
          context,
          'Section',
          course.section ?? 'N/A',
        ),
        if (course.category != null) ...[
          _buildDivider(context),
          _buildInfoRow(
            context,
            'Category',
            course.category!,
          ),
        ],
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Status',
          course.status,
          valueColor: _getStatusColor(course.status),
        ),
        _buildDivider(context),
        _buildInfoRow(
          context,
          'Created',
          _formatDate(course.createdAt),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, double progress, int completedQuizzes, int totalQuizzes) {
    final percentage = (progress * 100).toInt();
    Color progressColor;
    
    if (percentage >= 75) {
      progressColor = Colors.green;
    } else if (percentage >= 50) {
      progressColor = Colors.blue;
    } else if (percentage >= 25) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }
    
    return _buildInfoCard(
      context,
      title: 'Course Progress',
      icon: Icons.trending_up,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$completedQuizzes of $totalQuizzes quizzes completed',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                Icon(icon, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
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
}