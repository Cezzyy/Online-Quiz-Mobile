import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../models/student.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/app_theme.dart';
import '../../providers/course_provider.dart';

class ViewStudentsScreen extends ConsumerStatefulWidget {
  final Course course;

  const ViewStudentsScreen({
    super.key,
    required this.course,
  });

  @override
  ConsumerState<ViewStudentsScreen> createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends ConsumerState<ViewStudentsScreen> {
  String selectedSection = 'All';
  List<String> sections = ['All'];
  List<Map<String, dynamic>> enrolledStudents = [];
  List<Map<String, dynamic>> filteredStudents = [];
  
  // Search and pagination
  final TextEditingController _searchController = TextEditingController();
  int currentPage = 0;
  static const int studentsPerPage = 50;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadStudents() {
    final courseNotifier = ref.read(courseProvider.notifier);
    final students = courseNotifier.getEnrolledStudentsWithDetails(widget.course.courseId);
    
    final sectionsSet = <String>{'All'};
    for (final studentData in students) {
      final student = studentData['student'] as Student?;
      if (student?.section != null && student!.section!.isNotEmpty) {
        sectionsSet.add(student.section!);
      }
    }

    setState(() {
      enrolledStudents = students;
      sections = sectionsSet.toList()..sort();
      _applyFilters();
    });
  }

  void _onSearchChanged() {
    setState(() {
      currentPage = 0;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = enrolledStudents;

    // Apply section filter
    if (selectedSection != 'All') {
      filtered = filtered.where((studentData) {
        final student = studentData['student'] as Student?;
        return student?.section == selectedSection;
      }).toList();
    }

    // Apply search filter
    final searchTerm = _searchController.text.toLowerCase().trim();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((studentData) {
        final user = studentData['user'] as User;
        final student = studentData['student'] as Student?;
        
        return user.fullName.toLowerCase().contains(searchTerm) ||
               user.email.toLowerCase().contains(searchTerm) ||
               (student?.studentId.toLowerCase().contains(searchTerm) ?? false);
      }).toList();
    }

    filteredStudents = filtered;
  }

  List<Map<String, dynamic>> get paginatedStudents {
    final startIndex = currentPage * studentsPerPage;
    final endIndex = (startIndex + studentsPerPage).clamp(0, filteredStudents.length);
    
    if (startIndex >= filteredStudents.length) {
      return [];
    }
    
    return filteredStudents.sublist(startIndex, endIndex);
  }

  int get totalPages => (filteredStudents.length / studentsPerPage).ceil();

  bool get hasNextPage => currentPage < totalPages - 1;
  bool get hasPreviousPage => currentPage > 0;

  @override
  Widget build(BuildContext context) {
    final paginated = paginatedStudents;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'View Students',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          // Course Information Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.getCourseColor(widget.course.code).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.class_,
                    color: AppTheme.getCourseColor(widget.course.code),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.course.code,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getCourseColor(widget.course.code),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.course.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                // Search Bar
                CustomTextField(
                  controller: _searchController,
                  labelText: 'Search Students',
                  hintText: 'Search by name, email, or student ID...',
                  prefixIcon: Icons.search,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
                
                const SizedBox(height: 16),
                
                // Section Dropdown and Results Info
                Row(
                  children: [
                    // Section Dropdown
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSection,
                            isExpanded: true,
                            hint: const Text('Select Section'),
                            items: sections.map((String section) {
                              return DropdownMenuItem<String>(
                                value: section,
                                child: Text(
                                  section == 'All' ? 'All Sections' : section,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedSection = newValue;
                                  currentPage = 0;
                                  _applyFilters();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Results Info
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${filteredStudents.length} student${filteredStudents.length != 1 ? 's' : ''} found',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: filteredStudents.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      // Students List
                      Expanded(
                        child: _buildStudentsList(paginated),
                      ),
                              
                              // Pagination
                              if (totalPages > 1) _buildPagination(),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    if (_searchController.text.isNotEmpty) {
      message = 'No students found matching "${_searchController.text}".';
    } else if (selectedSection == 'All') {
      message = 'No students are currently enrolled in this course.';
    } else {
      message = 'No students found in section $selectedSection for this course.';
    }

    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'No Students Found',
      message: message,
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          ElevatedButton.icon(
            onPressed: hasPreviousPage
                ? () {
                    setState(() {
                      currentPage--;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPreviousPage 
                  ? AppTheme.primaryColor 
                  : Theme.of(context).disabledColor,
              foregroundColor: Colors.white,
            ),
          ),

          // Page Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page ${currentPage + 1} of $totalPages',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Next Button
          ElevatedButton.icon(
            onPressed: hasNextPage
                ? () {
                    setState(() {
                      currentPage++;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasNextPage 
                  ? AppTheme.primaryColor 
                  : Theme.of(context).disabledColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(List<Map<String, dynamic>> students) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final studentData = students[index];
        final user = studentData['user'] as User;
        final student = studentData['student'] as Student?;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildStudentCard(user, student),
        );
      },
    );
  }

  Widget _buildStudentCard(User user, Student? student) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                user.fullName.split(' ').map((name) => name[0]).take(2).join(),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (student?.studentId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${student!.studentId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Student Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (student?.section != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.getCourseColor(widget.course.code).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      student!.section!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getCourseColor(widget.course.code),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (student?.yearLevel != null) ...[
                  Text(
                    'Year ${student!.yearLevel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive 
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: user.isActive 
                          ? AppTheme.successColor
                          : Colors.grey,
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
}