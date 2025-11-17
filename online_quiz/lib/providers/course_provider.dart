import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/user.dart' as app_user;
import '../models/quiz.dart';
import '../models/attempt.dart';
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

  // Admin methods
  Future<void> initializeAdminCourses() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final courses = await _courseService.getAllCourses();
      state = state.copyWith(
        allCourses: courses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load admin courses: $e');
    }
  }

  List<Map<String, dynamic>> getPaginatedGroupedCourses() {
    final filtered = getFilteredCourses();
    
    // Group courses by code
    final Map<String, List<Course>> grouped = {};
    for (final course in filtered) {
      if (!grouped.containsKey(course.code)) {
        grouped[course.code] = [];
      }
      grouped[course.code]!.add(course);
    }

    // Convert to list of maps with metadata
    final List<Map<String, dynamic>> groupedList = [];
    for (final entry in grouped.entries) {
      final courses = entry.value;
      final primaryCourse = courses.first;
      
      groupedList.add({
        'courseCode': entry.key,
        'courseName': primaryCourse.name,
        'courses': courses,
        'primaryCourse': primaryCourse,
        'sections': courses.map((c) => c.section ?? 'N/A').toSet().toList(),
        'instructors': courses.map((c) => c.instructorUserId).toSet().toList()
            .map((id) => 'Instructor $id') // Will be replaced with actual names in UI
            .toList(),
        'category': primaryCourse.category,
        'status': primaryCourse.status,
        'totalEnrollments': 0, // Will be calculated if needed
      });
    }

    // Apply pagination
    final startIndex = (state.currentPage - 1) * state.itemsPerPage;
    final endIndex = (startIndex + state.itemsPerPage).clamp(0, groupedList.length);
    
    if (startIndex >= groupedList.length) {
      return [];
    }
    
    return groupedList.sublist(startIndex, endIndex);
  }

  int getTotalGroupedPages() {
    final filtered = getFilteredCourses();
    
    // Group courses by code to get unique course codes
    final uniqueCodes = filtered.map((c) => c.code).toSet().length;
    
    return (uniqueCodes / state.itemsPerPage).ceil().clamp(1, double.infinity).toInt();
  }

  List<Course> getFilteredCourses() {
    var filtered = state.allCourses;

    // Filter by search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((course) {
        return course.name.toLowerCase().contains(query) ||
               course.code.toLowerCase().contains(query) ||
               (course.section?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by status
    if (state.selectedStatus != null) {
      filtered = filtered.where((course) => course.status == state.selectedStatus).toList();
    }

    // Filter by category
    if (state.selectedCategory != null) {
      filtered = filtered.where((course) => course.category == state.selectedCategory).toList();
    }

    // Filter by instructor
    if (state.selectedInstructorId != null) {
      filtered = filtered.where((course) => course.instructorUserId == state.selectedInstructorId).toList();
    }

    return filtered;
  }

  List<Course> getPaginatedCourses() {
    final filtered = getFilteredCourses();
    final startIndex = (state.currentPage - 1) * state.itemsPerPage;
    final endIndex = (startIndex + state.itemsPerPage).clamp(0, filtered.length);
    
    if (startIndex >= filtered.length) {
      return [];
    }
    
    return filtered.sublist(startIndex, endIndex);
  }

  int getTotalPages() {
    final filtered = getFilteredCourses();
    return (filtered.length / state.itemsPerPage).ceil();
  }

  Future<List<app_user.User>> getAllTeachers() async {
    try {
      return await _courseService.getAllTeachers();
    } catch (e) {
      throw Exception('Failed to fetch teachers: $e');
    }
  }

  Future<List<String>> getAvailableSections() async {
    try {
      return await _courseService.getAvailableSections();
    } catch (e) {
      throw Exception('Failed to fetch available sections: $e');
    }
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
    try {
      final newCourse = await _courseService.createCourse(
        code: code,
        name: name,
        instructorUserId: instructorUserId,
        category: category,
        section: section,
        status: status,
        createdBy: createdBy,
      );

      // Add to state
      state = state.copyWith(
        allCourses: [...state.allCourses, newCourse],
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateCourse({
    required int courseId,
    required String code,
    required String name,
    required int instructorUserId,
    String? category,
    String? section,
    required String status,
    int? updatedBy,
  }) async {
    try {
      await _courseService.updateCourse(
        courseId: courseId,
        code: code,
        name: name,
        instructorUserId: instructorUserId,
        category: category,
        section: section,
        status: status,
        updatedBy: updatedBy,
      );

      // Update in state
      final updatedCourses = state.allCourses.map((course) {
        if (course.courseId == courseId) {
          return Course(
            courseId: courseId,
            code: code,
            name: name,
            instructorUserId: instructorUserId,
            status: status,
            category: category,
            section: section,
            createdAt: course.createdAt,
            updatedAt: DateTime.now(),
            createdBy: course.createdBy,
          );
        }
        return course;
      }).toList();

      state = state.copyWith(allCourses: updatedCourses);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCourse(int courseId, {int? deletedBy}) async {
    try {
      await _courseService.deleteCourse(courseId, deletedBy: deletedBy);

      // Remove from state
      final updatedCourses = state.allCourses.where((course) => course.courseId != courseId).toList();
      state = state.copyWith(allCourses: updatedCourses);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getEnrolledStudents(int courseId) async {
    try {
      return await _courseService.getEnrolledStudents(courseId);
    } catch (e) {
      throw Exception('Failed to fetch enrolled students: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableStudents(int courseId) async {
    try {
      return await _courseService.getAvailableStudents(courseId);
    } catch (e) {
      throw Exception('Failed to fetch available students: $e');
    }
  }

  Future<bool> enrollStudent({
    required int userId,
    required int courseId,
    String? section,
    required int enrolledBy,
  }) async {
    try {
      await _courseService.enrollStudent(
        userId: userId,
        courseId: courseId,
        section: section,
        enrolledBy: enrolledBy,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeEnrollment(int enrollmentId) async {
    try {
      await _courseService.removeEnrollment(enrollmentId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> loadAllCourses() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final courses = await _courseService.getAllCourses();
      state = state.copyWith(
        allCourses: courses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get enrolled students with details for a course (Teacher)
  Future<List<Map<String, dynamic>>> getEnrolledStudentsWithDetails(int courseId) async {
    try {
      return await _courseService.getEnrolledStudents(courseId);
    } catch (e) {
      return [];
    }
  }

  /// Get course quizzes (Teacher)
  Future<List<Quiz>> getCourseQuizzes(int courseId) async {
    try {
      return await _courseService.getCourseQuizzes(courseId);
    } catch (e) {
      return [];
    }
  }

  /// Get quiz attempts (Teacher) - returns all attempts for a specific quiz
  Future<List<Attempt>> getQuizAttempts(int quizId) async {
    try {
      // Get all attempts for this quiz from all users
      final response = await Supabase.instance.client
          .from('Attempt')
          .select('*')
          .eq('QuizId', quizId)
          .order('StartedAt', ascending: false);
      
      return response.map((data) => Attempt.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> enrollStudentInCourse(int userId, int courseId, int enrolledBy) async {
    try {
      await _courseService.enrollStudent(
        userId: userId,
        courseId: courseId,
        section: null,
        enrolledBy: enrolledBy,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeStudentFromCourse(int userId, int courseId, [int? removedBy]) async {
    try {
      // First, find the enrollment ID for this user and course
      final response = await Supabase.instance.client
          .from('Enrollment')
          .select('EnrollmentId')
          .eq('UserId', userId)
          .eq('CourseId', courseId)
          .single();
      
      final enrollmentId = response['EnrollmentId'] as int;
      
      // Then remove the enrollment
      await _courseService.removeEnrollment(enrollmentId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
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
