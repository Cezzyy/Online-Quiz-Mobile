import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';

class AddSectionScreen extends ConsumerStatefulWidget {
  final String courseCode;
  final Course primaryCourse;

  const AddSectionScreen({
    super.key,
    required this.courseCode,
    required this.primaryCourse,
  });

  @override
  ConsumerState<AddSectionScreen> createState() => _AddSectionScreenState();
}

class _AddSectionScreenState extends ConsumerState<AddSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSection;
  int? _selectedInstructorId;
  List<String> _availableSections = [];
  List<User> _teachers = [];
  List<Course> _existingCourses = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final notifier = ref.read(courseProvider.notifier);
      final sections = await notifier.getAvailableSections();
      final teachers = await notifier.getAllTeachers();
      
      // Get existing courses for this course code
      final state = ref.read(courseProvider);
      final existingCourses = state.allCourses
          .where((c) => c.code == widget.courseCode)
          .toList();

      if (mounted) {
        setState(() {
          _availableSections = sections;
          _teachers = teachers;
          _existingCourses = existingCourses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Section - ${widget.courseCode}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Course Info Card
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
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
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
                                      widget.primaryCourse.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.getTextColor(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.courseCode,
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

                      // Section Selection Card
                      Card(
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
                                'Section Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSection,
                                decoration: InputDecoration(
                                  labelText: 'Select Section',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.getCardColor(context),
                                  prefixIcon: const Icon(Icons.group),
                                  helperText:
                                      'Available sections from student records',
                                ),
                                items: _availableSections
                                    .map(
                                      (section) => DropdownMenuItem(
                                        value: section,
                                        child: Text(
                                          section,
                                          style:
                                              const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSection = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Section is required';
                                  }
                                  
                                  // Check if section already exists for this course
                                  final sectionExists = _existingCourses
                                      .any((c) => c.section == value);
                                  if (sectionExists) {
                                    return 'This section already exists for ${widget.courseCode}';
                                  }
                                  
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Instructor Assignment Card
                      Card(
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
                                'Instructor Assignment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedInstructorId,
                                decoration: InputDecoration(
                                  labelText: 'Select Instructor',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.getCardColor(context),
                                  prefixIcon:
                                      const Icon(Icons.person_outline),
                                ),
                                items: _teachers
                                    .map(
                                      (teacher) => DropdownMenuItem(
                                        value: teacher.userId,
                                        child: Text(
                                          teacher.fullName,
                                          style:
                                              const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedInstructorId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select an instructor';
                                  }
                                  
                                  // Check if teacher+section combination already exists
                                  if (_selectedSection != null) {
                                    final combinationExists = _existingCourses.any(
                                      (c) =>
                                          c.section == _selectedSection &&
                                          c.instructorUserId == value,
                                    );
                                    if (combinationExists) {
                                      return 'This instructor is already assigned to section $_selectedSection';
                                    }
                                  }
                                  
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Each section must have a unique instructor assignment. You cannot assign the same instructor to the same section multiple times.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Add Section Button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleAddSection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Add Section',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _handleAddSection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authState = ref.read(authProvider);
      final admin = authState.user;

      if (admin == null) {
        throw Exception('User not authenticated');
      }

      final notifier = ref.read(courseProvider.notifier);
      final success = await notifier.createCourse(
        code: widget.courseCode,
        name: widget.primaryCourse.name,
        instructorUserId: _selectedInstructorId!,
        category: widget.primaryCourse.category,
        section: _selectedSection!,
        status: 'Active',
        createdBy: admin.userId,
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Section $_selectedSection added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() {
          _isSaving = false;
        });
        final courseState = ref.read(courseProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(courseState.error ?? 'Failed to add section'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add section: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
