import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../providers/course_provider.dart';

class CourseDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> groupedCourse;

  const CourseDetailsScreen({super.key, required this.groupedCourse});

  @override
  ConsumerState<CourseDetailsScreen> createState() =>
      _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends ConsumerState<CourseDetailsScreen> {
  final Map<int, Map<String, dynamic>> _courseDetailsCache = {};

  @override
  Widget build(BuildContext context) {
    final courseCode = widget.groupedCourse['courseCode'] as String;
    final courseName = widget.groupedCourse['courseName'] as String;
    final sections = widget.groupedCourse['sections'] as List<String>;
    final category = widget.groupedCourse['category'] as String?;
    final status = widget.groupedCourse['status'] as String;
    final totalEnrollments = widget.groupedCourse['totalEnrollments'] as int;
    final courses = widget.groupedCourse['courses'] as List<Course>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            _getCourseColor(courseCode).withValues(alpha: 0.1),
                        child: Icon(
                          Icons.book,
                          color: _getCourseColor(courseCode),
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courseName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              courseCode,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(status),
                                    size: 16,
                                    color: _getStatusColor(status),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                                ],
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

              // Course Information Card
              _buildSectionCard(
                title: 'Course Information',
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      'Category',
                      category ?? 'Not specified',
                      Icons.category,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      'Total Students',
                      totalEnrollments.toString(),
                      Icons.people,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      'Sections',
                      sections.join(', '),
                      Icons.group,
                    ),
                    const SizedBox(height: 16),
                    _buildInstructorsRow(context, courses),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sections Breakdown Card
              _buildSectionCard(
                title: 'Sections Breakdown',
                child: Column(
                  children: courses.map((course) {
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _loadCourseDetails(course),
                      builder: (context, snapshot) {
                        final instructor =
                            snapshot.data?['instructor'] as User?;
                        final enrollmentCount =
                            snapshot.data?['enrollmentCount'] as int? ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.getDividerColor(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 60,
                                  minHeight: 50,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    course.section ?? 'A',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: AppTheme
                                              .getSecondaryTextColor(context),
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
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 16,
                                          color: AppTheme
                                              .getSecondaryTextColor(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$enrollmentCount students',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppTheme
                                                .getSecondaryTextColor(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(course.status)
                                      .withValues(alpha: 0.1),
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
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorsRow(BuildContext context, List<Course> courses) {
    // Get unique instructor user IDs
    final instructorIds = courses.map((c) => c.instructorUserId).toSet().toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructors',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                FutureBuilder<List<String>>(
                  future: _loadInstructorNames(instructorIds),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 20,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Loading...', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    }
                    
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Text(
                        'Error loading instructors',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      );
                    }
                    
                    return Text(
                      snapshot.data!.join(', '),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _loadInstructorNames(List<int> instructorIds) async {
    try {
      final notifier = ref.read(courseProvider.notifier);
      final names = <String>[];
      
      for (final id in instructorIds) {
        final instructor = await notifier.getCourseInstructor(id);
        if (instructor != null) {
          names.add(instructor.fullName);
        }
      }
      
      return names;
    } catch (e) {
      return ['Error loading names'];
    }
  }

  Future<Map<String, dynamic>> _loadCourseDetails(Course course) async {
    // Check cache first
    if (_courseDetailsCache.containsKey(course.courseId)) {
      return _courseDetailsCache[course.courseId]!;
    }

    try {
      final notifier = ref.read(courseProvider.notifier);
      final instructor =
          await notifier.getCourseInstructor(course.instructorUserId);
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

  Color _getCourseColor(String courseCode) {
    final colors = [
      AppTheme.primaryColor,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.blue,
      Colors.red,
    ];
    final hash = courseCode.hashCode.abs();
    return colors[hash % colors.length];
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'inactive':
        return Icons.pause_circle;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.info;
    }
  }
}
