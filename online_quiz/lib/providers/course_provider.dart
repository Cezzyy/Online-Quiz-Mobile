import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/user.dart' as app_user;
import '../models/quiz.dart';
import '../services/course_service.dart';

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
  
  // Admin/filtering properties
  final String searchQuery;
  final String selectedStatus;
  final String selectedCategory;
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
    this.selectedStatus = 'All',
    this.selectedCategory = 'All',
    this.selectedInstructorId,
    this.currentPage = 1,
    this.itemsPerPage = 10,
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
  final CourseService _courseService = CourseService();
  
  CourseNotifier() : super(const CourseState());

  // Initialize course data for a specific user
  Future<void> initializeCourses(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Load user enrollments and courses from Supabase
      final userEnrollments = await _courseService.getUserEnrollments(userId);
      final userCourses = await _courseService.getEnrolledCourses(userId);
      
      // Get all courses for admin/teacher views
      final allCourses = userCourses; // For students, only show enrolled courses
      
      // Calculate progress and quiz counts
      final courseIds = userCourses.map((c) => c.courseId).toList();
      final courseProgress = await _courseService.getCourseProgress(userId, courseIds);
      final quizCounts = await _courseService.getQuizCounts(userId, courseIds);
      
      state = state.copyWith(
        allCourses: allCourses,
        userCourses: userCourses,
        userEnrollments: userEnrollments,
        courseProgress: courseProgress,
        courseQuizCounts: quizCounts['total']!,
        completedQuizCounts: quizCounts['completed']!,
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
      final course = await _courseService.getCourseById(courseId);
      if (course == null) {
        throw Exception('Course not found');
      }
      
      final courseQuizzes = await _courseService.getCourseQuizzes(courseId);
      
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

  // Get instructor for a course
  Future<app_user.User?> getCourseInstructor(int instructorUserId) async {
    try {
      return await _courseService.getCourseInstructor(instructorUserId);
    } catch (e) {
      return null;
    }
  }

  // Admin methods - stubs for now (TODO: implement with backend)
  Future<void> initializeAdminCourses() async {
    // For now, just load all courses - implement proper admin logic later
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: Load all courses from database for admin view
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load admin courses: $e');
    }
  }

  List<Map<String, dynamic>> getPaginatedGroupedCourses() {
    // TODO: Implement grouped courses by code
    return [];
  }

  int getTotalGroupedPages() {
    // TODO: Implement pagination
    return 1;
  }

  List<Course> getFilteredCourses() {
    // TODO: Implement filtering
    return state.allCourses;
  }

  List<app_user.User> getAllTeachers() {
    // TODO: Implement teacher fetching
    return [];
  }

  Future<bool> createCourse({
    required String code,
    required String name,
    required int instructorUserId,
    String? category,
    String? section,
    required String status,
    required int createdBy,
  }) async {
    // TODO: Implement course creation with backend
    return false;
  }

  Future<bool> updateCourse(
    Course course, {
    required String code,
    required String name,
    required int instructorUserId,
    String? category,
    required String status,
  }) async {
    // TODO: Implement course update with backend
    return false;
  }

  Future<bool> deleteCourse(Course course) async {
    // TODO: Implement course deletion with backend
    return false;
  }

  List<Map<String, dynamic>> getEnrolledStudentsWithDetails(int courseId) {
    // TODO: Implement fetching enrolled students
    return [];
  }

  List<app_user.User> getAvailableStudents(int courseId) {
    // TODO: Implement fetching available students
    return [];
  }

  Future<bool> enrollStudentInCourse(int userId, int courseId, int enrolledBy) async {
    // TODO: Implement student enrollment
    return false;
  }

  Future<bool> removeStudentFromCourse(int userId, int courseId, [int? removedBy]) async {
    // TODO: Implement student removal
    return false;
  }

  // Filter/search methods
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
  }

  void updateSelectedStatus(String? status) {
    if (status != null) {
      state = state.copyWith(selectedStatus: status, currentPage: 1);
    }
  }

  void updateSelectedCategory(String? category) {
    if (category != null) {
      state = state.copyWith(selectedCategory: category, currentPage: 1);
    }
  }

  void updateSelectedInstructor(int? instructorId) {
    state = state.copyWith(selectedInstructorId: instructorId, currentPage: 1);
  }

  // Pagination methods
  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void nextPage() {
    state = state.copyWith(currentPage: state.currentPage + 1);
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
