import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../models/user.dart';
import '../../models/teacher.dart';
import '../../models/student.dart';
import '../../providers/user_management_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/info_card.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userManagementProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userManagementProvider);
    final userNotifier = ref.read(userManagementProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(context, userState, userNotifier),
            
            // Content Section
            Expanded(
              child: userState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(context, userState, userNotifier),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context, userNotifier),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserManagementState state, UserManagementNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(context, 'Total', state.users.length.toString(), Icons.people),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat(
                  context, 
                  'Admins', 
                  (state.users.length - state.teachers.length - state.students.length).toString(), 
                  Icons.admin_panel_settings
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat(context, 'Teachers', state.teachers.length.toString(), Icons.school),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat(context, 'Students', state.students.length.toString(), Icons.person),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search and Filter Section
          Column(
            children: [
              // Search Field
              TextField(
                onChanged: notifier.updateSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.getSurfaceColor(context),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // User Type Filter
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.getDividerColor(context)),
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.getSurfaceColor(context),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserType>(
                    value: state.selectedUserType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: UserType.all, child: Text('All Users')),
                      DropdownMenuItem(value: UserType.teachers, child: Text('Teachers')),
                      DropdownMenuItem(value: UserType.students, child: Text('Students')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        notifier.updateSelectedUserType(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserManagementState state, UserManagementNotifier notifier) {
    final paginatedUsers = notifier.getPaginatedUsers();
    final totalPages = notifier.getTotalPages();
    final userState = ref.watch(userManagementProvider);
    
    if (paginatedUsers.isEmpty) {
      return EmptyStateWidget(
        icon: state.searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
        title: state.searchQuery.isNotEmpty ? 'No Users Found' : 'No Users Available',
        message: state.searchQuery.isNotEmpty 
            ? 'No users match your search criteria'
            : 'Start by adding your first user',
        action: ElevatedButton.icon(
          onPressed: () => _showCreateUserDialog(context, notifier),
          icon: const Icon(Icons.person_add),
          label: const Text('Add User'),
        ),
      );
    }

    return Column(
      children: [
        // Table
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppTheme.getDividerColor(context).withValues(alpha: 0.1),
              ),
              dataRowColor: WidgetStateProperty.all(
                AppTheme.getCardColor(context),
              ),
              columnSpacing: 24,
              columns: const [
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Role',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: paginatedUsers.map((user) {
                // Determine role based on whether user is in teachers or students list
                String userRole = 'User';
                if (userState.teachers.any((t) => t.userId == user.userId)) {
                  userRole = 'Teacher';
                } else if (userState.students.any((s) => s.userId == user.userId)) {
                  userRole = 'Student';
                }
                
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            child: Text(
                              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.getTextColor(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.getSecondaryTextColor(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRoleColor(userRole).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          userRole,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getRoleColor(userRole),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'view':
                              _showUserDetailsDialog(context, user);
                              break;
                            case 'edit':
                              _showEditUserDialog(context, user, notifier);
                              break;
                            case 'delete':
                              _showDeleteConfirmationDialog(context, user, notifier);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        
        // Pagination Controls
        if (totalPages > 1) _buildPaginationControls(context, state, notifier, totalPages),
      ],
    );
  }

  Widget _buildPaginationControls(BuildContext context, UserManagementState state, UserManagementNotifier notifier, int totalPages) {
    final startIndex = (state.currentPage - 1) * state.itemsPerPage + 1;
    final endIndex = (startIndex + state.itemsPerPage - 1).clamp(0, notifier.getFilteredUsers().length);
    final totalItems = notifier.getFilteredUsers().length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        border: Border(
          top: BorderSide(
            color: AppTheme.getDividerColor(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Items info
          Text(
            'Showing $startIndex-$endIndex of $totalItems users',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 14,
            ),
          ),
          
          // Pagination controls
          Row(
            children: [
              // Previous button
              IconButton(
                onPressed: state.currentPage > 1 ? notifier.previousPage : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: state.currentPage > 1 
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
              ),
              
              // Page numbers
              ...List.generate(
                totalPages.clamp(0, 5), // Show max 5 page numbers
                (index) {
                  int pageNumber;
                  if (totalPages <= 5) {
                    pageNumber = index + 1;
                  } else {
                    // Smart pagination: show current page and surrounding pages
                    if (state.currentPage <= 3) {
                      pageNumber = index + 1;
                    } else if (state.currentPage >= totalPages - 2) {
                      pageNumber = totalPages - 4 + index;
                    } else {
                      pageNumber = state.currentPage - 2 + index;
                    }
                  }
                  
                  final isCurrentPage = pageNumber == state.currentPage;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () => notifier.goToPage(pageNumber),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCurrentPage 
                              ? AppTheme.primaryColor
                              : AppTheme.getSurfaceColor(context),
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrentPage 
                              ? null
                              : Border.all(
                                  color: AppTheme.getDividerColor(context),
                                  width: 1,
                                ),
                        ),
                        child: Center(
                          child: Text(
                            pageNumber.toString(),
                            style: TextStyle(
                              color: isCurrentPage 
                                  ? Colors.white
                                  : AppTheme.getTextColor(context),
                              fontWeight: isCurrentPage 
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Next button
              IconButton(
                onPressed: state.currentPage < totalPages ? notifier.nextPage : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: state.currentPage < totalPages 
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showCreateUserDialog(BuildContext context, UserManagementNotifier notifier) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    final contactController = TextEditingController();
    final emergencyController = TextEditingController();
    final departmentController = TextEditingController();
    final studentIdController = TextEditingController();
    final sectionController = TextEditingController();
    final courseController = TextEditingController();
    
    UserType selectedUserType = UserType.students;
    int? selectedYearLevel = 1;
    
    final formKey = GlobalKey<FormState>();

    AppDialog.show(
      context: context,
      title: 'Add New User',
      type: DialogType.custom,
      maxWidth: 600,
      content: StatefulBuilder(
        builder: (context, setState) {
          return Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Type Selection
                  Text(
                    'User Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<UserType>(
                    groupValue: selectedUserType,
                    onChanged: (value) {
                      setState(() {
                        selectedUserType = value!;
                      });
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(
                              'Student',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                            leading: Radio<UserType>(
                              value: UserType.students,
                            ),
                            onTap: () {
                              setState(() {
                                selectedUserType = UserType.students;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                              'Teacher',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                            leading: Radio<UserType>(
                              value: UserType.teachers,
                            ),
                            onTap: () {
                              setState(() {
                                selectedUserType = UserType.teachers;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Basic Information
                  Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  CustomTextField(
                    controller: emailController,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: passwordController,
                    labelText: 'Password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: fullNameController,
                    labelText: 'Full Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: contactController,
                    labelText: 'Contact Number',
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    controller: emergencyController,
                    labelText: 'Emergency Contact',
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Role-specific Information
                  if (selectedUserType == UserType.teachers) ...[
                    Text(
                      'Teacher Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: departmentController,
                      labelText: 'Department',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Department is required for teachers';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    Text(
                      'Student Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    CustomTextField(
                      controller: studentIdController,
                      labelText: 'Student ID',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Student ID is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<int>(
                      initialValue: selectedYearLevel,
                      decoration: const InputDecoration(
                        labelText: 'Year Level',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(4, (index) => index + 1)
                          .map((level) => DropdownMenuItem(
                                value: level,
                                child: Text('Year $level'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedYearLevel = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: sectionController,
                      labelText: 'Section',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: courseController,
                      labelText: 'Course',
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        DialogAction.cancel(context: context),
        DialogAction.save(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop();
              
              final currentUser = ref.read(authProvider).user;
              if (currentUser == null) return;

              await notifier.createUser(
                email: emailController.text,
                password: passwordController.text,
                fullName: fullNameController.text,
                contactNumber: contactController.text,
                emergencyContactNumber: emergencyController.text,
                userType: selectedUserType,
                createdBy: currentUser.userId,
                department: selectedUserType == UserType.teachers ? departmentController.text : null,
                studentId: selectedUserType == UserType.students ? studentIdController.text : null,
                yearLevel: selectedUserType == UserType.students ? selectedYearLevel : null,
                section: selectedUserType == UserType.students ? sectionController.text : null,
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  void _showEditUserDialog(BuildContext context, User user, UserManagementNotifier notifier) {
    final emailController = TextEditingController(text: user.email);
    final fullNameController = TextEditingController(text: user.fullName);
    final contactController = TextEditingController(text: user.contactNumber);
    final emergencyController = TextEditingController(text: user.emergencyContactNumber);
    final departmentController = TextEditingController();
    final studentIdController = TextEditingController();
    final sectionController = TextEditingController();
    final courseController = TextEditingController();
    
    String? selectedStatus = user.status;
    int? selectedYearLevel;
    
    // Get existing role-specific data from state
    final userState = ref.read(userManagementProvider);
    String userRole = 'User';
    Teacher? teacher;
    Student? student;
    
    if (userState.teachers.any((t) => t.userId == user.userId)) {
      userRole = 'Teacher';
      teacher = userState.teachers.firstWhere((t) => t.userId == user.userId);
    } else if (userState.students.any((s) => s.userId == user.userId)) {
      userRole = 'Student';
      student = userState.students.firstWhere((s) => s.userId == user.userId);
    }
    
    if (teacher != null) {
      departmentController.text = teacher.department ?? '';
    }
    if (student != null) {
      studentIdController.text = student.studentId;
      selectedYearLevel = student.yearLevel;
      sectionController.text = student.section ?? '';
      courseController.text = student.course ?? '';
    }
    
    final formKey = GlobalKey<FormState>();

    AppDialog.show(
      context: context,
      title: 'Edit User',
      type: DialogType.custom,
      maxWidth: 600,
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Selection
              Text(
                'Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  selectedStatus = value;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Basic Information
              Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              
              CustomTextField(
                controller: emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: fullNameController,
                labelText: 'Full Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: contactController,
                labelText: 'Contact Number',
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: emergencyController,
                labelText: 'Emergency Contact',
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 20),
              
              // Role-specific Information
              if (userRole == 'Teacher') ...[
                Text(
                  'Teacher Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: departmentController,
                  labelText: 'Department',
                ),
              ] else if (userRole == 'Student') ...[
                Text(
                  'Student Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                
                CustomTextField(
                  controller: studentIdController,
                  labelText: 'Student ID',
                ),
                
                const SizedBox(height: 16),
                
                DropdownButtonFormField<int>(
                  initialValue: selectedYearLevel,
                  decoration: const InputDecoration(
                    labelText: 'Year Level',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(4, (index) => index + 1)
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text('Year $level'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    selectedYearLevel = value;
                  },
                ),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: sectionController,
                  labelText: 'Section',
                ),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: courseController,
                  labelText: 'Course',
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        DialogAction.cancel(context: context),
        DialogAction.save(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop();
              
              await notifier.updateUser(
                user,
                email: emailController.text,
                fullName: fullNameController.text,
                contactNumber: contactController.text,
                emergencyContactNumber: emergencyController.text,
                status: selectedStatus,
                department: userRole == 'Teacher' ? departmentController.text : null,
                studentId: userRole == 'Student' ? studentIdController.text : null,
                yearLevel: userRole == 'Student' ? selectedYearLevel : null,
                section: userRole == 'Student' ? sectionController.text : null,
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  void _showUserDetailsDialog(BuildContext context, User user) {
    final userState = ref.read(userManagementProvider);
    String userRole = 'User';
    Teacher? teacher;
    Student? student;
    
    if (userState.teachers.any((t) => t.userId == user.userId)) {
      userRole = 'Teacher';
      teacher = userState.teachers.firstWhere((t) => t.userId == user.userId);
    } else if (userState.students.any((s) => s.userId == user.userId)) {
      userRole = 'Student';
      student = userState.students.firstWhere((s) => s.userId == user.userId);
    }

    AppDialog.show(
      context: context,
      title: 'User Details',
      type: DialogType.info,
      maxWidth: 500,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar and Basic Info
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
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
                      user.fullName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getRoleColor(userRole).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            userRole,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getRoleColor(userRole),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: user.isActive 
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            user.status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: user.isActive ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Contact Information
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          
          InfoCardPresets.compact(
            icon: Icons.phone,
            title: 'Contact Number',
            value: user.contactNumber.isNotEmpty ? user.contactNumber : 'Not provided',
            color: Colors.indigo,
          ),
          
          const SizedBox(height: 12),
          
          InfoCardPresets.compact(
            icon: Icons.emergency,
            title: 'Emergency Contact',
            value: user.emergencyContactNumber.isNotEmpty ? user.emergencyContactNumber : 'Not provided',
            color: Colors.red,
          ),
          
          const SizedBox(height: 24),
          
          // Role-specific Information
          if (userRole == 'Teacher' && teacher != null) ...[
            Text(
              'Teacher Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            InfoCardPresets.compact(
              icon: Icons.school,
              title: 'Department',
              value: teacher.department ?? 'Not specified',
              color: Colors.blue,
            ),
          ] else if (userRole == 'Student' && student != null) ...[
            Text(
              'Student Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 12),
            
            InfoCardPresets.compact(
              icon: Icons.badge,
              title: 'Student ID',
              value: student.studentId,
              color: Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            InfoCardPresets.compact(
              icon: Icons.grade,
              title: 'Year Level',
              value: student.yearLevel.toString(),
              color: Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            InfoCardPresets.compact(
              icon: Icons.group,
              title: 'Section',
              value: student.section ?? 'Not assigned',
              color: Colors.purple,
            ),
            
            const SizedBox(height: 12),
            
            InfoCardPresets.compact(
              icon: Icons.book,
              title: 'Course',
              value: student.course ?? 'Not specified',
              color: Colors.teal,
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Account Information
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          
          InfoCardPresets.compact(
            icon: Icons.calendar_today,
            title: 'Created At',
            value: _formatDate(user.createdAt),
            color: Colors.grey,
          ),
          
          const SizedBox(height: 12),
          
          InfoCardPresets.compact(
            icon: Icons.update,
            title: 'Last Updated',
            value: _formatDate(user.updatedAt),
            color: Colors.grey,
          ),
        ],
      ),
      actions: [
        DialogAction.ok(),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, User user, UserManagementNotifier notifier) {
    DialogUtils.showConfirmation(
      context: context,
      title: 'Delete User',
      message: 'Are you sure you want to delete ${user.fullName}? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    ).then((confirmed) async {
      if (confirmed == true) {
        await notifier.deleteUser(user);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.fullName} has been deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
