import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _emergencyContactController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _emergencyContactController = TextEditingController();
    
    // Load user data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref.read(userProfileProvider.notifier).loadUserData(authState.user!.userId);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  void _updateControllersFromState(UserProfileState state) {
    if (state.user != null) {
      // Format contact number by removing +63 prefix if present
      String formattedPhone = state.user!.contactNumber;
      if (formattedPhone.startsWith('+63 ')) {
        formattedPhone = formattedPhone.substring(4);
      }
      if (_phoneController.text != formattedPhone) {
        _phoneController.text = formattedPhone;
      }
      
      // Format emergency contact by removing +63 prefix if present
      String formattedEmergency = state.user!.emergencyContactNumber;
      if (formattedEmergency.startsWith('+63 ')) {
        formattedEmergency = formattedEmergency.substring(4);
      }
      if (_emergencyContactController.text != formattedEmergency) {
        _emergencyContactController.text = formattedEmergency;
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    
    // Update controllers when state changes
    _updateControllersFromState(profileState);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),

        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: profileState.isLoading || !profileState.hasChanges
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        await ref.read(userProfileProvider.notifier).saveProfile();
                        if (mounted && profileState.error == null) {
                          if (context.mounted) Navigator.pop(context);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: profileState.hasChanges && !profileState.isLoading
                    ? Colors.white
                    : Colors.grey[300],
                foregroundColor: profileState.hasChanges && !profileState.isLoading
                    ? Colors.blue[600]
                    : Colors.grey[600],
                elevation: profileState.hasChanges && !profileState.isLoading ? 2 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: profileState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: profileState.isLoading && profileState.user == null
          ? const Center(child: CircularProgressIndicator())
          : profileState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${profileState.error}',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final authState = ref.read(authProvider);
                          if (authState.user != null) {
                            ref.read(userProfileProvider.notifier).loadUserData(authState.user!.userId);
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture Section
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                                backgroundImage: const AssetImage('assets/images/aclclogo-nobg.png'),
                                child: null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                profileState.user?.fullName ?? 'User Name',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profileState.user?.email ?? 'user@example.com',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Student ID: ${profileState.student?.studentId ?? 'Not specified'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Course Information (Read-only)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.school,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Degree Program',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profileState.student?.course ?? 'Not specified',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Contact Number Field
                        Text(
                          'Contact Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            ref.read(userProfileProvider.notifier).updateContactNumber(value);
                          },
                          decoration: InputDecoration(
                            prefixText: '+63 | ',
                            prefixStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: '123 456 7890',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Contact number is required';
                            }
                            if (!RegExp(r'^\d{3}\s\d{3}\s\d{4}$').hasMatch(value.trim())) {
                              return 'Please enter a valid contact number (123 456 7890)';
                            }
                            if (value.trim() == _emergencyContactController.text.trim()) {
                              return 'Contact number cannot be the same as emergency contact number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Emergency Contact Number Field
                        Text(
                          'Emergency Contact Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emergencyContactController,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            ref.read(userProfileProvider.notifier).updateEmergencyContactNumber(value);
                          },
                          decoration: InputDecoration(
                            prefixText: '+63 | ',
                            prefixStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: '987 654 3210',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Emergency contact number is required';
                            }
                            if (!RegExp(r'^\d{3}\s\d{3}\s\d{4}$').hasMatch(value.trim())) {
                              return 'Please enter a valid emergency contact number (987 654 3210)';
                            }
                            if (value.trim() == _phoneController.text.trim()) {
                              return 'Emergency contact number cannot be the same as contact number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }
}