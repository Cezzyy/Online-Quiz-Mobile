import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../models/student.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/app_theme.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';

class ManageCourseScreen extends ConsumerStatefulWidget {
  final Course course;

  const ManageCourseScreen({
    super.key,
    required this.course,
  });

  @override
  ConsumerState<ManageCourseScreen> createState() => _ManageCourseScreenState();
}

class _ManageCourseScreenState extends ConsumerState<ManageCourseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedSection = 'All';
  String selectedYearLevel = 'All';
  List<String> sections = ['All'];
  List<String> yearLevels = ['All'];
  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> enrolledStudents = [];
  Set<int> selectedStudentIds = {};
  bool isLoading = false;

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

  void _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final courseNotifier = ref.read(courseProvider.notifier);
      
      // Load enrolled students using course provider
      final enrolled = await courseNotifier.getEnrolledStudentsWithDetails(widget.course.courseId);
      
      // Load available students (not enrolled in this course) using course provider
      final availableStudentsData = await courseNotifier.getAvailableStudents(widget.course.courseId);
      final students = <Map<String, dynamic>>[];
      
      // Convert available students data to the expected format with Student objects
      for (final studentData in availableStudentsData) {
        final user = studentData['user'] as User;
        final student = Student(
          userId: user.userId,
          studentId: studentData['studentId'] as String,
          yearLevel: studentData['yearLevel'] as int?,
          section: studentData['section'] as String?,
          course: studentData['course'] as String?,
        );
        
        students.add({
          'user': user,
          'student': student,
        });
      }
      
      // Build sections and year levels sets
      final sectionsSet = <String>{'All'};
      final yearLevelsSet = <String>{'All'};
      
      // Add sections and year levels from both enrolled and available students
      for (final studentData in [...enrolled, ...students]) {
        final student = studentData['student'] as Student?;
        if (student?.section != null && student!.section!.isNotEmpty) {
          sectionsSet.add(student.section!);
        }
        if (student?.yearLevel != null) {
          yearLevelsSet.add(student!.yearLevel.toString());
        }
      }

      if (mounted) {
        setState(() {
          allStudents = students;
          enrolledStudents = enrolled;
          sections = sectionsSet.toList()..sort();
          yearLevels = yearLevelsSet.toList()..sort((a, b) {
            if (a == 'All') return -1;
            if (b == 'All') return 1;
            return int.tryParse(a)?.compareTo(int.tryParse(b) ?? 0) ?? 0;
          });
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
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

  List<Map<String, dynamic>> get filteredStudents {
    var filtered = allStudents.where((studentData) {
      final user = studentData['user'] as User;
      final student = studentData['student'] as Student?;
      
      // Check if already enrolled
      final isEnrolled = enrolledStudents.any((enrolled) => 
          (enrolled['user'] as User).userId == user.userId);
      if (isEnrolled) return false;
      
      // Search filter
      final searchTerm = _searchController.text.toLowerCase();
      if (searchTerm.isNotEmpty) {
        final matchesName = user.fullName.toLowerCase().contains(searchTerm);
        final matchesEmail = user.email.toLowerCase().contains(searchTerm);
        final matchesStudentId = student?.studentId.toLowerCase().contains(searchTerm) ?? false;
        
        if (!matchesName && !matchesEmail && !matchesStudentId) {
          return false;
        }
      }
      
      // Section filter
      if (selectedSection != 'All') {
        if (student?.section != selectedSection) return false;
      }
      
      // Year level filter
      if (selectedYearLevel != 'All') {
        if (student?.yearLevel?.toString() != selectedYearLevel) return false;
      }
      
      return true;
    }).toList();

    return filtered;
  }

  void _toggleStudentSelection(int userId) {
    setState(() {
      if (selectedStudentIds.contains(userId)) {
        selectedStudentIds.remove(userId);
      } else {
        selectedStudentIds.add(userId);
      }
    });
  }

  void _assignSelectedStudents() async {
    if (selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one student to assign.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final courseNotifier = ref.read(courseProvider.notifier);
    final currentUser = ref.read(authProvider).user;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error')),
      );
      return;
    }

    int successCount = 0;
    int failCount = 0;

    // Enroll selected students using course provider
    for (final userId in selectedStudentIds) {
      final success = await courseNotifier.enrollStudentInCourse(
        userId, 
        widget.course.courseId, 
        currentUser.userId
      );
      
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    setState(() {
      selectedStudentIds.clear();
    });
    
    // Reload data to reflect changes
    _loadData();

    // Show result message
    if (mounted) {
      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount student(s) assigned to ${widget.course.name}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount assigned, $failCount failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _removeStudent(int userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: const Text('Are you sure you want to remove this student from the course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              navigator.pop();
              
              final courseNotifier = ref.read(courseProvider.notifier);
              final currentUser = ref.read(authProvider).user;
              
              if (currentUser == null) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Authentication error')),
                  );
                }
                return;
              }

              // Remove student using course provider
              final success = await courseNotifier.removeStudentFromCourse(
                userId, 
                widget.course.courseId, 
                currentUser.userId
              );
              
              if (mounted) {
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text('Student removed from course'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } else {
                  final error = ref.read(courseProvider).error;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Failed to remove student'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              
              _loadData();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredStudents;
    final courseState = ref.watch(courseProvider);
    
    // Show error if there's a course provider error
    if (courseState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(courseState.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                ref.read(courseProvider.notifier).clearError();
                _loadData();
              },
            ),
          ),
        );
      });
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Manage Course',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Assign Students'),
              Tab(text: 'Enrolled Students'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildAssignStudentsTab(filtered),
                  _buildEnrolledStudentsTab(),
                ],
              ),
        floatingActionButton: selectedStudentIds.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _assignSelectedStudents,
                backgroundColor: AppTheme.primaryColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Assign ${selectedStudentIds.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildAssignStudentsTab(List<Map<String, dynamic>> filtered) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: Column(
        children: [
        // Course Header
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.getCourseColor(widget.course.code).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.class_,
                  color: AppTheme.getCourseColor(widget.course.code),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.course.code,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search and Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              CustomTextField(
                controller: _searchController,
                labelText: 'Search Students',
                hintText: 'Search by name, email, or student ID',
                prefixIcon: Icons.search,
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              
              // Filters
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Section',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
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
                              menuMaxHeight: 300,
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
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Year Level',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedYearLevel,
                              isExpanded: true,
                              hint: const Text('Select Year'),
                              menuMaxHeight: 300, // Limit dropdown height to enable scrolling
                              items: yearLevels.map((String year) {
                                return DropdownMenuItem<String>(
                                  value: year,
                                  child: Text(
                                    year == 'All' ? 'All Years' : 'Year $year',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedYearLevel = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Students List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No students found matching your criteria.')
              : _buildStudentsList(filtered, true),
        ),
        ],
      ),
    );
  }

  Widget _buildEnrolledStudentsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: Column(
        children: [
        // Stats Header
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: AppTheme.successColor,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enrolled Students',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${enrolledStudents.length} students currently enrolled',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Enrolled Students List
        Expanded(
          child: enrolledStudents.isEmpty
              ? _buildEmptyState('No students are currently enrolled in this course.')
              : _buildStudentsList(enrolledStudents, false),
        ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'No Students',
      message: message,
    );
  }

  Widget _buildStudentsList(List<Map<String, dynamic>> students, bool isAssignTab) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final studentData = students[index];
        final user = studentData['user'] as User;
        final student = studentData['student'] as Student?;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildStudentCard(user, student, isAssignTab),
        );
      },
    );
  }

  Widget _buildStudentCard(User user, Student? student, bool isAssignTab) {
    final isSelected = selectedStudentIds.contains(user.userId);

    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? AppTheme.primaryColor
              : Theme.of(context).dividerColor,
          width: isSelected ? 2 : 1,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isAssignTab ? () => _toggleStudentSelection(user.userId) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Selection indicator or Avatar
                if (isAssignTab) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey,
                        width: 2,
                      ),
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 16),
                ],
                
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
                
                // Student Details and Actions
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
                      const SizedBox(height: 4),
                    ],
                    if (!isAssignTab) ...[
                      IconButton(
                        onPressed: () => _removeStudent(user.userId),
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}