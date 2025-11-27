import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../providers/course_provider.dart';
import 'edit_course_section_screen.dart';

class ManageSectionsScreen extends ConsumerStatefulWidget {
  final String courseCode;
  final List<Course> courses;

  const ManageSectionsScreen({
    super.key,
    required this.courseCode,
    required this.courses,
  });

  @override
  ConsumerState<ManageSectionsScreen> createState() =>
      _ManageSectionsScreenState();
}

class _ManageSectionsScreenState extends ConsumerState<ManageSectionsScreen> {
  final Map<int, Map<String, dynamic>> _courseDetailsCache = {};
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _courses = List.from(widget.courses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Sections - ${widget.courseCode}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: _courses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sections found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a section to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Info Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.book,
                                color: AppTheme.primaryColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.courseCode,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.getTextColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_courses.length} ${_courses.length == 1 ? 'Section' : 'Sections'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.getSecondaryTextColor(
                                          context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sections List
                    ..._courses.map((course) {
                      return FutureBuilder<Map<String, dynamic>>(
                        future: _loadCourseDetails(course),
                        builder: (context, snapshot) {
                          final instructor =
                              snapshot.data?['instructor'] as User?;
                          final enrollmentCount =
                              snapshot.data?['enrollmentCount'] as int? ?? 0;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        course.section ?? 'A',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Section ${course.section ?? 'A'}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.getTextColor(
                                                    context),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                        course.status)
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                course.status,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getStatusColor(
                                                      course.status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              size: 16,
                                              color: AppTheme
                                                  .getSecondaryTextColor(
                                                      context),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                instructor?.fullName ??
                                                    'Loading...',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme
                                                      .getSecondaryTextColor(
                                                          context),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.people_outline,
                                              size: 16,
                                              color: AppTheme
                                                  .getSecondaryTextColor(
                                                      context),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$enrollmentCount ${enrollmentCount == 1 ? 'student' : 'students'}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme
                                                    .getSecondaryTextColor(
                                                        context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            _navigateToEditSection(course),
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: AppTheme.primaryColor,
                                        ),
                                        tooltip: 'Edit Section',
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      IconButton(
                                        onPressed: () =>
                                            _showDeleteConfirmation(course),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Delete Section',
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.red.withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadCourseDetails(Course course) async {
    if (_courseDetailsCache.containsKey(course.courseId)) {
      return _courseDetailsCache[course.courseId]!;
    }

    try {
      final notifier = ref.read(courseProvider.notifier);
      final instructor = await notifier.getCourseInstructor(course.courseId);
      final enrolledStudents =
          await notifier.getEnrolledStudentsWithDetails(course.courseId);

      final details = {
        'instructor': instructor,
        'enrollmentCount': enrolledStudents.length,
      };

      _courseDetailsCache[course.courseId] = details;
      return details;
    } catch (e) {
      return {
        'instructor': null,
        'enrollmentCount': 0,
      };
    }
  }

  Future<void> _navigateToEditSection(Course course) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditCourseSectionScreen(course: course),
      ),
    );

    if (result == true && mounted) {
      // Reload the course list
      final notifier = ref.read(courseProvider.notifier);
      await notifier.loadAllCourses();
      
      // Update local courses list
      final state = ref.read(courseProvider);
      final updatedCourses = state.allCourses
          .where((c) => c.code == widget.courseCode)
          .toList();
      
      setState(() {
        _courses = updatedCourses;
        _courseDetailsCache.clear();
      });
    }
  }

  Future<void> _showDeleteConfirmation(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text(
          'Are you sure you want to delete Section ${course.section ?? 'A'}?\n\nThis action cannot be undone and will affect all enrolled students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteSection(course);
    }
  }

  Future<void> _deleteSection(Course course) async {
    try {
      final notifier = ref.read(courseProvider.notifier);
      await notifier.deleteCourse(course.courseId);

      if (mounted) {
        setState(() {
          _courses.removeWhere((c) => c.courseId == course.courseId);
          _courseDetailsCache.remove(course.courseId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Section ${course.section ?? 'A'} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete section: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
}
