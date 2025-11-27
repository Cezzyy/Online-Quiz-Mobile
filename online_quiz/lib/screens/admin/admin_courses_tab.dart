import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../providers/course_provider.dart';
import '../../widgets/empty_state_widget.dart';
import 'create_course_screen.dart';
import 'course_details_screen.dart';
import 'manage_sections_screen.dart';
import 'add_section_screen.dart';
import 'manage_course_screen.dart';

class AdminCoursesTab extends ConsumerStatefulWidget {
  const AdminCoursesTab({super.key});

  @override
  ConsumerState<AdminCoursesTab> createState() => _AdminCoursesTabState();
}

class _AdminCoursesTabState extends ConsumerState<AdminCoursesTab> {
  List<User> _teachers = [];
  List<String> _availableSections = [];

  @override
  void initState() {
    super.initState();
    // Initialize courses when the tab is first loaded
    Future.microtask(() {
      final existing = ref.read(courseProvider);
      if (!existing.isLoading && existing.allCourses.isEmpty) {
        ref.read(courseProvider.notifier).loadAllCourses();
      }
      if (_teachers.isEmpty) {
        _loadTeachers();
      }
      if (_availableSections.isEmpty) {
        _loadAvailableSections();
      }
    });
  }

  Future<void> _loadTeachers() async {
    try {
      final teachers = await ref.read(courseProvider.notifier).getAllTeachers();
      if (mounted) {
        setState(() {
          _teachers = teachers;
        });
      }
    } catch (e) {
      // Error loading teachers
    }
  }

