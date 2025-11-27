import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class EditCourseSectionScreen extends ConsumerStatefulWidget {
  final Course course;

  const EditCourseSectionScreen({super.key, required this.course});

  @override
  ConsumerState<EditCourseSectionScreen> createState() =>
      _EditCourseSectionScreenState();
}

class _EditCourseSectionScreenState
    extends ConsumerState<EditCourseSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _sectionController;

  int? _selectedInstructorId;
  String _selectedStatus = 'Active';
  List<User> _teachers = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.course.code);
    _nameController = TextEditingController(text: widget.course.name);
    _categoryController =
        TextEditingController(text: widget.course.category ?? '');
    _sectionController =
        TextEditingController(text: widget.course.section ?? '');
    _selectedInstructorId = widget.course.instructorUserId;
    _selectedStatus = widget.course.status;
    _loadTeachers();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    try {
      final teachers =
          await ref.read(courseProvider.notifier).getAllTeachers();
      if (mounted) {
        setState(() {
          _teachers = teachers;
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
            content: Text('Failed to load teachers: $e'),
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
        title: Text('Edit Section ${widget.course.section ?? 'A'}'),
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
                      // Course Information Card
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
                                'Course Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: _codeController,
                                labelText: 'Course Code',
                                enabled: false,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Course code is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _nameController,
                                labelText: 'Course Name',
                                enabled: false,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Course name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _categoryController,
                                labelText: 'Category (Optional)',
                                enabled: false,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _sectionController,
                                labelText: 'Section',
                                enabled: false,
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
                                          style: const TextStyle(fontSize: 14),
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
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Status Selection Card
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
                                'Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedStatus,
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.getCardColor(context),
                                  prefixIcon: Icon(_getStatusIcon(
                                      _selectedStatus)),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Active',
                                    child: Text('Active',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Inactive',
                                    child: Text('Inactive',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Archived',
                                    child: Text('Archived',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Save Button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
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
                                'Save Changes',
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

  Future<void> _handleSave() async {
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
      await notifier.updateCourse(
        courseId: widget.course.courseId,
        code: widget.course.code,
        name: widget.course.name,
        instructorUserId: _selectedInstructorId!,
        category: widget.course.category,
        section: widget.course.section,
        status: _selectedStatus,
        updatedBy: admin.userId,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Section updated successfully!'),
            backgroundColor: Colors.green,
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
            content: Text('Failed to update section: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
