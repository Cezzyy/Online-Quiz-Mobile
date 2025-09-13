import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/student.dart';
import '../data/mock_data.dart';

// State class to hold user profile data and UI state
class UserProfileState {
  final User? user;
  final Student? student;
  final bool isLoading;
  final String? error;
  final bool hasChanges;
  final String originalContactNumber;
  final String originalEmergencyContactNumber;


  const UserProfileState({
    this.user,
    this.student,
    this.isLoading = false,
    this.error,
    this.hasChanges = false,
    this.originalContactNumber = '',
    this.originalEmergencyContactNumber = '',

  });

  UserProfileState copyWith({
    User? user,
    Student? student,
    bool? isLoading,
    String? error,
    bool? hasChanges,
    String? originalContactNumber,
    String? originalEmergencyContactNumber,

  }) {
    return UserProfileState(
      user: user ?? this.user,
      student: student ?? this.student,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasChanges: hasChanges ?? this.hasChanges,
      originalContactNumber: originalContactNumber ?? this.originalContactNumber,
      originalEmergencyContactNumber: originalEmergencyContactNumber ?? this.originalEmergencyContactNumber,

    );
  }
}

// Notifier class to manage user profile state
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier() : super(const UserProfileState());

  // Load user data and set original values
  Future<void> loadUserData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // This is all early development pa, will be changed once naa nay backend ug DB so mock data sa ta
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get user with ID 4 (Jan Rosalijos)
      final user = MockData.users.firstWhere((u) => u.userId == 4);
      final student = MockData.students.firstWhere((s) => s.userId == 4);
      
      state = state.copyWith(
        user: user,
        student: student,
        isLoading: false,
        originalContactNumber: user.contactNumber,
        originalEmergencyContactNumber: user.emergencyContactNumber,

        hasChanges: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user data: $e',
      );
    }
  }

  // Update contact number and check for changes
  void updateContactNumber(String contactNumber) {
    if (state.user != null) {
      String formattedPhone = contactNumber.trim();
      if (!formattedPhone.startsWith('+63 ') && formattedPhone.isNotEmpty) {
        formattedPhone = '+63 $formattedPhone';
      }
      
      final updatedUser = state.user!.copyWith(
        contactNumber: formattedPhone,
      );
      
      state = state.copyWith(
        user: updatedUser,
        hasChanges: _checkForChanges(
          contactNumber: formattedPhone,
          emergencyContactNumber: updatedUser.emergencyContactNumber,
        ),
      );
    }
  }

  // Update emergency contact number and check for changes
  void updateEmergencyContactNumber(String emergencyContactNumber) {
    if (state.user != null) {
      String formattedEmergency = emergencyContactNumber.trim();
      if (!formattedEmergency.startsWith('+63 ') && formattedEmergency.isNotEmpty) {
        formattedEmergency = '+63 $formattedEmergency';
      }
      
      final updatedUser = state.user!.copyWith(
        emergencyContactNumber: formattedEmergency,
      );
      
      state = state.copyWith(
        user: updatedUser,
        hasChanges: _checkForChanges(
          contactNumber: updatedUser.contactNumber,
          emergencyContactNumber: formattedEmergency,
        ),
      );
    }
  }



  // Save profile changes
  Future<void> saveProfile() async {
    if (!state.hasChanges || state.user == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isLoading: false,
        hasChanges: false,
        originalContactNumber: state.user!.contactNumber,
        originalEmergencyContactNumber: state.user!.emergencyContactNumber,

      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save profile: $e',
      );
    }
  }

  // Check if any field has changed from original values
  bool _checkForChanges({
    required String contactNumber,
    required String emergencyContactNumber,
  }) {
    return contactNumber != state.originalContactNumber ||
           emergencyContactNumber != state.originalEmergencyContactNumber;
  }

  // Reset to original values
  void resetChanges() {
    if (state.user != null) {
      final resetUser = state.user!.copyWith(
        contactNumber: state.originalContactNumber,
        emergencyContactNumber: state.originalEmergencyContactNumber,
      );
      
      state = state.copyWith(
        user: resetUser,
        hasChanges: false,
      );
    }
  }
}

// Provider for user profile state management
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>(
  (ref) => UserProfileNotifier(),
);