  Future<void> _loadAvailableSections() async {
    try {
      final sections = await ref
          .read(courseProvider.notifier)
          .getAvailableSections();
      if (mounted) {
        setState(() {
          _availableSections = sections;
        });
      }
    } catch (e) {
      // Error loading sections
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseProvider);
    final courseNotifier = ref.read(courseProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(context, courseState, courseNotifier),

            // Content Section
            Expanded(
              child: courseState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(context, courseState, courseNotifier),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_courses_fab',
        onPressed: () => _navigateToCreateCourse(context, courseNotifier),
        icon: const Icon(Icons.add),
        label: const Text('Add Course'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CourseState state,
    CourseNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Total',
                  state.allCourses.length.toString(),
                  Icons.book,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Active',
                  state.allCourses.where((c) => c.isActive).length.toString(),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Inactive',
                  state.allCourses.where((c) => c.isInactive).length.toString(),
                  Icons.pause_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Archived',
                  state.allCourses.where((c) => c.isArchived).length.toString(),
                  Icons.archive,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search and Filter Section
          Column(
            children: [
              // Search Field
              TextField(
                onChanged: notifier.updateSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.getSurfaceColor(context),
                ),
              ),

              const SizedBox(height: 12),

              // Filter Row
              Row(
                children: [
                  // Status Filter
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.getDividerColor(context),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.getSurfaceColor(context),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.selectedStatus,
                          isExpanded: true,
                          menuMaxHeight: 300,
                          hint: Text(
                            'All Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'All Status',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Active',
                              child: Text(
                                'Active',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Inactive',
                              child: Text(
                                'Inactive',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Archived',
                              child: Text(
                                'Archived',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              notifier.updateSelectedStatus(value),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Category Filter
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.getDividerColor(context),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.getSurfaceColor(context),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.selectedCategory,
                          isExpanded: true,
                          menuMaxHeight: 300,
                          hint: Text(
                            'All Categories',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'All Categories',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ...state.allCourses
                                .where((course) => course.category != null)
                                .map((course) => course.category!)
                                .toSet()
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                          ],
                          onChanged: (value) =>
                              notifier.updateSelectedCategory(value),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Instructor Filter
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.getDividerColor(context),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.getSurfaceColor(context),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: state.selectedInstructorId,
                          isExpanded: true,
                          menuMaxHeight: 300,
                          hint: Text(
                            'All Instructors',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.getSecondaryTextColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'All Instructors',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ..._teachers.map(
                              (teacher) => DropdownMenuItem(
                                value: teacher.userId,
                                child: Text(
                                  teacher.fullName,
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              notifier.updateSelectedInstructor(value),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CourseState state,
    CourseNotifier notifier,
  ) {
    final groupedCourses = notifier.getPaginatedGroupedCourses();
    final totalPages = notifier.getTotalGroupedPages();

    if (groupedCourses.isEmpty) {
      return EmptyStateWidget(
        icon: state.searchQuery.isNotEmpty
            ? Icons.search_off
            : Icons.book_outlined,
        title: state.searchQuery.isNotEmpty
            ? 'No Courses Found'
            : 'No Courses Available',
        message: state.searchQuery.isNotEmpty
            ? 'No courses match your search criteria'
            : 'Start by adding your first course',
        action: ElevatedButton.icon(
          onPressed: () => _navigateToCreateCourse(context, notifier),
          icon: const Icon(Icons.add),
          label: const Text('Add Course'),
        ),
      );
    }

    return Column(
      children: [
        // Table
        Expanded(
          child: SingleChildScrollView(
            primary: false,
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppTheme.getDividerColor(context).withValues(alpha: 0.1),
                ),
                dataRowColor: WidgetStateProperty.all(
                  AppTheme.getCardColor(context),
                ),
                columnSpacing: 24,
                columns: const [
                  DataColumn(
                    label: Expanded(
                      child: Text(
                        'Course',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Code',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: groupedCourses.map((groupedCourse) {
                  final courseCode = groupedCourse['courseCode'] as String;
                  final courseName = groupedCourse['courseName'] as String;

                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _getCourseColor(
                                courseCode,
                              ).withValues(alpha: 0.1),
                              child: Icon(
                                Icons.book,
                                size: 18,
                                color: _getCourseColor(courseCode),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    courseName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppTheme.getTextColor(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    courseCode,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.getSecondaryTextColor(
                                        context,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          courseCode,
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataCell(
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleGroupedCourseAction(
                            context,
                            value,
                            groupedCourse,
                            notifier,
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text('View Details'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'manage',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('Manage Course'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'sections',
                              child: Row(
                                children: [
                                  Icon(Icons.layers_outlined, size: 20),
                                  SizedBox(width: 12),
                                  Text('Manage Sections'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'add_section',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text('Add Section'),
                                ],
                              ),
                            ),
                          ],
                          child: Icon(
                            Icons.more_vert,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Pagination Controls
        if (totalPages > 1)
          _buildPaginationControls(context, state, notifier, totalPages),
      ],
    );
  }

  Widget _buildPaginationControls(
    BuildContext context,
    CourseState state,
    CourseNotifier notifier,
    int totalPages,
  ) {
    final startIndex = (state.currentPage - 1) * state.itemsPerPage + 1;
    final endIndex = (startIndex + state.itemsPerPage - 1).clamp(
      0,
      notifier.getFilteredCourses().length,
    );
    final totalItems = notifier.getFilteredCourses().length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        border: Border(
          top: BorderSide(color: AppTheme.getDividerColor(context), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items info
          Text(
            'Showing $startIndex-$endIndex of $totalItems courses',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 14,
            ),
          ),

          // Pagination controls
          Row(
            children: [
              // Previous button
              IconButton(
                onPressed: state.currentPage > 1 ? notifier.previousPage : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: state.currentPage > 1
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
              ),

              // Page numbers
              ...List.generate(
                totalPages.clamp(0, 5), // Show max 5 page numbers
                (index) {
                  int pageNumber;
                  if (totalPages <= 5) {
                    pageNumber = index + 1;
                  } else {
                    // Smart pagination: show current page and surrounding pages
                    if (state.currentPage <= 3) {
                      pageNumber = index + 1;
                    } else if (state.currentPage >= totalPages - 2) {
                      pageNumber = totalPages - 4 + index;
                    } else {
                      pageNumber = state.currentPage - 2 + index;
                    }
                  }

                  final isCurrentPage = pageNumber == state.currentPage;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => notifier.goToPage(pageNumber),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCurrentPage
                              ? AppTheme.primaryColor
                              : AppTheme.getSurfaceColor(context),
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrentPage
                              ? null
                              : Border.all(
                                  color: AppTheme.getDividerColor(context),
                                  width: 1,
                                ),
                        ),
                        child: Center(
                          child: Text(
                            pageNumber.toString(),
                            style: TextStyle(
                              color: isCurrentPage
                                  ? Colors.white
                                  : AppTheme.getTextColor(context),
                              fontWeight: isCurrentPage
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Next button
              IconButton(
                onPressed: state.currentPage < totalPages
                    ? notifier.nextPage
                    : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: state.currentPage < totalPages
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleGroupedCourseAction(
    BuildContext context,
    String action,
    Map<String, dynamic> groupedCourse,
    CourseNotifier notifier,
  ) {
    final courseCode = groupedCourse['courseCode'] as String;
    final courses = groupedCourse['courses'] as List<Course>;
    final primaryCourse = groupedCourse['primaryCourse'] as Course;

    switch (action) {
      case 'view':
        _navigateToCourseDetails(context, groupedCourse, notifier);
        break;
      case 'manage':
        _navigateToManageCourse(context, groupedCourse, notifier);
        break;
      case 'sections':
        _navigateToManageSections(context, courseCode, courses, notifier);
        break;
      case 'add_section':
        _navigateToAddSection(context, courseCode, primaryCourse, notifier);
        break;
    }
  }

  Future<void> _navigateToCourseDetails(
    BuildContext context,
    Map<String, dynamic> groupedCourse,
    CourseNotifier notifier,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CourseDetailsScreen(groupedCourse: groupedCourse),
      ),
    );
  }

  Future<void> _navigateToManageCourse(
    BuildContext context,
    Map<String, dynamic> groupedCourse,
    CourseNotifier notifier,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ManageCourseScreen(groupedCourse: groupedCourse),
      ),
    );

    if (result == true && mounted) {
      await notifier.loadAllCourses();
    }
  }

  Future<void> _navigateToManageSections(
    BuildContext context,
    String courseCode,
    List<Course> courses,
    CourseNotifier notifier,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            ManageSectionsScreen(courseCode: courseCode, courses: courses),
      ),
    );

    if (result == true && mounted) {
      await notifier.loadAllCourses();
    }
  }

  Future<void> _navigateToAddSection(
    BuildContext context,
    String courseCode,
    Course primaryCourse,
    CourseNotifier notifier,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddSectionScreen(
          courseCode: courseCode,
          primaryCourse: primaryCourse,
        ),
      ),
    );

    if (result == true && mounted) {
      await notifier.loadAllCourses();
    }
  }

  Future<void> _navigateToCreateCourse(
    BuildContext context,
    CourseNotifier notifier,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const CreateCourseScreen()),
    );

    // Reload courses if creation was successful
    if (result == true && mounted) {
      await notifier.loadAllCourses();
    }
  }

  Color _getCourseColor(String courseCode) {
    // Generate a consistent color based on course code
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];

    final hash = courseCode.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
