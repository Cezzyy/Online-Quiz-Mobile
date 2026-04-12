import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../models/user.dart';
import '../../models/teacher.dart';
import '../../models/student.dart';
import '../../providers/user_management_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dialog.dart';

class EditUserScreen extends ConsumerStatefulWidget {
  final User user;

  const EditUserScreen({super.key, required this.user});

  @override
  ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends ConsumerState<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _emergencyPersonController = TextEditingController();
  final _departmentController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _sectionController = TextEditingController();
  final _courseController = TextEditingController();

  String _selectedStatus = 'Active';
  int _selectedYearLevel = 1;
  String? _selectedCourse;
  String? _selectedDepartment;
  bool _isLoading = false;

  String _userRole = 'User';
  Teacher? _teacher;
  Student? _student;

  // Student Course options
  final List<String> _studentCourses = [
    'BS Computer Science',
    'BS Information Technology',
    'BS Information System',
    'BS Business Administration',
    'BS Accountancy',
  ];

  // Teacher Department options
  final List<String> _teacherDepartments = [
    'General Education',
    'Computer Science',
    'Information Technology',
    'Business',
    'Accountancy',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final userState = ref.read(userManagementProvider);

    // Set basic info
    _emailController.text = widget.user.email;
    _fullNameController.text = widget.user.fullName;
    _contactController.text = widget.user.contactNumber;
    _emergencyController.text = widget.user.emergencyContactNumber;
    _emergencyPersonController.text = widget.user.emergencyContactPerson;
    _selectedStatus = widget.user.status;

    // Determine user role and set role-specific data
    if (userState.teachers.any((t) => t.userId == widget.user.userId)) {
      _userRole = 'Teacher';
      _teacher = userState.teachers.firstWhere(
        (t) => t.userId == widget.user.userId,
      );
      _selectedDepartment = _teacher!.department;
    } else if (userState.students.any((s) => s.userId == widget.user.userId)) {
      _userRole = 'Student';
      _student = userState.students.firstWhere(
        (s) => s.userId == widget.user.userId,
      );
      _studentIdController.text = _student!.studentId;
      _selectedYearLevel = _student!.yearLevel ?? 1;
      _sectionController.text = _student!.section ?? '';

      // Handle course selection safely
      final course = _student!.course;
      if (course != null && course.isNotEmpty) {
        if (_studentCourses.contains(course)) {
          _selectedCourse = course;
        } else {
          // Try to find a match (e.g., "Computer Science" -> "BS Computer Science")
          final match = _studentCourses.firstWhere(
            (c) =>
                c.toLowerCase().contains(course.toLowerCase()) ||
                course.toLowerCase().contains(c.toLowerCase()),
            orElse: () => '',
          );

          if (match.isNotEmpty) {
            _selectedCourse = match;
          } else {
            // If no match found, add it to the list to prevent crash
            setState(() {
              _studentCourses.add(course);
              _selectedCourse = course;
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _contactController.dispose();
    _emergencyController.dispose();
    _departmentController.dispose();
    _studentIdController.dispose();
    _sectionController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Header
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
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            widget.user.fullName.isNotEmpty
                                ? widget.user.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editing $_userRole Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.user.fullName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.getSecondaryTextColor(
                                    context,
                                  ),
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

                // Status Selection Card
                _buildSectionCard(
                  title: 'Account Status',
                  child: Column(
                    children: [
                      _buildStatusOption(
                        status: 'Active',
                        icon: Icons.check_circle_outline,
                        title: 'Active',
                        subtitle: 'User can access the system',
                      ),
                      const SizedBox(height: 12),
                      _buildStatusOption(
                        status: 'Inactive',
                        icon: Icons.cancel_outlined,
                        title: 'Inactive',
                        subtitle: 'User cannot access the system',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Basic Information Card
                _buildSectionCard(
                  title: 'Basic Information',
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'example@university.edu',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _fullNameController,
                        labelText: 'Full Name',
                        hintText: 'John Doe',
                        prefixIcon: Icons.person_outline,
                        validator: _validateRequired,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Contact Information Card
                _buildSectionCard(
                  title: 'Contact Information',
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _contactController,
                        labelText: 'Contact Number',
                        hintText: '+639123456789',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emergencyPersonController,
                        labelText: 'Emergency Contact Person',
                        hintText: 'Enter name of emergency contact',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Emergency contact person is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emergencyController,
                        labelText: 'Emergency Contact Number',
                        hintText: '+639987654321',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.emergency_outlined,
                        validator: _validatePhone,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Role-specific Information Card
                if (_userRole == 'Student')
                  _buildStudentInformationCard()
                else if (_userRole == 'Teacher')
                  _buildTeacherInformationCard(),

                const SizedBox(height: 32),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleUpdateUser,
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
                            'Update User',
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

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: Radio<String>(value: status),
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
                      color: AppTheme.getTextColor(
                        context,
                      ).withValues(alpha: 0.6),
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

  Widget _buildStudentInformationCard() {
    return _buildSectionCard(
      title: 'Student Information',
      child: Column(
        children: [
          CustomTextField(
            controller: _studentIdController,
            labelText: 'Student ID',
            hintText: 'e.g., 2024-00001',
            prefixIcon: Icons.badge_outlined,
            validator: _validateRequired,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedYearLevel,
            decoration: InputDecoration(
              labelText: 'Year Level',
              prefixIcon: const Icon(Icons.school_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.getSurfaceColor(context),
            ),
            items: List.generate(4, (index) => index + 1)
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text('Year $level'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedYearLevel = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _sectionController,
            labelText: 'Section',
            hintText: 'e.g., A, B, C',
            prefixIcon: Icons.class_outlined,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedCourse,
            decoration: InputDecoration(
              labelText: 'Course *',
              prefixIcon: const Icon(Icons.menu_book_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.getSurfaceColor(context),
            ),
            hint: const Text('Select a course'),
            items: _studentCourses
                .map(
                  (course) => DropdownMenuItem(
                    value: course,
                    child: Text(
                      course,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCourse = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a course';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherInformationCard() {
    return _buildSectionCard(
      title: 'Teacher Information',
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedDepartment,
        decoration: InputDecoration(
          labelText: 'Department *',
          prefixIcon: const Icon(Icons.business_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppTheme.getSurfaceColor(context),
        ),
        hint: const Text('Select a department'),
        items: _teacherDepartments
            .map(
              (dept) => DropdownMenuItem(
                value: dept,
                child: Text(
                  dept,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedDepartment = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a department';
          }
          return null;
        },
      ),
    );
  }

  // Validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,13}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  Future<void> _handleUpdateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(userManagementProvider.notifier);

      await notifier.updateUser(
        widget.user,
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        emergencyContactNumber: _emergencyController.text.trim(),
        emergencyContactPerson: _emergencyPersonController.text.trim(),
        status: _selectedStatus,
        // Student-specific fields
        studentId: _userRole == 'Student'
            ? _studentIdController.text.trim()
            : null,
        yearLevel: _userRole == 'Student' ? _selectedYearLevel : null,
        section: _userRole == 'Student' ? _sectionController.text.trim() : null,
        course: _userRole == 'Student' ? _selectedCourse : null,
        // Teacher-specific fields
        department: _userRole == 'Teacher' ? _selectedDepartment : null,
      );

      if (!mounted) return;

      AppDialog.show(
        context: context,
        title: 'Success',
        subtitle: 'User updated successfully',
        type: DialogType.success,
      ).then((_) {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      });
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          context: context,
          title: 'Error',
          subtitle: 'Failed to update user: $e',
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
