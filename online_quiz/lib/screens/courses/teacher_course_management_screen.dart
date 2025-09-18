import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/mock_data.dart';
import '../../utils/app_theme.dart';
import 'course_detail_screen.dart';

class TeacherCourseManagementScreen extends ConsumerStatefulWidget {
  const TeacherCourseManagementScreen({super.key});

  @override
  ConsumerState<TeacherCourseManagementScreen> createState() => _TeacherCourseManagementScreenState();
}

class _TeacherCourseManagementScreenState extends ConsumerState<TeacherCourseManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize courses when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.read(courseProvider.notifier).initializeCourses(currentUser.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to continue')),
      );
    }

    // Get courses taught by this teacher
    final teacherCourses = ref.read(courseProvider.notifier).getCoursesByInstructor(currentUser.userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Courses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(courseProvider.notifier).refreshCourses(currentUser.userId);
            },
          ),
        ],
      ),
      body: courseState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : courseState.error != null
              ? _buildErrorState(currentUser)
              : teacherCourses.isEmpty
                  ? _buildEmptyState()
                  : _buildCoursesList(teacherCourses, currentUser),
    );
  }

  Widget _buildErrorState(User currentUser) {
    final courseState = ref.watch(courseProvider);
    
    return Center(
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
            'Error loading courses',
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
              ref.read(courseProvider.notifier).refreshCourses(currentUser.userId);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No courses assigned',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Contact your administrator to get courses assigned to you.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(List<Course> courses, User currentUser) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(course, currentUser);
      },
    );
  }

  Widget _buildCourseCard(Course course, User currentUser) {
    final enrolledStudents = ref.read(courseProvider.notifier).getEnrolledStudents(course.courseId);
    final courseQuizzes = MockData.getQuizzesByCourse(course.courseId);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCourseColor(course.code).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.book,
                      color: _getCourseColor(course.code),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.code,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Course Stats
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.people,
                    label: '${enrolledStudents.length} Students',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    icon: Icons.quiz,
                    label: '${courseQuizzes.length} Quizzes',
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showStudentManagementDialog(course, currentUser),
                      icon: const Icon(Icons.people_alt, size: 18),
                      label: const Text('Manage Students'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _getCourseColor(course.code),
                        side: BorderSide(color: _getCourseColor(course.code)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(course: course),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getCourseColor(course.code),
                        foregroundColor: Colors.white,
                      ),
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

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentManagementDialog(Course course, User currentUser) {
    showDialog(
      context: context,
      builder: (context) => StudentManagementDialog(
        course: course,
        teacherId: currentUser.userId,
      ),
    );
  }

  Color _getCourseColor(String courseCode) {
    return AppTheme.getCourseColor(courseCode);
  }
}

class StudentManagementDialog extends ConsumerStatefulWidget {
  final Course course;
  final int teacherId;

  const StudentManagementDialog({
    super.key,
    required this.course,
    required this.teacherId,
  });

  @override
  ConsumerState<StudentManagementDialog> createState() => _StudentManagementDialogState();
}

class _StudentManagementDialogState extends ConsumerState<StudentManagementDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enrolledStudents = ref.read(courseProvider.notifier).getEnrolledStudents(widget.course.courseId);
    final availableStudents = ref.read(courseProvider.notifier).getAvailableStudents(widget.course.courseId);

    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Students',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.course.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Enrolled (${enrolledStudents.length})'),
                Tab(text: 'Available (${availableStudents.length})'),
              ],
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEnrolledStudentsList(enrolledStudents),
                  _buildAvailableStudentsList(availableStudents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledStudentsList(List<User> students) {
    if (students.isEmpty) {
      return const Center(
        child: Text('No students enrolled in this course'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentTile(
          student: student,
          isEnrolled: true,
          onAction: () => _removeStudent(student),
        );
      },
    );
  }

  Widget _buildAvailableStudentsList(List<User> students) {
    if (students.isEmpty) {
      return const Center(
        child: Text('All students are already enrolled'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _buildStudentTile(
          student: student,
          isEnrolled: false,
          onAction: () => _enrollStudent(student),
        );
      },
    );
  }

  Widget _buildStudentTile({
    required User student,
    required bool isEnrolled,
    required VoidCallback onAction,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : 'S',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(student.fullName),
        subtitle: Text(student.email),
        trailing: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                onPressed: onAction,
                icon: Icon(
                  isEnrolled ? Icons.remove_circle : Icons.add_circle,
                  color: isEnrolled ? Colors.red : Colors.green,
                ),
              ),
      ),
    );
  }

  Future<void> _enrollStudent(User student) async {
    setState(() => _isLoading = true);
    
    final success = await ref.read(courseProvider.notifier).enrollStudentInCourse(
      student.userId,
      widget.course.courseId,
      widget.teacherId,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} enrolled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the dialog
      } else {
        final error = ref.read(courseProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to enroll student'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeStudent(User student) async {
    setState(() => _isLoading = true);
    
    final success = await ref.read(courseProvider.notifier).removeStudentFromCourse(
      student.userId,
      widget.course.courseId,
      widget.teacherId,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} removed successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {}); // Refresh the dialog
      } else {
        final error = ref.read(courseProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to remove student'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}