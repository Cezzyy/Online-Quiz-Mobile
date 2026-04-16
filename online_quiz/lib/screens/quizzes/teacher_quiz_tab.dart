import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/local_auth_provider.dart';
import '../../widgets/quizzes_skeleton_loader.dart';
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
    Future.microtask(() {
      final currentUser = ref.read(currentUserProvider);
      final userRole = ref.read(currentUserRoleProvider);
      final localAuthState = ref.read(localAuthProvider);
      
      if (currentUser != null) {
        // If app was just unlocked, clear cache and reload data
        if (localAuthState.shouldReloadData) {
          setState(() {
            selectedCourse = null;
            courseQuizzes = [];
          });
        }
        
        ref
            .read(courseProvider.notifier)
            .initializeCourses(currentUser.userId, userRole: userRole);
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

    await ref
        .read(quizProvider.notifier)
        .loadQuizzesForCourse(selectedCourse!.courseId);

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
        content: Text(
          'Are you sure you want to delete "${quiz.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Delete quiz using provider
              final success = await ref
                  .read(quizProvider.notifier)
                  .deleteQuiz(quiz.quizId);

              if (success) {
                setState(() {
                  courseQuizzes = ref.read(quizProvider).allQuizzes;
                  currentPage = 0; // Reset to first page
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Quiz "${quiz.title}" deleted successfully',
                      ),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ref.read(quizProvider).error ?? 'Failed to delete quiz',
                      ),
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
        builder: (context) =>
            CreateQuizScreen(course: selectedCourse!, quiz: quiz),
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
    final localAuthState = ref.watch(localAuthProvider);
    final theme = Theme.of(context);

    // Show loading skeleton
    if (currentUser == null || localAuthState.shouldReloadData || courseState.isLoading) {
      return const QuizzesSkeletonLoader();
    }

    // Show error if there's an error
    if (courseState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading courses',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                courseState.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final userRole = ref.read(currentUserRoleProvider);
                  ref
                      .read(courseProvider.notifier)
                      .initializeCourses(currentUser.userId, userRole: userRole);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter to only show active courses
    final allCourses = courseState.allCourses;
    final teacherCourses = allCourses
        .where((course) => course.isActive)
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final userRole = ref.read(currentUserRoleProvider);
          await ref
              .read(courseProvider.notifier)
              .initializeCourses(currentUser.userId, userRole: userRole);
          if (selectedCourse != null) {
            await _refreshQuizzes();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header Section with Gradient
              _buildHeader(context, teacherCourses),
              const SizedBox(height: 24),
              
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (teacherCourses.isEmpty)
                      _buildEmptyCoursesState()
                    else ...[
                      // Compact Course Selector with Stats
                      _buildCompactCourseSelector(context, teacherCourses),
                      
                      if (selectedCourse != null) ...[
                        const SizedBox(height: 16),
                        
                        // Quiz List
                        _buildQuizList(context),
                      ],
                    ],
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

  Future<void> _togglePublishStatus(Quiz quiz) async {
    // Toggle publish status using provider
    final success = await ref
        .read(quizProvider.notifier)
        .togglePublishQuiz(quiz.quizId, !quiz.isPublished);

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
          content: Text(
            ref.read(quizProvider).error ?? 'Failed to toggle publish status',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context, List<Course> teacherCourses) {
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
                'Manage Quizzes',
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
                  selectedCourse != null
                      ? '${courseQuizzes.length} ${courseQuizzes.length == 1 ? 'Quiz' : 'Quizzes'}'
                      : '${teacherCourses.length} ${teacherCourses.length == 1 ? 'Course' : 'Courses'}',
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

  Widget _buildEmptyCoursesState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Courses Assigned',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any courses assigned yet.\nContact your administrator to get courses assigned.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final currentUser = ref.read(currentUserProvider);
                final userRole = ref.read(currentUserRoleProvider);
                if (currentUser != null) {
                  ref
                      .read(courseProvider.notifier)
                      .initializeCourses(currentUser.userId, userRole: userRole);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCourseSelector(BuildContext context, List<Course> teacherCourses) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalQuizzes = courseQuizzes.length;
    final publishedQuizzes = courseQuizzes.where((q) => q.isPublished).length;
    final draftQuizzes = courseQuizzes.where((q) => !q.isPublished).length;
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Course Button with Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _showCourseSelectionBottomSheet(context, teacherCourses),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 20,
                            color: selectedCourse != null 
                                ? AppTheme.primaryColor
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedCourse?.code ?? 'Select Course',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selectedCourse != null ? FontWeight.w600 : FontWeight.normal,
                                color: selectedCourse != null 
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Create Quiz Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: selectedCourse == null ? null : _showCreateQuizDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Create',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Refresh Button
                IconButton(
                  onPressed: selectedCourse == null || isRefreshing ? null : _refreshQuizzes,
                  icon: isRefreshing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: selectedCourse == null 
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                              : theme.colorScheme.primary,
                        ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark 
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            
            // Stats Row (only show when course is selected)
            if (selectedCourse != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCompactStat(
                      context,
                      'Total',
                      totalQuizzes.toString(),
                      Colors.blue,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                    _buildCompactStat(
                      context,
                      'Published',
                      publishedQuizzes.toString(),
                      Colors.green,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                    _buildCompactStat(
                      context,
                      'Draft',
                      draftQuizzes.toString(),
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCourseSelectionBottomSheet(BuildContext context, List<Course> teacherCourses) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.school,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select Course',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Course List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: teacherCourses.length,
                itemBuilder: (context, index) {
                  final course = teacherCourses[index];
                  final isSelected = selectedCourse?.courseId == course.courseId;
                  
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _loadQuizzesForCourse(course);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : (isDark 
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.black.withValues(alpha: 0.02)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.getCourseColor(course.code).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.book,
                              color: AppTheme.getCourseColor(course.code),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.code,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected 
                                        ? AppTheme.primaryColor
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  course.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                              size: 24,
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

  Widget _buildCompactStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
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
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizList(BuildContext context) {
    if (courseQuizzes.isEmpty) {
      return _buildEmptyQuizzesState();
    }

    if (isRefreshing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        // Quiz cards
        ...paginatedQuizzes.map((quiz) => _buildQuizCard(context, quiz)),

        // Compact Pagination controls
        if (totalPages > 1) _buildCompactPaginationControls(),
      ],
    );
  }

  Widget _buildCompactPaginationControls() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            style: IconButton.styleFrom(
              backgroundColor: hasPreviousPage 
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${currentPage + 1} / $totalPages',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
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
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            style: IconButton.styleFrom(
              backgroundColor: hasNextPage 
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQuizzesState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Quizzes Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first quiz for ${selectedCourse!.name}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateQuizDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, Quiz quiz) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Color statusColor = quiz.isPublished ? Colors.green : Colors.orange;
    IconData statusIcon = quiz.isPublished ? Icons.check_circle : Icons.edit;
    
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: quiz.isPublished ? null : () => _continueDraft(quiz),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status Icon
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
              
              // Quiz Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
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
                        FutureBuilder<int>(
                          future: ref.read(quizProvider.notifier).getQuestionCount(quiz.quizId),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            return Text(
                              '$count Q',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            );
                          },
                        ),
                        if (quiz.hasTimeLimit) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                          Text(
                            ' ${quiz.timeLimitMinutes}m',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.5),
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
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.5),
                        ),
                        Text(
                          ' ${DateFormat('MMMM d, yyyy').format(quiz.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quiz.isPublished ? 'Live' : 'Draft',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Menu Button
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
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
                          Icon(Icons.edit_note, color: Colors.blue, size: 20),
                          SizedBox(width: 12),
                          Text('Continue Draft', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit Details', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_publish',
                    child: Row(
                      children: [
                        Icon(
                          quiz.isPublished ? Icons.unpublished : Icons.publish,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          quiz.isPublished ? 'Unpublish' : 'Publish',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateQuizDialog extends ConsumerStatefulWidget {
  final Course course;
  final VoidCallback onQuizCreated;

  const _CreateQuizDialog({required this.course, required this.onQuizCreated});

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
                    errorText: _dueDate == null
                        ? 'Please select a due date'
                        : null,
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
        ElevatedButton(onPressed: _createQuiz, child: const Text('Create')),
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
      final createdQuiz = await ref
          .read(quizProvider.notifier)
          .createQuiz(
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
            content: Text(
              ref.read(quizProvider).error ?? 'Failed to create quiz',
            ),
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
          builder: (context) =>
              CreateQuizScreen(course: widget.course, quiz: createdQuiz),
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
                    initialDate:
                        _dueDate ?? DateTime.now().add(const Duration(days: 7)),
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
                    errorText: _dueDate == null
                        ? 'Please select a due date'
                        : null,
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
        ElevatedButton(onPressed: _updateQuiz, child: const Text('Update')),
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
      final success = await ref
          .read(quizProvider.notifier)
          .updateQuiz(
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
          SnackBar(
            content: Text(
              'Quiz "${_titleController.text}" updated successfully',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(quizProvider).error ?? 'Failed to update quiz',
            ),
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
