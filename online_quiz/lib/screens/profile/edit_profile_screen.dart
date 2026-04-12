import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyContactPersonController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _emergencyContactPersonController = TextEditingController();

    // Load user data when screen initializes
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref
            .read(userProfileProvider.notifier)
            .loadUserData(authState.user!.userId);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _emergencyContactPersonController.dispose();
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

      // Set emergency contact person
      if (_emergencyContactPersonController.text != state.user!.emergencyContactPerson) {
        _emergencyContactPersonController.text = state.user!.emergencyContactPerson;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    // Update controllers when state changes
    _updateControllersFromState(profileState);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Reset changes before closing
            ref.read(userProfileProvider.notifier).resetChanges();
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: profileState.isLoading || !profileState.hasChanges
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        await ref
                            .read(userProfileProvider.notifier)
                            .saveProfile();
                        if (mounted && profileState.error == null) {
                          if (context.mounted) Navigator.pop(context);
                        }
                      }
                    },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              child: profileState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save'),
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
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profileState.error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authState = ref.read(authProvider);
                      if (authState.user != null) {
                        ref
                            .read(userProfileProvider.notifier)
                            .loadUserData(authState.user!.userId);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header with Profile Picture
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: const CircleAvatar(
                                radius: 50,
                                backgroundImage: AssetImage(
                                  'assets/images/aclclogo-nobg.png',
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Text(
                          profileState.user?.fullName ?? 'User Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          profileState.user?.email ?? 'user@example.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, 'Academic Info'),
                          const SizedBox(height: 16),

                          // Read-only Academic Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildReadOnlyField(
                                  context,
                                  'Student ID',
                                  profileState.student?.studentId ?? 'N/A',
                                  Icons.badge_outlined,
                                ),
                                const Divider(height: 24),
                                _buildReadOnlyField(
                                  context,
                                  'Degree Program',
                                  profileState.student?.course ?? 'N/A',
                                  Icons.school_outlined,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                          _buildSectionTitle(context, 'Contact Information'),
                          const SizedBox(height: 16),

                          // Contact Fields
                          _buildPhoneField(
                            context,
                            controller: _phoneController,
                            label: 'Contact Number',
                            icon: Icons.phone_outlined,
                            onChanged: (value) {
                              ref
                                  .read(userProfileProvider.notifier)
                                  .updateContactNumber(value);
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Contact number is required';
                              }
                              if (!RegExp(
                                r'^\d{3}\s\d{3}\s\d{4}$',
                              ).hasMatch(value.trim())) {
                                return 'Format: 123 456 7890';
                              }
                              if (value.trim() ==
                                  _emergencyContactController.text.trim()) {
                                return 'Cannot be same as emergency';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: _emergencyContactPersonController,
                            labelText: 'Emergency Contact Person',
                            hintText: 'Enter name of emergency contact',
                            prefixIcon: Icons.person_outline,
                            keyboardType: TextInputType.text,
                            onChanged: (value) {
                              ref
                                  .read(userProfileProvider.notifier)
                                  .updateEmergencyContactPerson(value);
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Emergency contact person is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          _buildPhoneField(
                            context,
                            controller: _emergencyContactController,
                            label: 'Emergency Contact Number',
                            icon: Icons.contact_phone_outlined,
                            onChanged: (value) {
                              ref
                                  .read(userProfileProvider.notifier)
                                  .updateEmergencyContactNumber(value);
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Emergency contact is required';
                              }
                              if (!RegExp(
                                r'^\d{3}\s\d{3}\s\d{4}$',
                              ).hasMatch(value.trim())) {
                                return 'Format: 987 654 3210';
                              }
                              if (value.trim() ==
                                  _phoneController.text.trim()) {
                                return 'Cannot be same as contact';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      onChanged: onChanged,
      style: TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        prefixText: '+63 | ',
        prefixStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
        hintText: 'XXX XXX XXXX',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}
