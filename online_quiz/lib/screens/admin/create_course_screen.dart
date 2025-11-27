import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../models/user.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dialog.dart';

class CreateCourseScreen extends ConsumerStatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  ConsumerState<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sectionController = TextEditingController();

  List<User> _teachers = [];
  List<String> _availableSections = [];
  int? _selectedInstructorId;
  String _selectedStatus = 'Active';
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final teachers = await ref.read(courseProvider.notifier).getAllTeachers();
      final sections = await ref.read(courseProvider.notifier).getAvailableSections();
      
      if (mounted) {
        setState(() {
          _teachers = teachers;
          _availableSections = sections;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        AppDialog.show(
          context: context,
          title: 'Error',
          subtitle: 'Failed to load initial data: $e',
          type: DialogType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Course'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading teachers and sections...'),
                ],
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Information Card
                      _buildSectionCard(
                        title: 'Course Information',
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _codeController,
                              labelText: 'Course Code',
                              hintText: 'e.g., CS101, IT201',
                              prefixIcon: Icons.code,
                              validator: _validateRequired,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _nameController,
                              labelText: 'Course Name',
                              hintText: 'e.g., Introduction to Programming',
                              prefixIcon: Icons.book_outlined,
                              validator: _validateRequired,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _categoryController,
                              labelText: 'Category',
                              hintText: 'e.g., Computer Science, Math (Optional)',
                              prefixIcon: Icons.category_outlined,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Instructor Assignment Card
                      _buildSectionCard(
                        title: 'Instructor & Section Assignment',
                        child: Column(
                          children: [
                            DropdownButtonFormField<int>(
                              initialValue: _selectedInstructorId,
                              decoration: InputDecoration(
                                labelText: 'Select Instructor *',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: AppTheme.getSurfaceColor(context),
                              ),
                              hint: const Text('Choose a teacher'),
                              isExpanded: true,
                              items: _teachers.isEmpty
                                  ? [
                                      const DropdownMenuItem(
                                        value: null,
                                        enabled: false,
                                        child: Text(
                                          'No teachers available',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ]
                                  : _teachers
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
                            const SizedBox(height: 16),
                            _availableSections.isEmpty
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomTextField(
                                        controller: _sectionController,
                                        labelText: 'Section',
                                        hintText: 'e.g., A, B, C',
                                        prefixIcon: Icons.class_outlined,
                                        validator: _validateRequired,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No existing sections found. Enter a new section.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.getTextColor(context)
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          labelText: 'Section *',
                                          prefixIcon: const Icon(Icons.class_outlined),
                                          helperText: 'From existing student records',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: AppTheme.getSurfaceColor(context),
                                        ),
                                        hint: const Text('Select a section'),
                                        items: _availableSections
                                            .map(
                                              (section) => DropdownMenuItem(
                                                value: section,
                                                child: Text(
                                                  section,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _sectionController.text = value ?? '';
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a section';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _availableSections = [];
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            'Or enter a custom section',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Status Selection Card
                      _buildSectionCard(
                        title: 'Course Status',
                        child: Column(
                          children: [
                            _buildStatusOption(
                              status: 'Active',
                              icon: Icons.check_circle_outline,
                              title: 'Active',
                              subtitle: 'Course is currently active and visible',
                            ),
                            const SizedBox(height: 12),
                            _buildStatusOption(
                              status: 'Inactive',
                              icon: Icons.pause_circle_outline,
                              title: 'Inactive',
                              subtitle: 'Course is paused but not archived',
                            ),
                            const SizedBox(height: 12),
                            _buildStatusOption(
                              status: 'Archived',
                              icon: Icons.archive_outlined,
                              title: 'Archived',
                              subtitle: 'Course is no longer active',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Create Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleCreateCourse,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Create Course',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
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

  Widget _buildStatusOption({
    required String status,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.getDividerColor(context),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            RadioGroup<String>(
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
              child: Radio<String>(
                value: status,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.getTextColor(context).withValues(alpha: 0.6),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.getTextColor(context).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Validation methods
  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Future<void> _handleCreateCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) {
      AppDialog.show(
        context: context,
        title: 'Error',
        subtitle: 'No authenticated user found',
        type: DialogType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final courseNotifier = ref.read(courseProvider.notifier);
      
      final success = await courseNotifier.createCourse(
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        instructorUserId: _selectedInstructorId!,
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        section: _sectionController.text.trim(),
        status: _selectedStatus,
        createdBy: currentUser.userId,
      );

      if (!mounted) return;
      
      if (success) {
        AppDialog.show(
          context: context,
          title: 'Success',
          subtitle: 'Course created successfully',
          type: DialogType.success,
        ).then((_) {
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        });
      } else {
        AppDialog.show(
          context: context,
          title: 'Error',
          subtitle: 'Failed to create course',
          type: DialogType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          context: context,
          title: 'Error',
          subtitle: 'Failed to create course: $e',
          type: DialogType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
