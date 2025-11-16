import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/teacher.dart';
import '../models/course.dart';
import '../models/quiz.dart';
import '../services/teacher_service.dart';
import '../services/course_service.dart';
import '../services/quiz_service.dart';

// State class to hold teacher profile data and UI state
class TeacherProfileState {
  final User? user;
  final Teacher? teacher;
  final List<Course> courses;
  final List<Quiz> quizzes;
  final double totalStudents;
  final bool isLoading;
  final String? error;

  const TeacherProfileState({
    this.user,
    this.teacher,
    this.courses = const [],
    this.quizzes = const [],
    this.totalStudents = 0,
    this.isLoading = false,
    this.error,
  });

  TeacherProfileState copyWith({
    User? user,
    Teacher? teacher,
    List<Course>? courses,
    List<Quiz>? quizzes,
    double? totalStudents,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TeacherProfileState(
      user: user ?? this.user,
      teacher: teacher ?? this.teacher,
      courses: courses ?? this.courses,
      quizzes: quizzes ?? this.quizzes,
      totalStudents: totalStudents ?? this.totalStudents,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Notifier class to manage teacher profile state
class TeacherProfileNotifier extends StateNotifier<TeacherProfileState> {
  TeacherProfileNotifier() : super(const TeacherProfileState());

  // Load teacher data based on user ID
  Future<void> loadTeacherData(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final teacherService = TeacherService();
      final courseService = CourseService();
      final quizService = QuizService();
      
      // Get teacher data with user info
      final teacherData = await teacherService.getTeacherWithUser(userId);
      if (teacherData == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Teacher not found',
        );
        return;
      }

      // Extract user and teacher from combined data
      final user = User(
        userId: teacherData['UserId'] as int,
        fullName: teacherData['FullName'] as String,
        email: teacherData['Email'] as String,
        passwordHash: '', // Not needed for display
        status: teacherData['Status'] as String? ?? 'Active',
        contactNumber: teacherData['ContactNumber'] as String? ?? '',
        emergencyContactNumber: teacherData['EmergencyContactNumber'] as String? ?? '',
        createdAt: DateTime.parse(teacherData['CreatedAt'] as String),
        updatedAt: teacherData['UpdatedAt'] != null 
            ? DateTime.parse(teacherData['UpdatedAt'] as String)
            : DateTime.parse(teacherData['CreatedAt'] as String),
        createdBy: teacherData['CreatedBy'] as int?,
      );

      final teacher = Teacher(
        userId: teacherData['UserId'] as int,
        department: teacherData['Department'] as String?,
      );

      // Get teacher's courses
      final courses = await courseService.getCoursesByInstructor(userId);
      
      // Get all quizzes for teacher's courses
      final quizzes = <Quiz>[];
      for (final course in courses) {
        final courseQuizzes = await quizService.getQuizzesByCourse(course.courseId);
        quizzes.addAll(courseQuizzes);
      }

      // Get teacher statistics for total students
      final statistics = await teacherService.getTeacherStatistics(userId);
      final totalStudents = (statistics['totalStudents'] as num?)?.toDouble() ?? 0.0;

      state = state.copyWith(
        user: user,
        teacher: teacher,
        courses: courses,
        quizzes: quizzes,
        totalStudents: totalStudents,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load teacher data: $e',
      );
    }
  }

  // Refresh teacher data
  Future<void> refreshTeacherData(int userId) async {
    await loadTeacherData(userId);
  }

  // Get teaching statistics
  Map<String, num> getTeachingStatistics() {
    return {
      'courses': state.courses.length,
      'quizzes': state.quizzes.length,
      'students': state.totalStudents,
    };
  }

  // Get courses by status
  List<Course> getCoursesByStatus(String status) {
    return state.courses;
  }

  // Get recent quizzes
  List<Quiz> getRecentQuizzes({int limit = 5}) {
    final sortedQuizzes = List<Quiz>.from(state.quizzes);
    sortedQuizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedQuizzes.take(limit).toList();
  }

  // Get upcoming quizzes
  List<Quiz> getUpcomingQuizzes() {
    final now = DateTime.now();
    return state.quizzes.where((quiz) => 
      quiz.dueAt?.isAfter(now) == true && quiz.isPublished
    ).toList();
  }

  // Get overdue quizzes
  List<Quiz> getOverdueQuizzes() {
    final now = DateTime.now();
    return state.quizzes.where((quiz) => 
      quiz.dueAt?.isBefore(now) == true && quiz.isPublished
    ).toList();
  }
}

// Provider for teacher profile state management
final teacherProfileProvider = StateNotifierProvider<TeacherProfileNotifier, TeacherProfileState>(
  (ref) => TeacherProfileNotifier(),
);

// Convenience providers
final teacherUserProvider = Provider<User?>((ref) {
  return ref.watch(teacherProfileProvider).user;
});

final teacherDataProvider = Provider<Teacher?>((ref) {
  return ref.watch(teacherProfileProvider).teacher;
});

final teacherCoursesProvider = Provider<List<Course>>((ref) {
  return ref.watch(teacherProfileProvider).courses;
});

final teacherQuizzesProvider = Provider<List<Quiz>>((ref) {
  return ref.watch(teacherProfileProvider).quizzes;
});

final teacherStatisticsProvider = Provider<Map<String, num>>((ref) {
  final state = ref.watch(teacherProfileProvider);
  return {
    'courses': state.courses.length,
    'quizzes': state.quizzes.length,
    'students': state.totalStudents,
  };
});

final teacherIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(teacherProfileProvider).isLoading;
});

final teacherErrorProvider = Provider<String?>((ref) {
  return ref.watch(teacherProfileProvider).error;
});
