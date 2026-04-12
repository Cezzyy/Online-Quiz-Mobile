import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../providers/user_management_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dialog.dart';

class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _emergencyPersonController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _sectionController = TextEditingController();

  UserType _selectedUserType = UserType.students;
  int _selectedYearLevel = 1;
  String? _selectedCourse;
  String? _selectedDepartment;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _contactController.dispose();
    _emergencyController.dispose();
    _studentIdController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New User'),
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
                // User Type Selection Card
                _buildSectionCard(
                  title: 'User Type',
                  child: Column(
                    children: [
                      _buildUserTypeOption(
                        userType: UserType.students,
                        icon: Icons.person,
                        title: 'Student',
                        subtitle: 'Create a student account',
                      ),
                      const SizedBox(height: 12),
                      _buildUserTypeOption(
                        userType: UserType.teachers,
                        icon: Icons.school,
                        title: 'Teacher',
                        subtitle: 'Create a teacher account',
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
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Minimum 6 characters',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter password',
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: _validateConfirmPassword,
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
                        controller: _emergencyController,
                        labelText: 'Emergency Contact',
                        hintText: '+639987654321',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.emergency_outlined,
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Role-specific Information Card
                if (_selectedUserType == UserType.students)
                  _buildStudentInformationCard()
                else
                  _buildTeacherInformationCard(),

                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateUser,
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create User',
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

  Widget _buildUserTypeOption({
    required UserType userType,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedUserType == userType;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedUserType = userType;
          // Reset role-specific fields
          _selectedCourse = null;
          _selectedDepartment = null;
          _studentIdController.clear();
          _sectionController.clear();
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
            RadioGroup<UserType>(
              groupValue: _selectedUserType,
              onChanged: (value) {
                setState(() {
                  _selectedUserType = value!;
                  // Reset role-specific fields
                  _selectedCourse = null;
                  _selectedDepartment = null;
                  _studentIdController.clear();
                  _sectionController.clear();
                });
              },
              child: Radio<UserType>(
                value: userType,
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
        initialValue: _selectedDepartment,
        decoration: InputDecoration(
          labelText: 'Department *',
          prefixIcon: const Icon(Icons.business_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
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

  Future<void> _handleCreateUser() async {
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
      final notifier = ref.read(userManagementProvider.notifier);
      
      await notifier.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        emergencyContactNumber: _emergencyController.text.trim(),
        emergencyContactPerson: _emergencyPersonController.text.trim(),
        userType: _selectedUserType,
        createdBy: currentUser.userId,
        // Student-specific fields
        studentId: _selectedUserType == UserType.students
            ? _studentIdController.text.trim()
            : null,
        yearLevel: _selectedUserType == UserType.students
            ? _selectedYearLevel
            : null,
        section: _selectedUserType == UserType.students
            ? _sectionController.text.trim()
            : null,
        course: _selectedUserType == UserType.students
            ? _selectedCourse
            : null,
        // Teacher-specific fields
        department: _selectedUserType == UserType.teachers
            ? _selectedDepartment
            : null,
      );

      if (!mounted) return;
      
      AppDialog.show(
        context: context,
        title: 'Success',
        subtitle: 'User created successfully',
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
          subtitle: 'Failed to create user: $e',
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
