import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty_state_widget.dart';

class AdminCoursesTab extends ConsumerStatefulWidget {
  const AdminCoursesTab({super.key});

  @override
  ConsumerState<AdminCoursesTab> createState() => _AdminCoursesTabState();
}

class _AdminCoursesTabState extends ConsumerState<AdminCoursesTab> {
  @override
  void initState() {
    super.initState();
    // Initialize courses when the tab is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseProvider.notifier).initializeAdminCourses();
    });
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
        onPressed: () => _showCreateCourseDialog(context, courseNotifier),
        icon: const Icon(Icons.add),
        label: const Text('Add Course'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CourseState state, CourseNotifier notifier) {
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
          // Title and Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Course Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
              const SizedBox(height: 8),
            Text(
                'Manage courses and assign instructors',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getSecondaryTextColor(context),
              ),
              ),
              const SizedBox(height: 16),
              // Quick Stats
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickStat(context, 'Total', state.allCourses.length.toString(), Icons.book),
                    const SizedBox(width: 12),
                    _buildQuickStat(context, 'Active', state.allCourses.where((c) => c.isActive).length.toString(), Icons.check_circle),
                    const SizedBox(width: 12),
                    _buildQuickStat(context, 'Inactive', state.allCourses.where((c) => c.isInactive).length.toString(), Icons.pause_circle),
                    const SizedBox(width: 12),
                    _buildQuickStat(context, 'Archived', state.allCourses.where((c) => c.isArchived).length.toString(), Icons.archive),
                  ],
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
                        border: Border.all(color: AppTheme.getDividerColor(context)),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.getSurfaceColor(context),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.selectedStatus,
                          isExpanded: true,
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
                          onChanged: (value) => notifier.updateSelectedStatus(value),
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
                        border: Border.all(color: AppTheme.getDividerColor(context)),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.getSurfaceColor(context),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.selectedCategory,
                          isExpanded: true,
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
                                .map((category) => DropdownMenuItem(
                                  value: category, 
                                  child: Text(
                                    category,
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: (value) => notifier.updateSelectedCategory(value),
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
                        border: Border.all(color: AppTheme.getDividerColor(context)),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.getSurfaceColor(context),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: state.selectedInstructorId,
                          isExpanded: true,
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
                            ...notifier.getAllTeachers().map((teacher) => 
                                DropdownMenuItem(
                                  value: teacher.userId, 
                                  child: Text(
                                    teacher.fullName,
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: (value) => notifier.updateSelectedInstructor(value),
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

  Widget _buildQuickStat(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
            icon,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CourseState state, CourseNotifier notifier) {
    final groupedCourses = notifier.getPaginatedGroupedCourses();
    final totalPages = notifier.getTotalGroupedPages();
    
    if (groupedCourses.isEmpty) {
      return EmptyStateWidget(
        icon: state.searchQuery.isNotEmpty ? Icons.search_off : Icons.book_outlined,
        title: state.searchQuery.isNotEmpty ? 'No Courses Found' : 'No Courses Available',
        message: state.searchQuery.isNotEmpty 
            ? 'No courses match your search criteria'
            : 'Start by adding your first course',
        action: ElevatedButton.icon(
          onPressed: () => _showCreateCourseDialog(context, notifier),
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
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AppTheme.getDividerColor(context).withValues(alpha: 0.1),
                ),
                dataRowColor: WidgetStateProperty.all(
                  AppTheme.getCardColor(context),
                ),
                columns: const [
                  DataColumn(label: Text('Course')),
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Sections')),
                  DataColumn(label: Text('Instructors')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Students')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: groupedCourses.map((groupedCourse) {
                  final courseCode = groupedCourse['courseCode'] as String;
                  final courseName = groupedCourse['courseName'] as String;
                  final sections = groupedCourse['sections'] as List<String>;
                  final instructors = groupedCourse['instructors'] as List<String>;
                  final category = groupedCourse['category'] as String?;
                  final status = groupedCourse['status'] as String;
                  final totalEnrollments = groupedCourse['totalEnrollments'] as int;
                  
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _getCourseColor(courseCode).withValues(alpha: 0.1),
                              child: Icon(
                                Icons.book,
                                size: 16,
                                color: _getCourseColor(courseCode),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                courseName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextColor(context),
                                ),
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
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          sections.join(', '),
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          instructors.join(', '),
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          category ?? 'Not specified',
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          totalEnrollments.toString(),
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ),
                      DataCell(
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleGroupedCourseAction(context, value, groupedCourse, notifier),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'view', child: Text('View Details')),
                            const PopupMenuItem(value: 'sections', child: Text('Manage Sections')),
                            const PopupMenuItem(value: 'add_section', child: Text('Add Section')),
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
        if (totalPages > 1) _buildPaginationControls(context, state, notifier, totalPages),
      ],
    );
  }

  Widget _buildPaginationControls(BuildContext context, CourseState state, CourseNotifier notifier, int totalPages) {
    final startIndex = (state.currentPage - 1) * state.itemsPerPage + 1;
    final endIndex = (startIndex + state.itemsPerPage - 1).clamp(0, notifier.getFilteredCourses().length);
    final totalItems = notifier.getFilteredCourses().length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        border: Border(
          top: BorderSide(
            color: AppTheme.getDividerColor(context),
            width: 1,
          ),
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
                onPressed: state.currentPage < totalPages ? notifier.nextPage : null,
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

  void _handleGroupedCourseAction(BuildContext context, String action, Map<String, dynamic> groupedCourse, CourseNotifier notifier) {
    final courseCode = groupedCourse['courseCode'] as String;
    final courses = groupedCourse['courses'] as List<Course>;
    final primaryCourse = groupedCourse['primaryCourse'] as Course;
    
    switch (action) {
      case 'view':
        _showGroupedCourseDetailsDialog(context, groupedCourse);
        break;
      case 'sections':
        _showManageSectionsDialog(context, courseCode, courses, notifier);
        break;
      case 'add_section':
        _showAddSectionDialog(context, courseCode, primaryCourse, notifier);
        break;
    }
  }

  void _showCreateCourseDialog(BuildContext context, CourseNotifier notifier) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final sectionController = TextEditingController();
    
    int? selectedInstructorId;
    String selectedStatus = 'Active';
    
    final formKey = GlobalKey<FormState>();

    AppDialog.show(
      context: context,
      title: 'Add New Course',
      type: DialogType.custom,
      maxWidth: 600,
      content: StatefulBuilder(
        builder: (context, setState) {
          return Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information
                  Text(
                    'Course Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  CustomTextField(
                    controller: codeController,
                    labelText: 'Course Code',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Course code is required';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: nameController,
                    labelText: 'Course Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Course name is required';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: categoryController,
                    labelText: 'Category (Optional)',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Instructor Selection
                  Text(
                    'Instructor Assignment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Select Instructor',
                      border: OutlineInputBorder(),
                    ),
                    items: notifier.getAllTeachers().map((teacher) => 
                        DropdownMenuItem(
                          value: teacher.userId,
                          child: Text(
                            teacher.fullName,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedInstructorId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an instructor';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Status Selection
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
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
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        DialogAction.cancel(context: context),
        DialogAction.save(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop();
              
              final success = await notifier.createCourse(
                code: codeController.text,
                name: nameController.text,
                instructorUserId: selectedInstructorId!,
                category: categoryController.text.isNotEmpty ? categoryController.text : null,
                section: sectionController.text.isNotEmpty ? sectionController.text : null,
                status: selectedStatus,
                createdBy: 1, // Admin user ID
              );
              
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final courseState = ref.read(courseProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(courseState.error ?? 'Failed to create course'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }

  void _showEditCourseDialog(BuildContext context, Course course, CourseNotifier notifier) {
    final codeController = TextEditingController(text: course.code);
    final nameController = TextEditingController(text: course.name);
    final categoryController = TextEditingController(text: course.category ?? '');
    
    int? selectedInstructorId = course.instructorUserId;
    String selectedStatus = course.status;
    
    final formKey = GlobalKey<FormState>();

    AppDialog.show(
      context: context,
      title: 'Edit Course',
      type: DialogType.custom,
      maxWidth: 600,
      content: StatefulBuilder(
        builder: (context, setState) {
          return Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information
                  Text(
                    'Course Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  CustomTextField(
                    controller: codeController,
                    labelText: 'Course Code',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Course code is required';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: nameController,
                    labelText: 'Course Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Course name is required';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: categoryController,
                    labelText: 'Category (Optional)',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Instructor Selection
                  Text(
                    'Instructor Assignment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<int>(
                    initialValue: selectedInstructorId,
                    decoration: const InputDecoration(
                      labelText: 'Select Instructor',
                      border: OutlineInputBorder(),
                    ),
                    items: notifier.getAllTeachers().map((teacher) => 
                        DropdownMenuItem(
                          value: teacher.userId,
                          child: Text(
                            teacher.fullName,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedInstructorId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an instructor';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Status Selection
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
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
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
            ),
          ],
        ),
      ),
    );
        },
      ),
      actions: [
        DialogAction.cancel(context: context),
        DialogAction.save(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop();
              
              final success = await notifier.updateCourse(
                course,
                code: codeController.text,
                name: nameController.text,
                instructorUserId: selectedInstructorId,
                category: categoryController.text.isNotEmpty ? categoryController.text : null,
                status: selectedStatus,
              );
              
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final courseState = ref.read(courseProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(courseState.error ?? 'Failed to update course'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }
  void _showGroupedCourseDetailsDialog(BuildContext context, Map<String, dynamic> groupedCourse) {
    final courseCode = groupedCourse['courseCode'] as String;
    final courseName = groupedCourse['courseName'] as String;
    final sections = groupedCourse['sections'] as List<String>;
    final instructors = groupedCourse['instructors'] as List<String>;
    final category = groupedCourse['category'] as String?;
    final status = groupedCourse['status'] as String;
    final totalEnrollments = groupedCourse['totalEnrollments'] as int;
    final courses = groupedCourse['courses'] as List<Course>;

    AppDialog.show(
      context: context,
      title: 'Course Details',
      type: DialogType.info,
      maxWidth: 600,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _getCourseColor(courseCode).withValues(alpha: 0.1),
                child: Icon(
                  Icons.book,
                  color: _getCourseColor(courseCode),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courseCode,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
            const SizedBox(height: 24),
          
          // Course Information
            Text(
            'Course Information',
              style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(context, 'Category', category ?? 'Not specified', Icons.category),
          _buildInfoRow(context, 'Total Students', totalEnrollments.toString(), Icons.people),
          _buildInfoRow(context, 'Sections', sections.join(', '), Icons.group),
          _buildInfoRow(context, 'Instructors', instructors.join(', '), Icons.person),
          
          const SizedBox(height: 24),
          
          // Sections Breakdown
          Text(
            'Sections Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          
          ...courses.map((course) {
            final instructor = MockData.getUserById(course.instructorUserId);
            final enrollments = MockData.getEnrollmentsByCourse(course.courseId);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.getDividerColor(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Section ${course.section ?? 'A'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Instructor: ${instructor?.fullName ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                        Text(
                          'Students: ${enrollments.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(course.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      course.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(course.status),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      actions: [
        DialogAction.ok(),
      ],
    );
  }

  void _showManageSectionsDialog(BuildContext context, String courseCode, List<Course> courses, CourseNotifier notifier) {
    AppDialog.show(
      context: context,
      title: 'Manage Sections - $courseCode',
      type: DialogType.info,
      maxWidth: 600,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sections for $courseCode',
            style: TextStyle(
              fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
          
          ...courses.map((course) {
            final instructor = MockData.getUserById(course.instructorUserId);
            final enrollments = MockData.getEnrollmentsByCourse(course.courseId);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.getDividerColor(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            Text(
                          'Section ${course.section ?? 'A'}',
              style: TextStyle(
                fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Instructor: ${instructor?.fullName ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                        Text(
                          'Students: ${enrollments.length}',
                          style: TextStyle(
                            fontSize: 14,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showEditCourseDialog(context, course, notifier),
                        icon: Icon(Icons.edit, color: AppTheme.getSecondaryTextColor(context)),
                        tooltip: 'Edit Section',
                      ),
                      IconButton(
                        onPressed: () => _showDeleteConfirmationDialog(context, course, notifier),
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Section',
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      actions: [
        DialogAction.ok(),
      ],
    );
  }

  void _showAddSectionDialog(BuildContext context, String courseCode, Course primaryCourse, CourseNotifier notifier) {
    final sectionController = TextEditingController();
    int? selectedInstructorId;
    
    final formKey = GlobalKey<FormState>();
    
    AppDialog.show(
      context: context,
      title: 'Add New Section - $courseCode',
      type: DialogType.info,
      maxWidth: 500,
      content: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a new section for $courseCode',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 20),
            
            CustomTextField(
              controller: sectionController,
              labelText: 'Section',
              hintText: 'e.g., CS31B, IT21C',
              prefixIcon: Icons.group,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Section is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Instructor Selection
            Text(
              'Assign Instructor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            
            DropdownButtonFormField<int>(
              initialValue: selectedInstructorId,
              decoration: InputDecoration(
                labelText: 'Select Instructor',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppTheme.getCardColor(context),
              ),
              items: notifier.getAllTeachers().map((teacher) {
                return DropdownMenuItem<int>(
                  value: teacher.userId,
                  child: Text(
                    teacher.fullName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getTextColor(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                selectedInstructorId = value;
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select an instructor';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        DialogAction.cancel(),
        DialogAction.confirm(
          text: 'Add Section',
          onPressed: () async {
            if (formKey.currentState!.validate() && selectedInstructorId != null) {
              final success = await notifier.createCourse(
                code: courseCode,
                name: primaryCourse.name,
                instructorUserId: selectedInstructorId!,
                category: primaryCourse.category,
                section: sectionController.text,
                status: primaryCourse.status,
                createdBy: 1, // Admin user ID
              );
              
              if (success && context.mounted) {
                Navigator.of(context).pop();
                AppDialog.show(
                  context: context,
                  title: 'Success',
                  type: DialogType.success,
                  content: Text('Section ${sectionController.text} added successfully!'),
                  actions: [DialogAction.ok()],
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.getSecondaryTextColor(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Course course, CourseNotifier notifier) {
    DialogUtils.showConfirmation(
      context: context,
      title: 'Delete Course',
      message: 'Are you sure you want to delete "${course.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    ).then((confirmed) async {
      if (confirmed == true) {
        final success = await notifier.deleteCourse(course);
        
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${course.name} has been deleted'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            final courseState = ref.read(courseProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(courseState.error ?? 'Failed to delete course'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
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