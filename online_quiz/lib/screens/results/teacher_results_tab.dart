import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/local_auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/teacher_results_skeleton_loader.dart';
import 'quiz_student_results_screen.dart';

class TeacherResultsTab extends ConsumerStatefulWidget {
  const TeacherResultsTab({super.key});

  @override
  ConsumerState<TeacherResultsTab> createState() => _TeacherResultsTabState();
}

class _TeacherResultsTabState extends ConsumerState<TeacherResultsTab> {
  Course? selectedCourse;
  List<Quiz> courseQuizzes = [];
  bool isLoading = false;
  bool isRefreshing = false;
  Map<String, dynamic>? courseStatistics;

  // Pagination variables
  int currentPage = 0;
  final int itemsPerPage = 10;

  List<Quiz> get paginatedQuizzes {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, courseQuizzes.length);
    return courseQuizzes.sublist(startIndex, endIndex);
  }

  int get totalPages => courseQuizzes.isEmpty ? 1 : (courseQuizzes.length / itemsPerPage).ceil();
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
            courseStatistics = null;
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
      courseStatistics = null;
    });

    // Load quizzes for the course
    await ref.read(quizProvider.notifier).loadQuizzesForCourse(course.courseId);
    
    // Load course statistics
    final stats = await ref
        .read(analyticsProvider.notifier)
        .getCourseStatistics(course.courseId);

    setState(() {
      courseQuizzes = ref.read(quizProvider).allQuizzes;
      courseStatistics = stats;
      currentPage = 0; // Reset to first page when loading new course
      isLoading = false;
    });
  }

  Future<void> _refreshResults() async {
    if (selectedCourse == null) return;

    setState(() {
      isRefreshing = true;
    });

    // Reload quizzes and statistics
    await ref
        .read(quizProvider.notifier)
        .loadQuizzesForCourse(selectedCourse!.courseId);
    
    final stats = await ref
        .read(analyticsProvider.notifier)
        .getCourseStatistics(selectedCourse!.courseId);

    setState(() {
      courseQuizzes = ref.read(quizProvider).allQuizzes;
      courseStatistics = stats;
      currentPage = 0; // Reset to first page after refresh
      isRefreshing = false;
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
      return const TeacherResultsSkeletonLoader();
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
            await _refreshResults();
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
                        
                        // Course Statistics Card
                        if (courseStatistics != null)
                          _buildCourseStatisticsCard(),
                        
                        const SizedBox(height: 16),
                        
                        // Quiz Results List
                        _buildQuizResultsList(context),
                      ] else ...[
                        const SizedBox(height: 16),
                        
                        // Empty state when no course selected
                        _buildNoCourseSelectedState(),
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

  Widget _buildHeader(BuildContext context, List<Course> teacherCourses) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight < 700 ? 200.0 : 220.0;
    final totalQuizzes = courseQuizzes.length;
    final totalStudents = courseStatistics?['totalStudents'] ?? 0;
    
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
                Icons.analytics,
                color: Colors.white,
                size: screenHeight < 700 ? 40 : 48,
              ),
              SizedBox(height: screenHeight < 700 ? 12 : 16),
              Text(
                'Quiz Analytics',
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
                      ? '$totalQuizzes ${totalQuizzes == 1 ? 'Quiz' : 'Quizzes'} • $totalStudents ${totalStudents == 1 ? 'Student' : 'Students'}'
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

  Widget _buildNoCourseSelectedState() {
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
                Icons.touch_app,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a Course',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the course selector above to choose\na course and view its quiz analytics.',
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

  Widget _buildCompactCourseSelector(BuildContext context, List<Course> teacherCourses) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
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
                        child: selectedCourse != null && selectedCourse!.section != null && selectedCourse!.section!.isNotEmpty
                            ? Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      selectedCourse!.code,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      selectedCourse!.section!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
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
            // Refresh Button
            IconButton(
              onPressed: selectedCourse == null || isRefreshing ? null : _refreshResults,
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
                                : Colors.black.withValues(alpha: 0.03)),
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
                                Row(
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
                                    if (course.section != null && course.section!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.getCourseColor(course.code).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          course.section!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.getCourseColor(course.code),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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

  Widget _buildCourseStatisticsCard() {
    if (courseStatistics == null) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    final totalStudents = courseStatistics!['totalStudents'] as int;
    final totalQuizzes = courseStatistics!['totalQuizzes'] as int;
    final publishedQuizzes = courseStatistics!['publishedQuizzes'] as int;
    final averageScore = courseStatistics!['averageScore'] as double;
    final completionRate = courseStatistics!['completionRate'] as double;
    final activeStudents = courseStatistics!['activeStudents'] as int;

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
                Icon(Icons.analytics, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Course Analytics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Total Students',
              totalStudents.toString(),
            ),
            _buildDivider(context),
            _buildInfoRow(
              context,
              'Active Students',
              activeStudents.toString(),
              valueColor: Colors.green,
            ),
            _buildDivider(context),
            _buildInfoRow(
              context,
              'Total Quizzes',
              totalQuizzes.toString(),
            ),
            _buildDivider(context),
            _buildInfoRow(
              context,
              'Published Quizzes',
              publishedQuizzes.toString(),
              valueColor: Colors.blue,
            ),
            _buildDivider(context),
            _buildInfoRow(
              context,
              'Average Score',
              '${averageScore.round()}%',
              valueColor: averageScore >= 75 ? Colors.green : (averageScore >= 50 ? Colors.blue : Colors.grey),
            ),
            _buildDivider(context),
            _buildInfoRow(
              context,
              'Completion Rate',
              '${completionRate.toStringAsFixed(1)}%',
              valueColor: completionRate >= 80 ? Colors.green : (completionRate >= 50 ? Colors.blue : Colors.grey),
            ),
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
          Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor ?? theme.colorScheme.onSurface,
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

  Widget _buildQuizResultsList(BuildContext context) {
    if (courseQuizzes.isEmpty) {
      return _buildEmptyQuizzesState();
    }

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'Quiz Results',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Quiz cards
        ...paginatedQuizzes.map((quiz) => _buildQuizResultCard(context, quiz)),

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
              'Create quizzes for ${selectedCourse!.name} to see analytics and results.',
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

  Widget _buildQuizResultCard(BuildContext context, Quiz quiz) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return FutureBuilder<Map<String, dynamic>>(
      future: ref
          .read(analyticsProvider.notifier)
          .getQuizAnalytics(quiz.quizId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading analytics...',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final analytics = snapshot.data!;
        final completedAttempts = analytics['completedAttempts'] as int;
        final averagePercentage = analytics['averagePercentage'] as double;
        final completionRate = analytics['completionRate'] as double;
        
        // Determine status color based on completion rate - using more neutral colors
        Color statusColor;
        IconData statusIcon;
        if (completionRate >= 80) {
          statusColor = Colors.green;
          statusIcon = Icons.trending_up;
        } else if (completionRate >= 50) {
          statusColor = Colors.blue;
          statusIcon = Icons.trending_flat;
        } else {
          statusColor = Colors.grey;
          statusIcon = Icons.trending_down;
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
                  builder: (context) => QuizStudentResultsScreen(
                    quiz: quiz,
                    course: selectedCourse!,
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
                            Text(
                              '$completedAttempts attempts',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
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
                              'Avg: ${averagePercentage.round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                            if (quiz.dueAt != null) ...[
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
                                color: quiz.isOverdue ? Colors.orange : (isDark 
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5)),
                              ),
                              Text(
                                ' ${_formatDate(quiz.dueAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: quiz.isOverdue ? Colors.orange : (isDark 
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.5)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Completion Rate Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${completionRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Arrow Icon
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      final daysPast = now.difference(date).inDays;
      if (daysPast == 0) {
        return 'Due today';
      } else if (daysPast == 1) {
        return 'Overdue 1 day';
      } else {
        return 'Overdue $daysPast days';
      }
    } else if (difference.inDays > 0) {
      return 'Due in ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else if (difference.inHours > 0) {
      return 'Due in ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else {
      return 'Due in ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
    }
  }
}
