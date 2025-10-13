import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/user.dart';
import '../models/quiz.dart';
import '../data/mock_data.dart';

// Course state class to hold all course-related data and UI state
class CourseState {
  final List<Course> allCourses;
  final List<Course> userCourses;
  final List<Enrollment> userEnrollments;
  final Course? selectedCourse;
  final List<Quiz> selectedCourseQuizzes;
  final bool isLoading;
  final bool isLoadingCourseDetails;
  final String? error;
  final Map<int, double> courseProgress; // courseId -> progress percentage
  final Map<int, int> courseQuizCounts; // courseId -> quiz count
  final Map<int, int> completedQuizCounts; // courseId -> completed quiz count

  const CourseState({
    this.allCourses = const [],
    this.userCourses = const [],
    this.userEnrollments = const [],
    this.selectedCourse,
    this.selectedCourseQuizzes = const [],
    this.isLoading = false,
    this.isLoadingCourseDetails = false,
    this.error,
    this.courseProgress = const {},
    this.courseQuizCounts = const {},
    this.completedQuizCounts = const {},
  });

  CourseState copyWith({
    List<Course>? allCourses,
    List<Course>? userCourses,
    List<Enrollment>? userEnrollments,
    Course? selectedCourse,
    List<Quiz>? selectedCourseQuizzes,
    bool? isLoading,
    bool? isLoadingCourseDetails,
    String? error,
    Map<int, double>? courseProgress,
    Map<int, int>? courseQuizCounts,
    Map<int, int>? completedQuizCounts,
    bool clearError = false,
    bool clearSelectedCourse = false,
  }) {
    return CourseState(
      allCourses: allCourses ?? this.allCourses,
      userCourses: userCourses ?? this.userCourses,
      userEnrollments: userEnrollments ?? this.userEnrollments,
      selectedCourse: clearSelectedCourse ? null : (selectedCourse ?? this.selectedCourse),
      selectedCourseQuizzes: selectedCourseQuizzes ?? this.selectedCourseQuizzes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingCourseDetails: isLoadingCourseDetails ?? this.isLoadingCourseDetails,
      error: clearError ? null : (error ?? this.error),
      courseProgress: courseProgress ?? this.courseProgress,
      courseQuizCounts: courseQuizCounts ?? this.courseQuizCounts,
      completedQuizCounts: completedQuizCounts ?? this.completedQuizCounts,
    );
  }

  // Helper getters
  bool get hasUserCourses => userCourses.isNotEmpty;
  bool get hasSelectedCourse => selectedCourse != null;
  int get totalUserCourses => userCourses.length;
  
  // Get progress for a specific course
  double getCourseProgress(int courseId) {
    return courseProgress[courseId] ?? 0.0;
  }
  
  // Get quiz count for a specific course
  int getCourseQuizCount(int courseId) {
    return courseQuizCounts[courseId] ?? 0;
  }
  
  // Get completed quiz count for a specific course
  int getCompletedQuizCount(int courseId) {
    return completedQuizCounts[courseId] ?? 0;
  }
  
  // Check if user is enrolled in a course
  bool isEnrolledInCourse(int courseId) {
    return userEnrollments.any((enrollment) => enrollment.courseId == courseId);
  }
  

}

// Course notifier class to manage course state
class CourseNotifier extends StateNotifier<CourseState> {
  CourseNotifier() : super(const CourseState());

