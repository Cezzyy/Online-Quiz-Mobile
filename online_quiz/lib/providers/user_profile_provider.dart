import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/mock_data.dart';

// State class to hold user profile data and UI state
class UserProfileState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool hasChanges;
  final String originalBio;
  final String originalPhone;
  final String originalEmergencyContact;
  final String originalProfileImageUrl;

  const UserProfileState({
    this.user,
    this.isLoading = false,
    this.error,
    this.hasChanges = false,
    this.originalBio = '',
    this.originalPhone = '',
    this.originalEmergencyContact = '',
    this.originalProfileImageUrl = '',
  });

  UserProfileState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? hasChanges,
    String? originalBio,
    String? originalPhone,
    String? originalEmergencyContact,
    String? originalProfileImageUrl,
  }) {
    return UserProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasChanges: hasChanges ?? this.hasChanges,
      originalBio: originalBio ?? this.originalBio,
      originalPhone: originalPhone ?? this.originalPhone,
      originalEmergencyContact: originalEmergencyContact ?? this.originalEmergencyContact,
      originalProfileImageUrl: originalProfileImageUrl ?? this.originalProfileImageUrl,
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
      
      final user = DummyData.getUser();
      
      state = state.copyWith(
        user: user,
        isLoading: false,
        originalBio: user.bio,
        originalPhone: user.phoneNumber,
        originalEmergencyContact: user.emergencyContact,
        originalProfileImageUrl: user.profileImageUrl,
        hasChanges: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user data: $e',
      );
    }
  }

  // Update bio and check for changes
  void updateBio(String bio) {
    if (state.user != null) {
      final updatedUser = User(
        id: state.user!.id,
        name: state.user!.name,
        email: state.user!.email,
        studentId: state.user!.studentId,
        courses: state.user!.courses,
        notifications: state.user!.notifications,
        bio: bio,
        phoneNumber: state.user!.phoneNumber,
        emergencyContact: state.user!.emergencyContact,
        profileImageUrl: state.user!.profileImageUrl,
        degree: state.user!.degree,
        userType: state.user!.userType,
      );
      
      state = state.copyWith(
        user: updatedUser,
        hasChanges: _checkForChanges(
          bio: bio,
          phone: state.user!.phoneNumber,
          emergencyContact: state.user!.emergencyContact,
          profileImageUrl: state.user!.profileImageUrl,
        ),
      );
    }
  }

  // Update phone number and check for changes
  void updatePhoneNumber(String phoneNumber) {
    if (state.user != null) {
      String formattedPhone = phoneNumber.trim();
      if (!formattedPhone.startsWith('+63 ') && formattedPhone.isNotEmpty) {
        formattedPhone = '+63 $formattedPhone';
      }
      
      final updatedUser = User(
        id: state.user!.id,
        name: state.user!.name,
        email: state.user!.email,
        studentId: state.user!.studentId,
        courses: state.user!.courses,
        notifications: state.user!.notifications,
        bio: state.user!.bio,
        phoneNumber: formattedPhone,
        emergencyContact: state.user!.emergencyContact,
        profileImageUrl: state.user!.profileImageUrl,
        degree: state.user!.degree,
        userType: state.user!.userType,
      );
      
      state = state.copyWith(
        user: updatedUser,
        hasChanges: _checkForChanges(
          bio: state.user!.bio,
          phone: formattedPhone,
          emergencyContact: state.user!.emergencyContact,
          profileImageUrl: state.user!.profileImageUrl,
        ),
      );
    }
  }

  // Update emergency contact and check for changes
  void updateEmergencyContact(String emergencyContact) {
    if (state.user != null) {
      String formattedEmergency = emergencyContact.trim();
      if (!formattedEmergency.startsWith('+63 ') && formattedEmergency.isNotEmpty) {
        formattedEmergency = '+63 $formattedEmergency';
      }
      
      final updatedUser = User(
        id: state.user!.id,
        name: state.user!.name,
        email: state.user!.email,
        studentId: state.user!.studentId,
        courses: state.user!.courses,
        notifications: state.user!.notifications,
        bio: state.user!.bio,
        phoneNumber: state.user!.phoneNumber,
        emergencyContact: formattedEmergency,
        profileImageUrl: state.user!.profileImageUrl,
        degree: state.user!.degree,
        userType: state.user!.userType,
      );
      
      state = state.copyWith(
        user: updatedUser,
        hasChanges: _checkForChanges(
          bio: state.user!.bio,
          phone: state.user!.phoneNumber,
          emergencyContact: formattedEmergency,
          profileImageUrl: state.user!.profileImageUrl,
        ),
      );
    }
  }

  // Update profile image URL and check for changes
  void updateProfileImageUrl(String profileImageUrl) {
    if (state.user != null) {
      final updatedUser = User(
        id: state.user!.id,
        name: state.user!.name,
        email: state.user!.email,
        studentId: state.user!.studentId,
        courses: state.user!.courses,
        notifications: state.user!.notifications,
        bio: state.user!.bio,
        phoneNumber: state.user!.phoneNumber,
        emergencyContact: state.user!.emergencyContact,
        profileImageUrl: profileImageUrl,
        degree: state.user!.degree,
        userType: state.user!.userType,
      );
      
      state = state.copyWith(
        user: updatedUser,
        hasChanges: _checkForChanges(
          bio: state.user!.bio,
          phone: state.user!.phoneNumber,
          emergencyContact: state.user!.emergencyContact,
          profileImageUrl: profileImageUrl,
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
        originalBio: state.user!.bio,
        originalPhone: state.user!.phoneNumber,
        originalEmergencyContact: state.user!.emergencyContact,
        originalProfileImageUrl: state.user!.profileImageUrl,
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
    required String bio,
    required String phone,
    required String emergencyContact,
    required String profileImageUrl,
  }) {
    return bio != state.originalBio ||
           phone != state.originalPhone ||
           emergencyContact != state.originalEmergencyContact ||
           profileImageUrl != state.originalProfileImageUrl;
  }

  // Reset to original values
  void resetChanges() {
    if (state.user != null) {
      final resetUser = User(
        id: state.user!.id,
        name: state.user!.name,
        studentId: state.user!.studentId,
        courses: state.user!.courses,
        notifications: state.user!.notifications,
        email: state.user!.email,
        bio: state.originalBio,
        phoneNumber: state.originalPhone,
        emergencyContact: state.originalEmergencyContact,
        profileImageUrl: state.originalProfileImageUrl,
        degree: state.user!.degree,
        userType: state.user!.userType,
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