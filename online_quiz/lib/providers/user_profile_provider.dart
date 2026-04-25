import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../services/user_profile_service.dart';

// State class to hold user profile data and UI state
class UserProfileState {
  final User? user;
  final Student? student;
  final List<Course> enrolledCourses;
  final Map<String, dynamic>? statistics;
  final Map<int, double> courseProgress;
  final bool isLoading;
  final String? error;
  final bool hasChanges;
  final String originalContactNumber;
  final String originalEmergencyContactNumber;
  final String originalEmergencyContactPerson;

  const UserProfileState({
    this.user,
    this.student,
    this.enrolledCourses = const [],
    this.statistics,
    this.courseProgress = const {},
    this.isLoading = false,
    this.error,
    this.hasChanges = false,
    this.originalContactNumber = '',
    this.originalEmergencyContactNumber = '',
    this.originalEmergencyContactPerson = '',
  });

  UserProfileState copyWith({
    User? user,
    Student? student,
    List<Course>? enrolledCourses,
    Map<String, dynamic>? statistics,
    Map<int, double>? courseProgress,
    bool? isLoading,
    String? error,
    bool? hasChanges,
    String? originalContactNumber,
    String? originalEmergencyContactNumber,
    String? originalEmergencyContactPerson,
  }) {
    return UserProfileState(
      user: user ?? this.user,
      student: student ?? this.student,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      statistics: statistics ?? this.statistics,
      courseProgress: courseProgress ?? this.courseProgress,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasChanges: hasChanges ?? this.hasChanges,
      originalContactNumber: originalContactNumber ?? this.originalContactNumber,
      originalEmergencyContactNumber: originalEmergencyContactNumber ?? this.originalEmergencyContactNumber,
      originalEmergencyContactPerson: originalEmergencyContactPerson ?? this.originalEmergencyContactPerson,
    );
  }
}

// Notifier class to manage user profile state
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final UserProfileService _userProfileService = UserProfileService();

  UserProfileNotifier() : super(const UserProfileState());

  // Load user data and set original values
  Future<void> loadUserData(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _userProfileService.getUserProfile(userId),
        _userProfileService.getEnrolledCourses(userId),
        _userProfileService.getQuizStatistics(userId),
        _userProfileService.getCourseProgress(userId),
      ]);

      final profileData = results[0] as Map<String, dynamic>;
      final courses = results[1] as List<Course>;
      final stats = results[2] as Map<String, dynamic>;
      final progress = results[3] as Map<int, double>;

      final user = profileData['user'] as User;
      final student = profileData['student'] as Student?;
      
      state = state.copyWith(
        user: user,
        student: student,
        enrolledCourses: courses,
        statistics: stats,
        courseProgress: progress,
        isLoading: false,
        originalContactNumber: user.contactNumber,
        originalEmergencyContactNumber: user.emergencyContactNumber,
        originalEmergencyContactPerson: user.emergencyContactPerson,
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
          emergencyContactPerson: updatedUser.emergencyContactPerson,
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
          emergencyContactPerson: updatedUser.emergencyContactPerson,
        ),
      );
    }
  }

  // Update emergency contact person and check for changes
  void updateEmergencyContactPerson(String emergencyContactPerson) {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(
        emergencyContactPerson: emergencyContactPerson.trim(),
      );
      
      state = state.copyWith(
        user: updatedUser,
        hasChanges: _checkForChanges(
          contactNumber: updatedUser.contactNumber,
          emergencyContactNumber: updatedUser.emergencyContactNumber,
          emergencyContactPerson: emergencyContactPerson.trim(),
        ),
      );
    }
  }


  // Save profile changes
  Future<void> saveProfile() async {
    if (!state.hasChanges || state.user == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Update profile in Supabase
      await _userProfileService.updateUserProfile(
        userId: state.user!.userId,
        contactNumber: state.user!.contactNumber,
        emergencyContactNumber: state.user!.emergencyContactNumber,
        emergencyContactPerson: state.user!.emergencyContactPerson,
      );

      // Reload user data to reflect changes
      await loadUserData(state.user!.userId);
      
      state = state.copyWith(
        isLoading: false,
        hasChanges: false,
        originalContactNumber: state.user!.contactNumber,
        originalEmergencyContactNumber: state.user!.emergencyContactNumber,
        originalEmergencyContactPerson: state.user!.emergencyContactPerson,
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
    required String emergencyContactPerson,
  }) {
    return contactNumber != state.originalContactNumber ||
           emergencyContactNumber != state.originalEmergencyContactNumber ||
           emergencyContactPerson != state.originalEmergencyContactPerson;
  }

  // Reset to original values
  void resetChanges() {
    if (state.user != null) {
      final resetUser = state.user!.copyWith(
        contactNumber: state.originalContactNumber,
        emergencyContactNumber: state.originalEmergencyContactNumber,
        emergencyContactPerson: state.originalEmergencyContactPerson,
      );
      
      state = state.copyWith(
        user: resetUser,
        hasChanges: false,
      );
    }
  }

  // Reset to loading state (used when app is locked)
  void resetToLoading() {
    state = const UserProfileState(isLoading: true);
  }
}

// Provider for user profile state management
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>(
  (ref) => UserProfileNotifier(),
);