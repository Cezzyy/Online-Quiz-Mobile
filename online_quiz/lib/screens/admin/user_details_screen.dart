import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../models/user.dart';
import '../../models/teacher.dart';
import '../../models/student.dart';
import '../../providers/user_management_provider.dart';
import '../../widgets/info_card.dart';

class UserDetailsScreen extends ConsumerStatefulWidget {
  final User user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  bool _isResettingPassword = false;

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userManagementProvider);
    String userRole = 'User';
    Teacher? teacher;
    Student? student;

    if (userState.teachers.any((t) => t.userId == widget.user.userId)) {
      userRole = 'Teacher';
      teacher = userState.teachers.firstWhere((t) => t.userId == widget.user.userId);
    } else if (userState.students.any((s) => s.userId == widget.user.userId)) {
      userRole = 'Student';
      student = userState.students.firstWhere((s) => s.userId == widget.user.userId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar and Basic Info Card
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
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          widget.user.fullName.isNotEmpty
                              ? widget.user.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.fullName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.getSecondaryTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(userRole).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getRoleIcon(userRole),
                                        size: 16,
                                        color: _getRoleColor(userRole),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        userRole,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _getRoleColor(userRole),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.user.isActive
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.user.isActive
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 16,
                                        color: widget.user.isActive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.user.status,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: widget.user.isActive
                                              ? Colors.green
                                              : Colors.red,
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Account Actions Card
              _buildSectionCard(
                title: 'Account Actions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.getDividerColor(context),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lock_reset,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password Reset',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.getTextColor(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Generate a new temporary password for this user',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.getSecondaryTextColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isResettingPassword ? null : _handleResetPassword,
                            icon: _isResettingPassword
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.lock_reset),
                            label: Text(
                              _isResettingPassword ? 'Resetting...' : 'Reset Password',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'A new temporary password will be generated and displayed. Make sure to copy it and share with the user.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
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
              ),

              const SizedBox(height: 24),

              // Contact Information Card
              _buildSectionCard(
                title: 'Contact Information',
                child: Column(
                  children: [
                    InfoCardPresets.compact(
                      icon: Icons.phone_outlined,
                      title: 'Contact Number',
                      value: widget.user.contactNumber.isNotEmpty
                          ? widget.user.contactNumber
                          : 'Not provided',
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 12),
                    InfoCardPresets.compact(
                      icon: Icons.emergency_outlined,
                      title: 'Emergency Contact',
                      value: widget.user.emergencyContactNumber.isNotEmpty
                          ? widget.user.emergencyContactNumber
                          : 'Not provided',
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    InfoCardPresets.compact(
                      icon: Icons.person_outline,
                      title: 'Emergency Contact Person',
                      value: widget.user.emergencyContactPerson.isNotEmpty
                          ? widget.user.emergencyContactPerson
                          : 'Not provided',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Role-specific Information Card
              if (userRole == 'Teacher' && teacher != null)
                _buildSectionCard(
                  title: 'Teacher Information',
                  child: InfoCardPresets.compact(
                    icon: Icons.school_outlined,
                    title: 'Department',
                    value: teacher.department ?? 'Not specified',
                    color: Colors.blue,
                  ),
                )
              else if (userRole == 'Student' && student != null)
                _buildSectionCard(
                  title: 'Student Information',
                  child: Column(
                    children: [
                      InfoCardPresets.compact(
                        icon: Icons.badge_outlined,
                        title: 'Student ID',
                        value: student.studentId,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      InfoCardPresets.compact(
                        icon: Icons.grade_outlined,
                        title: 'Year Level',
                        value: 'Year ${student.yearLevel}',
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      InfoCardPresets.compact(
                        icon: Icons.group_outlined,
                        title: 'Section',
                        value: student.section ?? 'Not assigned',
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      InfoCardPresets.compact(
                        icon: Icons.book_outlined,
                        title: 'Course',
                        value: student.course ?? 'Not specified',
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Account Information Card
              _buildSectionCard(
                title: 'Account Information',
                child: Column(
                  children: [
                    InfoCardPresets.compact(
                      icon: Icons.calendar_today_outlined,
                      title: 'Created At',
                      value: _formatDate(widget.user.createdAt),
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    InfoCardPresets.compact(
                      icon: Icons.update_outlined,
                      title: 'Last Updated',
                      value: _formatDate(widget.user.updatedAt),
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
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

  Future<void> _handleResetPassword() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Are you sure you want to reset the password for ${widget.user.fullName}?\n\nA new temporary password will be generated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isResettingPassword = true;
    });

    try {
      final notifier = ref.read(userManagementProvider.notifier);
      final newPassword = await notifier.resetUserPassword(widget.user.userId);
      
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });

        // Show the new password in a dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Password Reset Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New temporary password for ${widget.user.fullName}:',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          newPassword,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy to clipboard',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: newPassword));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Make sure to copy and securely share this password with the user. It cannot be retrieved again.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Teacher':
        return Colors.blue;
      case 'Student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Teacher':
        return Icons.school;
      case 'Student':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