  // Initialize course data for a specific user
  Future<void> initializeCourses(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      // Load all courses
      final allCourses = List<Course>.from(MockData.courses);
      
      // Load user enrollments
      final userEnrollments = MockData.getEnrollmentsByUser(userId);
      
      // Load user courses based on enrollments
      final userCourses = userEnrollments
          .map((enrollment) => MockData.getCourseById(enrollment.courseId))
          .where((course) => course != null)
          .cast<Course>()
          .toList();
      
      // Calculate progress and quiz counts for each user course
      final Map<int, double> courseProgress = {};
      final Map<int, int> courseQuizCounts = {};
      final Map<int, int> completedQuizCounts = {};
      
      for (final course in userCourses) {
        final courseQuizzes = MockData.getQuizzesByCourse(course.courseId);
        final completedAttempts = MockData.getAttemptsByUser(userId)
            .where((attempt) => 
                courseQuizzes.any((quiz) => quiz.quizId == attempt.quizId) && 
                attempt.submittedAt != null)
            .length;
        
        final totalQuizzes = courseQuizzes.length;
        final progress = totalQuizzes > 0 ? completedAttempts / totalQuizzes : 0.0;
        
        courseProgress[course.courseId] = progress;
        courseQuizCounts[course.courseId] = totalQuizzes;
        completedQuizCounts[course.courseId] = completedAttempts;
      }
      
      state = state.copyWith(
        allCourses: allCourses,
        userCourses: userCourses,
        userEnrollments: userEnrollments,
        courseProgress: courseProgress,
        courseQuizCounts: courseQuizCounts,
        completedQuizCounts: completedQuizCounts,
        isLoading: false,
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load courses: $e',
      );
    }
  }

  // Load course details and quizzes
  Future<void> loadCourseDetails(int courseId) async {
    state = state.copyWith(isLoadingCourseDetails: true, clearError: true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate API call
      
      final course = MockData.getCourseById(courseId);
      if (course == null) {
        throw Exception('Course not found');
      }
      
      final courseQuizzes = MockData.getQuizzesByCourse(courseId);
      
      state = state.copyWith(
        selectedCourse: course,
        selectedCourseQuizzes: courseQuizzes,
        isLoadingCourseDetails: false,
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoadingCourseDetails: false,
        error: 'Failed to load course details: $e',
      );
    }
  }



  // Refresh course data
  Future<void> refreshCourses(int userId) async {
    await initializeCourses(userId);
  }

  // Clear selected course
  void clearSelectedCourse() {
    state = state.copyWith(clearSelectedCourse: true);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Search courses by name or code
  List<Course> searchCourses(String query) {
    if (query.isEmpty) return state.allCourses;
    
    final lowercaseQuery = query.toLowerCase();
    return state.allCourses.where((course) =>
        course.name.toLowerCase().contains(lowercaseQuery) ||
        course.code.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Get courses by instructor
  List<Course> getCoursesByInstructor(int instructorId) {
    return state.allCourses.where((course) => course.instructorUserId == instructorId).toList();
  }

  // Get instructor for a course
  User? getCourseInstructor(int courseId) {
    final course = state.allCourses.firstWhere(
      (c) => c.courseId == courseId,
      orElse: () => Course(
        courseId: 0, 
        code: '', 
        name: '', 
        instructorUserId: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 0,
      ),
    );
    
    if (course.courseId == 0) return null;
    
    return MockData.getUserById(course.instructorUserId);
  }

  // Teacher method: Get students enrolled in a specific course
  List<User> getEnrolledStudents(int courseId) {
    final enrollments = MockData.enrollments.where((e) => e.courseId == courseId).toList();
    return enrollments
        .map((enrollment) => MockData.getUserById(enrollment.userId))
        .where((user) => user != null)
        .cast<User>()
        .toList();
  }

  // Get enrolled students with their details for a course
  List<Map<String, dynamic>> getEnrolledStudentsWithDetails(int courseId) {
    final enrollments = MockData.enrollments.where((e) => e.courseId == courseId).toList();
    final students = <Map<String, dynamic>>[];

    for (final enrollment in enrollments) {
      final user = MockData.getUserById(enrollment.userId);
      final student = MockData.getStudentByUserId(enrollment.userId);
      
      if (user != null) {
        students.add({
          'user': user,
          'student': student,
          'enrollment': enrollment,
        });
      }
    }

    return students;
  }

  // Teacher method: Get all students not enrolled in a specific course
  List<User> getAvailableStudents(int courseId) {
    final enrolledUserIds = MockData.enrollments
        .where((e) => e.courseId == courseId)
        .map((e) => e.userId)
        .toSet();
    
    // Get all students (users with student role)
    final studentRoles = MockData.userRoles.where((ur) => 
        MockData.roles.any((role) => role.roleId == ur.roleId && role.name == 'Student')
    ).toList();
    
    return studentRoles
        .map((ur) => MockData.getUserById(ur.userId))
        .where((user) => user != null && !enrolledUserIds.contains(user.userId))
        .cast<User>()
        .toList();
  }

  // Teacher method: Enroll a student in their course
  Future<bool> enrollStudentInCourse(int studentId, int courseId, int teacherId) async {
    try {
      // Verify teacher owns this course
      final course = MockData.getCourseById(courseId);
      if (course == null || course.instructorUserId != teacherId) {
        state = state.copyWith(error: 'You can only enroll students in your own courses');
        return false;
      }

      // Check if student is already enrolled
      final existingEnrollment = MockData.enrollments.any(
        (e) => e.userId == studentId && e.courseId == courseId,
      );
      
      if (existingEnrollment) {
        state = state.copyWith(error: 'Student is already enrolled in this course');
        return false;
      }

      // Create new enrollment
      final newEnrollment = Enrollment(
        enrollmentId: DateTime.now().millisecondsSinceEpoch,
        userId: studentId,
        courseId: courseId,
        enrolledAt: DateTime.now(),
      );

      MockData.enrollments.add(newEnrollment);
      state = state.copyWith(clearError: true);
      return true;

    } catch (e) {
      state = state.copyWith(error: 'Failed to enroll student: $e');
      return false;
    }
  }

  // Teacher method: Remove a student from their course
  Future<bool> removeStudentFromCourse(int studentId, int courseId, int teacherId) async {
    try {
      // Verify teacher owns this course
      final course = MockData.getCourseById(courseId);
      if (course == null || course.instructorUserId != teacherId) {
        state = state.copyWith(error: 'You can only remove students from your own courses');
        return false;
      }

      // Find and remove enrollment
      final enrollmentIndex = MockData.enrollments.indexWhere(
        (e) => e.userId == studentId && e.courseId == courseId,
      );

      if (enrollmentIndex == -1) {
        state = state.copyWith(error: 'Student is not enrolled in this course');
        return false;
      }

      MockData.enrollments.removeAt(enrollmentIndex);
      state = state.copyWith(clearError: true);
      return true;

    } catch (e) {
      state = state.copyWith(error: 'Failed to remove student: $e');
      return false;
    }
  }
}

// Main course provider
final courseProvider = StateNotifierProvider<CourseNotifier, CourseState>(
  (ref) => CourseNotifier(),
);

// Convenience providers for specific data
final userCoursesProvider = Provider<List<Course>>((ref) {
  return ref.watch(courseProvider).userCourses;
});

final allCoursesProvider = Provider<List<Course>>((ref) {
  return ref.watch(courseProvider).allCourses;
});

final selectedCourseProvider = Provider<Course?>((ref) {
  return ref.watch(courseProvider).selectedCourse;
});

final selectedCourseQuizzesProvider = Provider<List<Quiz>>((ref) {
  return ref.watch(courseProvider).selectedCourseQuizzes;
});

final courseLoadingProvider = Provider<bool>((ref) {
  return ref.watch(courseProvider).isLoading;
});

final courseDetailsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(courseProvider).isLoadingCourseDetails;
});

final courseErrorProvider = Provider<String?>((ref) {
  return ref.watch(courseProvider).error;
});

// Provider for course progress by course ID
final courseProgressProvider = Provider.family<double, int>((ref, courseId) {
  return ref.watch(courseProvider).getCourseProgress(courseId);
});

// Provider for course quiz count by course ID
final courseQuizCountProvider = Provider.family<int, int>((ref, courseId) {
  return ref.watch(courseProvider).getCourseQuizCount(courseId);
});

// Provider for completed quiz count by course ID
final completedQuizCountProvider = Provider.family<int, int>((ref, courseId) {
  return ref.watch(courseProvider).getCompletedQuizCount(courseId);
});

// Provider to check if user is enrolled in a course
final isEnrolledProvider = Provider.family<bool, int>((ref, courseId) {
  return ref.watch(courseProvider).isEnrolledInCourse(courseId);
});