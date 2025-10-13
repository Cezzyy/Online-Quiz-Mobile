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
  
  // Admin course management state
  final String searchQuery;
  final String? selectedStatus;
  final String? selectedCategory;
  final int? selectedInstructorId;
  final int currentPage;
  final int itemsPerPage;

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
    this.searchQuery = '',
    this.selectedStatus,
    this.selectedCategory,
    this.selectedInstructorId,
    this.currentPage = 1,
    this.itemsPerPage = 20,
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
    String? searchQuery,
    String? selectedStatus,
    String? selectedCategory,
    int? selectedInstructorId,
    int? currentPage,
    int? itemsPerPage,
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
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedInstructorId: selectedInstructorId ?? this.selectedInstructorId,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
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

  // Admin method: Create a new course
  Future<bool> createCourse({
    required String code,
    required String name,
    required int instructorUserId,
    String? category,
    String? section,
    String status = 'Active',
    required int createdBy,
  }) async {
    try {
      // Check if course code already exists
      final existingCourse = MockData.courses.any((c) => c.code.toLowerCase() == code.toLowerCase());
      if (existingCourse) {
        state = state.copyWith(error: 'Course code already exists');
        return false;
      }

      // Generate new course ID
      final newCourseId = MockData.courses.isNotEmpty
          ? MockData.courses.map((c) => c.courseId).reduce((a, b) => a > b ? a : b) + 1
          : 1;

      // Create new course
      final newCourse = Course(
        courseId: newCourseId,
        code: code,
        name: name,
        instructorUserId: instructorUserId,
        status: status,
        category: category,
        section: section,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: createdBy,
      );

      MockData.courses.add(newCourse);
      
      // Update state
      state = state.copyWith(
        allCourses: List.from(MockData.courses),
        clearError: true,
      );
      
      return true;

    } catch (e) {
      state = state.copyWith(error: 'Failed to create course: $e');
      return false;
    }
  }

  // Admin method: Update an existing course
  Future<bool> updateCourse(Course course, {
    String? code,
    String? name,
    int? instructorUserId,
    String? category,
    String? section,
    String? status,
  }) async {
    try {
      // Check if new code conflicts with existing courses (if code is being changed)
      if (code != null && code != course.code) {
        final existingCourse = MockData.courses.any((c) => 
            c.courseId != course.courseId && c.code.toLowerCase() == code.toLowerCase());
        if (existingCourse) {
          state = state.copyWith(error: 'Course code already exists');
          return false;
        }
      }

      // Find course index
      final courseIndex = MockData.courses.indexWhere((c) => c.courseId == course.courseId);
      if (courseIndex == -1) {
        state = state.copyWith(error: 'Course not found');
        return false;
      }

      // Update course
      MockData.courses[courseIndex] = course.copyWith(
        code: code ?? course.code,
        name: name ?? course.name,
        instructorUserId: instructorUserId ?? course.instructorUserId,
        category: category ?? course.category,
        section: section ?? course.section,
        status: status ?? course.status,
        updatedAt: DateTime.now(),
      );

      // Update state
      state = state.copyWith(
        allCourses: List.from(MockData.courses),
        clearError: true,
      );
      
      return true;

    } catch (e) {
      state = state.copyWith(error: 'Failed to update course: $e');
      return false;
    }
  }

  // Admin method: Delete a course
  Future<bool> deleteCourse(Course course) async {
    try {
      // Check if course has enrollments
      final hasEnrollments = MockData.enrollments.any((e) => e.courseId == course.courseId);
      if (hasEnrollments) {
        state = state.copyWith(error: 'Cannot delete course with enrolled students');
        return false;
      }

      // Check if course has quizzes
      final hasQuizzes = MockData.quizzes.any((q) => q.courseId == course.courseId);
      if (hasQuizzes) {
        state = state.copyWith(error: 'Cannot delete course with existing quizzes');
        return false;
      }

      // Remove course
      MockData.courses.removeWhere((c) => c.courseId == course.courseId);

      // Update state
      state = state.copyWith(
        allCourses: List.from(MockData.courses),
        clearError: true,
      );
      
      return true;

    } catch (e) {
      state = state.copyWith(error: 'Failed to delete course: $e');
      return false;
    }
  }

  // Admin method: Get all teachers (for course assignment)
  List<User> getAllTeachers() {
    final teacherRoles = MockData.userRoles.where((ur) => 
        MockData.roles.any((role) => role.roleId == ur.roleId && role.name == 'Teacher')
    ).toList();
    
    return teacherRoles
        .map((ur) => MockData.getUserById(ur.userId))
        .where((user) => user != null)
        .cast<User>()
        .toList();
  }

  // Admin method: Get courses by status
  List<Course> getCoursesByStatus(String status) {
    return state.allCourses.where((course) => course.status.toLowerCase() == status.toLowerCase()).toList();
  }

  // Admin method: Search courses with filters
  List<Course> searchCoursesWithFilters({
    String query = '',
    String? status,
    String? category,
    int? instructorId,
  }) {
    List<Course> filteredCourses = state.allCourses;

    // Filter by search query
    if (query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filteredCourses = filteredCourses.where((course) =>
          course.name.toLowerCase().contains(lowercaseQuery) ||
          course.code.toLowerCase().contains(lowercaseQuery) ||
          (course.category?.toLowerCase().contains(lowercaseQuery) ?? false)
      ).toList();
    }

    // Filter by status
    if (status != null && status.isNotEmpty) {
      filteredCourses = filteredCourses.where((course) => 
          course.status.toLowerCase() == status.toLowerCase()).toList();
    }

    // Filter by category
    if (category != null && category.isNotEmpty) {
      filteredCourses = filteredCourses.where((course) => 
          course.category?.toLowerCase() == category.toLowerCase()).toList();
    }

    // Filter by instructor
    if (instructorId != null) {
      filteredCourses = filteredCourses.where((course) => 
          course.instructorUserId == instructorId).toList();
    }

    return filteredCourses;
  }

  // Helper method: Get grouped courses (grouped by course code)
  List<Map<String, dynamic>> getGroupedCourses() {
    final Map<String, List<Course>> groupedCourses = {};
    
    // Group courses by their base code
    for (final course in state.allCourses) {
      if (!groupedCourses.containsKey(course.code)) {
        groupedCourses[course.code] = [];
      }
      groupedCourses[course.code]!.add(course);
    }
    
    // Convert to list of maps with aggregated data
    final List<Map<String, dynamic>> groupedList = [];
    
    groupedCourses.forEach((courseCode, courses) {
      final firstCourse = courses.first;
      final totalEnrollments = courses.fold<int>(0, (sum, course) => 
          sum + MockData.getEnrollmentsByCourse(course.courseId).length);
      
      // Get all instructors for this course
      final instructors = courses.map((course) => MockData.getUserById(course.instructorUserId)?.fullName ?? 'Unknown').toSet().toList();
      
      // Get all sections for this course
      final sections = courses.map((course) => course.section ?? 'A').toSet().toList()..sort();
      
      groupedList.add({
        'courseCode': courseCode,
        'courseName': firstCourse.name,
        'category': firstCourse.category,
        'status': firstCourse.status,
        'sections': sections,
        'instructors': instructors,
        'totalEnrollments': totalEnrollments,
        'courses': courses, // Keep reference to individual courses
        'primaryCourse': firstCourse, // Use first course as primary for actions
      });
    });
    
    return groupedList;
  }

  // Helper method: Get paginated grouped courses
  List<Map<String, dynamic>> getPaginatedGroupedCourses() {
    final groupedCourses = getGroupedCourses();
    final startIndex = (state.currentPage - 1) * state.itemsPerPage;
    final endIndex = (startIndex + state.itemsPerPage).clamp(0, groupedCourses.length);
    return groupedCourses.sublist(startIndex, endIndex);
  }

  // Helper method: Get total pages for grouped courses
  int getTotalGroupedPages() {
    final groupedCourses = getGroupedCourses();
    return (groupedCourses.length / state.itemsPerPage).ceil();
  }

  // Helper method: Get courses by base code (all sections)
  List<Course> getCoursesByBaseCode(String baseCode) {
    return state.allCourses.where((course) => course.code == baseCode).toList();
  }

  // Helper method: Get unique course codes (base codes without sections)
  List<String> getUniqueCourseCodes() {
    return state.allCourses.map((course) => course.code).toSet().toList();
  }

  // Helper method: Get sections for a specific course code
  List<String> getSectionsForCourse(String courseCode) {
    return state.allCourses
        .where((course) => course.code == courseCode)
        .map((course) => course.section ?? 'A')
        .toSet()
        .toList()
        ..sort();
  }

  // Helper method: Get instructors for a specific course code
  List<User> getInstructorsForCourse(String courseCode) {
    final courseIds = state.allCourses
        .where((course) => course.code == courseCode)
        .map((course) => course.instructorUserId)
        .toSet();
    
    return courseIds
        .map((instructorId) => MockData.getUserById(instructorId))
        .where((user) => user != null)
        .cast<User>()
        .toList();
  }

  // Admin pagination methods
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
  }

  void updateSelectedStatus(String? status) {
    state = state.copyWith(selectedStatus: status, currentPage: 1);
  }

  void updateSelectedCategory(String? category) {
    state = state.copyWith(selectedCategory: category, currentPage: 1);
  }

  void updateSelectedInstructor(int? instructorId) {
    state = state.copyWith(selectedInstructorId: instructorId, currentPage: 1);
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void nextPage() {
    final totalPages = getTotalPages();
    if (state.currentPage < totalPages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  int getTotalPages() {
    final filteredCourses = getFilteredCourses();
    return (filteredCourses.length / state.itemsPerPage).ceil();
  }

  List<Course> getPaginatedCourses() {
    final filteredCourses = getFilteredCourses();
    final startIndex = (state.currentPage - 1) * state.itemsPerPage;
    final endIndex = (startIndex + state.itemsPerPage).clamp(0, filteredCourses.length);
    return filteredCourses.sublist(startIndex, endIndex);
  }

  List<Course> getFilteredCourses() {
    return searchCoursesWithFilters(
      query: state.searchQuery,
      status: state.selectedStatus,
      category: state.selectedCategory,
      instructorId: state.selectedInstructorId,
    );
  }

  // Admin method: Initialize admin course management
  Future<void> initializeAdminCourses() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      // Load all courses
      final allCourses = List<Course>.from(MockData.courses);
      
      state = state.copyWith(
        allCourses: allCourses,
        isLoading: false,
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load courses: $e',
      );
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