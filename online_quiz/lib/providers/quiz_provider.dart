import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/attempt.dart';
import '../models/attempt_answer.dart';
import '../models/choice.dart';
import '../models/course.dart';
import '../services/quiz_service.dart';
import '../services/teacher_quiz_service.dart';
import '../services/course_service.dart';
import 'course_provider.dart';

// Quiz state class to hold all quiz-related data and UI state
class QuizState {
  final List<Quiz> allQuizzes;
  final List<Quiz> userQuizzes;
  final List<Quiz> filteredQuizzes;
  final Quiz? selectedQuiz;
  final List<Question> selectedQuizQuestions;
  final Map<int, List<Choice>> questionChoices; // questionId -> choices
  final List<Attempt> userAttempts;
  final bool isLoading;
  final bool isLoadingQuizDetails;
  final String? error;
  final String selectedFilter;
  final int currentPage;
  final int itemsPerPage;
  final Map<int, bool> quizCompletionStatus; // quizId -> isCompleted
  final Map<int, Attempt?> quizAttempts; // quizId -> latest attempt
  final Map<int, double> quizScores; // quizId -> score percentage
  final Map<int, List<AttemptAnswer>> attemptAnswers; // attemptId -> answers
  final Map<int, Course> courseCache; // courseId -> course (for performance)

  const QuizState({
    this.allQuizzes = const [],
    this.userQuizzes = const [],
    this.filteredQuizzes = const [],
    this.selectedQuiz,
    this.selectedQuizQuestions = const [],
    this.questionChoices = const {},
    this.userAttempts = const [],
    this.isLoading = false,
    this.isLoadingQuizDetails = false,
    this.error,
    this.selectedFilter = 'All',
    this.currentPage = 0,
    this.itemsPerPage = 10,
    this.quizCompletionStatus = const {},
    this.quizAttempts = const {},
    this.quizScores = const {},
    this.attemptAnswers = const {},
    this.courseCache = const {},
  });

  QuizState copyWith({
    List<Quiz>? allQuizzes,
    List<Quiz>? userQuizzes,
    List<Quiz>? filteredQuizzes,
    Quiz? selectedQuiz,
    List<Question>? selectedQuizQuestions,
    Map<int, List<Choice>>? questionChoices,
    List<Attempt>? userAttempts,
    bool? isLoading,
    bool? isLoadingQuizDetails,
    String? error,
    String? selectedFilter,
    int? currentPage,
    int? itemsPerPage,
    Map<int, bool>? quizCompletionStatus,
    Map<int, Attempt?>? quizAttempts,
    Map<int, double>? quizScores,
    Map<int, List<AttemptAnswer>>? attemptAnswers,
    Map<int, Course>? courseCache,
    bool clearError = false,
    bool clearSelectedQuiz = false,
  }) {
    return QuizState(
      allQuizzes: allQuizzes ?? this.allQuizzes,
      userQuizzes: userQuizzes ?? this.userQuizzes,
      filteredQuizzes: filteredQuizzes ?? this.filteredQuizzes,
      selectedQuiz: clearSelectedQuiz ? null : (selectedQuiz ?? this.selectedQuiz),
      selectedQuizQuestions: selectedQuizQuestions ?? this.selectedQuizQuestions,
      questionChoices: questionChoices ?? this.questionChoices,
      userAttempts: userAttempts ?? this.userAttempts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingQuizDetails: isLoadingQuizDetails ?? this.isLoadingQuizDetails,
      error: clearError ? null : (error ?? this.error),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      quizCompletionStatus: quizCompletionStatus ?? this.quizCompletionStatus,
      quizAttempts: quizAttempts ?? this.quizAttempts,
      quizScores: quizScores ?? this.quizScores,
      attemptAnswers: attemptAnswers ?? this.attemptAnswers,
      courseCache: courseCache ?? this.courseCache,
    );
  }

  // Helper methods
  List<Quiz> get paginatedQuizzes {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredQuizzes.length);
    return filteredQuizzes.sublist(startIndex, endIndex);
  }

  int get totalPages => filteredQuizzes.isEmpty ? 1 : (filteredQuizzes.length / itemsPerPage).ceil();

  int get totalQuizzes => allQuizzes.length;
  int get completedQuizzes => quizCompletionStatus.values.where((completed) => completed).length;
  int get pendingQuizzes => totalQuizzes - completedQuizzes;

  bool isQuizCompleted(int quizId) => quizCompletionStatus[quizId] ?? false;
  Attempt? getQuizAttempt(int quizId) => quizAttempts[quizId];
  double getQuizScore(int quizId) => quizScores[quizId] ?? 0.0;
  Course? getCachedCourse(int courseId) => courseCache[courseId];
}

// Quiz notifier class to manage quiz state
class QuizNotifier extends StateNotifier<QuizState> {
  final Ref ref;
  final QuizService _quizService = QuizService();
  final TeacherQuizService _teacherQuizService = TeacherQuizService();
  
  QuizNotifier(this.ref) : super(const QuizState());

  // Initialize quiz data for a specific user
  Future<void> initializeQuizzes(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Load all data in parallel for better performance
      final results = await Future.wait([
        _quizService.getAvailableQuizzes(userId),
        _quizService.getUserAttempts(userId),
      ]);
      
      final allQuizzes = results[0] as List<Quiz>;
      final userAttempts = results[1] as List<Attempt>;
      
      // Get all unique quiz IDs and course IDs
      final quizIds = allQuizzes.map((q) => q.quizId).toList();
      final courseIds = allQuizzes.map((q) => q.courseId).toSet().toList();
      final attemptIds = userAttempts.map((a) => a.attemptId).toList();
      
      // Batch fetch questions, answers, and courses in parallel
      final batchResults = await Future.wait([
        if (quizIds.isNotEmpty) _quizService.getQuestionsForQuizzes(quizIds),
        if (attemptIds.isNotEmpty) _quizService.getAnswersForAttempts(attemptIds),
        if (courseIds.isNotEmpty) ref.read(courseProvider.notifier).getCoursesByIds(courseIds),
      ]);
      
      final questionsByQuiz = quizIds.isNotEmpty 
          ? batchResults[0] as Map<int, List<dynamic>>
          : <int, List<dynamic>>{};
      final answersByAttempt = attemptIds.isNotEmpty 
          ? batchResults[quizIds.isNotEmpty ? 1 : 0] as Map<int, List<AttemptAnswer>>
          : <int, List<AttemptAnswer>>{};
      final courses = courseIds.isNotEmpty
          ? batchResults[quizIds.isNotEmpty && attemptIds.isNotEmpty ? 2 : (quizIds.isNotEmpty || attemptIds.isNotEmpty ? 1 : 0)] as List<Course>
          : <Course>[];
      
      // Build course cache
      final Map<int, Course> courseCache = {};
      for (final course in courses) {
        courseCache[course.courseId] = course;
      }
      
      // Calculate completion status and scores for each quiz
      final Map<int, bool> completionStatus = {};
      final Map<int, Attempt?> attempts = {};
      final Map<int, double> scores = {};
      
      for (final quiz in allQuizzes) {
        final quizAttempts = userAttempts.where((attempt) => 
            attempt.quizId == quiz.quizId && attempt.submittedAt != null).toList();
        
        final isCompleted = quizAttempts.isNotEmpty;
        final latestAttempt = quizAttempts.isNotEmpty ? quizAttempts.first : null;
        
        completionStatus[quiz.quizId] = isCompleted;
        attempts[quiz.quizId] = latestAttempt;
        
        if (latestAttempt != null) {
          final questions = questionsByQuiz[quiz.quizId] ?? [];
          final totalPoints = questions.fold<double>(0, (sum, q) => sum + (q['Points'] as num).toDouble());
          scores[quiz.quizId] = totalPoints > 0 ? (latestAttempt.score / totalPoints) * 100 : 0.0;
        }
      }

      // Sort quizzes by due date (earliest first, null dates last)
      allQuizzes.sort((a, b) {
        if (a.dueAt == null && b.dueAt == null) return 0;
        if (a.dueAt == null) return 1;
        if (b.dueAt == null) return -1;
        return a.dueAt!.compareTo(b.dueAt!);
      });
      
      state = state.copyWith(
        allQuizzes: allQuizzes,
        userQuizzes: allQuizzes,
        userAttempts: userAttempts,
        quizCompletionStatus: completionStatus,
        quizAttempts: attempts,
        quizScores: scores,
        attemptAnswers: answersByAttempt,
        courseCache: courseCache,
        isLoading: false,
      );
      
      // Apply initial filter
      _applyFilter(state.selectedFilter);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load quizzes: $e',
      );
    }
  }

  // Set filter and apply it
  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter, currentPage: 0);
    _applyFilter(filter);
  }

  // Apply filter to quizzes
  void _applyFilter(String filter) {
    List<Quiz> filtered;
    
    switch (filter) {
      case 'Pending':
        // Only show quizzes that are not completed and not overdue
        filtered = state.allQuizzes.where((quiz) => 
          !state.isQuizCompleted(quiz.quizId) && !quiz.isOverdue
        ).toList();
        break;
      case 'Overdue':
        // Only show quizzes that are not completed and overdue
        filtered = state.allQuizzes.where((quiz) => 
          !state.isQuizCompleted(quiz.quizId) && quiz.isOverdue
        ).toList();
        break;
      case 'Completed':
        filtered = state.allQuizzes.where((quiz) => state.isQuizCompleted(quiz.quizId)).toList();
        break;
      default:
        // For 'All', prioritize pending, then overdue, then completed
        final pending = state.allQuizzes.where((quiz) => 
          !state.isQuizCompleted(quiz.quizId) && !quiz.isOverdue
        ).toList();
        final overdue = state.allQuizzes.where((quiz) => 
          !state.isQuizCompleted(quiz.quizId) && quiz.isOverdue
        ).toList();
        final completed = state.allQuizzes.where((quiz) => state.isQuizCompleted(quiz.quizId)).toList();
        filtered = [...pending, ...overdue, ...completed];
        break;
    }
    
    // Sort filtered quizzes
    if (filter == 'Pending' || filter == 'Overdue' || filter == 'All') {
      final incompleteQuizzes = filtered.where((quiz) => !state.isQuizCompleted(quiz.quizId)).toList();
      incompleteQuizzes.sort((a, b) {
        if (a.dueAt == null && b.dueAt == null) return 0;
        if (a.dueAt == null) return 1;
        if (b.dueAt == null) return -1;
        return a.dueAt!.compareTo(b.dueAt!);
      });
      
      if (filter == 'All') {
        final completedQuizzes = filtered.where((quiz) => state.isQuizCompleted(quiz.quizId)).toList();
        completedQuizzes.sort((a, b) {
          final attemptA = state.getQuizAttempt(a.quizId);
          final attemptB = state.getQuizAttempt(b.quizId);
          if (attemptA?.submittedAt == null || attemptB?.submittedAt == null) return 0;
          return attemptB!.submittedAt!.compareTo(attemptA!.submittedAt!);
        });
        filtered = [...incompleteQuizzes, ...completedQuizzes];
      } else {
        filtered = incompleteQuizzes;
      }
    } else if (filter == 'Completed') {
      filtered.sort((a, b) {
        final attemptA = state.getQuizAttempt(a.quizId);
        final attemptB = state.getQuizAttempt(b.quizId);
        if (attemptA?.submittedAt == null || attemptB?.submittedAt == null) return 0;
        return attemptB!.submittedAt!.compareTo(attemptA!.submittedAt!);
      });
    }
    
    state = state.copyWith(filteredQuizzes: filtered);
  }

  // Set current page for pagination
  void setCurrentPage(int page) {
    if (page >= 0 && page < state.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  // Go to next page
  void nextPage() {
    if (state.currentPage < state.totalPages - 1) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  // Go to previous page
  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  // Load quiz details with questions and choices
  Future<void> loadQuizDetails(int quizId) async {
    state = state.copyWith(isLoadingQuizDetails: true, clearError: true);
    
    try {
      final quiz = await _quizService.getQuizById(quizId);
      if (quiz == null) {
        throw Exception('Quiz not found');
      }
      
      final questions = await _quizService.getQuizQuestions(quizId);
      final questionIds = questions.map((q) => q.questionId).toList();
      final choices = await _quizService.getChoicesForQuestions(questionIds);
      
      state = state.copyWith(
        selectedQuiz: quiz,
        selectedQuizQuestions: questions,
        questionChoices: choices,
        isLoadingQuizDetails: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingQuizDetails: false,
        error: 'Failed to load quiz details: $e',
      );
    }
  }

  // Refresh quiz data
  Future<void> refreshQuizzes(int userId) async {
    await initializeQuizzes(userId);
  }

  // Clear selected quiz
  void clearSelectedQuiz() {
    state = state.copyWith(clearSelectedQuiz: true);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Set current page for pagination
  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  // Get course for quiz
  Course? getCourseForQuizSync(int quizId) {
    final quiz = state.allQuizzes.where((q) => q.quizId == quizId).firstOrNull;
    if (quiz == null) return null;
    
    return state.getCachedCourse(quiz.courseId);
  }

  Future<Course?> getCourseForQuiz(int quizId) async {
    final quiz = state.allQuizzes.where((q) => q.quizId == quizId).firstOrNull;
    if (quiz == null) return null;
    
    // Try cache first
    final cachedCourse = state.getCachedCourse(quiz.courseId);
    if (cachedCourse != null) return cachedCourse;
    
    // Fallback to fetching from course provider
    return await ref.read(courseProvider.notifier).getCourseById(quiz.courseId);
  }

  // Start a quiz attempt
  Future<Attempt?> startQuizAttempt(int quizId, int userId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      final attempt = await _quizService.startAttempt(userId, quizId);
      
      state = state.copyWith(isLoading: false);
      return attempt;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start quiz attempt: $e',
      );
      return null;
    }
  }

  // Submit quiz attempt with answers
  Future<Attempt?> submitQuizAttempt({
    required int attemptId,
    required int quizId,
    required int userId,
    required Map<int, dynamic> answers,
    required DateTime startTime,
    required bool autoSubmit,
    String? userRole,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      final attempt = await _quizService.submitAttempt(
        attemptId: attemptId,
        quizId: quizId,
        userId: userId,
        answers: answers,
        startTime: startTime,
        autoSubmit: autoSubmit,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Quiz submission timed out. Please check your connection and try again.');
        },
      );
      
      // Refresh quiz data to reflect the new attempt
      await initializeQuizzes(userId);
      
      // Also refresh course provider to update progress
      await ref.read(courseProvider.notifier).initializeCourses(userId, userRole: userRole);
      
      state = state.copyWith(isLoading: false);
      return attempt;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit quiz: $e',
      );
      return null;
    }
  }

  // Get attempt details (for results screen)
  Future<Map<String, dynamic>?> getAttemptDetails(int attemptId) async {
    try {
      final details = await _quizService.getAttemptDetails(attemptId);
      
      // Update state with the attempt answers
      // The service returns answers grouped by question, but we need to flatten them
      final answersByQuestion = details['answers'] as Map<int, List<AttemptAnswer>>;
      final allAnswers = <AttemptAnswer>[];
      answersByQuestion.forEach((questionId, answers) {
        allAnswers.addAll(answers);
      });
      
      // Store answers indexed by attemptId
      final updatedAttemptAnswers = Map<int, List<AttemptAnswer>>.from(state.attemptAnswers);
      updatedAttemptAnswers[attemptId] = allAnswers;
      
      state = state.copyWith(
        attemptAnswers: updatedAttemptAnswers,
      );
      
      return details;
    } catch (e) {
      state = state.copyWith(error: 'Failed to load attempt details: $e');
      return null;
    }
  }

  // Get quiz result details with all related data (for results list)
  Future<Map<String, dynamic>?> getQuizResultDetails(Attempt attempt) async {
    try {
      // Get quiz details
      final quiz = await _quizService.getQuizById(attempt.quizId);
      if (quiz == null) return null;

      // Get course details
      final courseService = CourseService();
      final course = await courseService.getCourseById(quiz.courseId);
      if (course == null) return null;

      // Get questions and answers
      final questions = await _quizService.getQuizQuestions(attempt.quizId);
      final answers = await _quizService.getAttemptAnswers(attempt.attemptId);

      // Calculate statistics
      final totalQuestions = questions.length;
      final totalPoints = questions.fold<double>(0.0, (sum, q) => sum + q.points);
      final percentage = totalPoints > 0 ? (attempt.score / totalPoints) * 100 : 0.0;
      final correctAnswers = answers.where((a) => a.isCorrect == true).length;

      return {
        'attempt': attempt,
        'quiz': quiz,
        'course': course,
        'percentage': percentage,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'questions': questions,
        'answers': answers,
      };
    } catch (e) {
      state = state.copyWith(error: 'Failed to load quiz result details: $e');
      return null;
    }
  }

  // Get all quiz results for a user
  Future<List<Map<String, dynamic>>> getAllQuizResults(int userId) async {
    try {
      return await _quizService.getAllQuizResults(userId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load quiz results: $e');
      return [];
    }
  }

  // ==================== TEACHER QUIZ MANAGEMENT ====================

  /// Create a new quiz (Teacher)
  Future<Quiz?> createQuiz({
    required int courseId,
    required String title,
    required int createdBy,
    DateTime? dueAt,
    int? timeLimitMinutes,
    bool isPublished = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final quiz = await _teacherQuizService.createQuiz(
        courseId: courseId,
        title: title,
        createdBy: createdBy,
        dueAt: dueAt,
        timeLimitMinutes: timeLimitMinutes,
        isPublished: isPublished,
      );

      // Refresh quizzes list
      final updatedQuizzes = [...state.allQuizzes, quiz];
      state = state.copyWith(
        allQuizzes: updatedQuizzes,
        isLoading: false,
      );

      return quiz;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create quiz: $e',
      );
      return null;
    }
  }

  /// Update an existing quiz (Teacher)
  Future<bool> updateQuiz({
    required int quizId,
    String? title,
    DateTime? dueAt,
    int? timeLimitMinutes,
    bool? isPublished,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final updatedQuiz = await _teacherQuizService.updateQuiz(
        quizId: quizId,
        title: title,
        dueAt: dueAt,
        timeLimitMinutes: timeLimitMinutes,
        isPublished: isPublished,
      );

      // Update quiz in the list
      final updatedQuizzes = state.allQuizzes.map((q) {
        return q.quizId == quizId ? updatedQuiz : q;
      }).toList();

      state = state.copyWith(
        allQuizzes: updatedQuizzes,
        selectedQuiz: state.selectedQuiz?.quizId == quizId ? updatedQuiz : state.selectedQuiz,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update quiz: $e',
      );
      return false;
    }
  }

  /// Delete a quiz (Teacher)
  Future<bool> deleteQuiz(int quizId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _teacherQuizService.deleteQuiz(quizId);

      // Remove quiz from the list
      final updatedQuizzes = state.allQuizzes.where((q) => q.quizId != quizId).toList();

      state = state.copyWith(
        allQuizzes: updatedQuizzes,
        selectedQuiz: state.selectedQuiz?.quizId == quizId ? null : state.selectedQuiz,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete quiz: $e',
      );
      return false;
    }
  }

  /// Toggle quiz publish status (Teacher)
  Future<bool> togglePublishQuiz(int quizId, bool isPublished) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final updatedQuiz = await _teacherQuizService.togglePublishQuiz(quizId, isPublished);

      // Update quiz in the list
      final updatedQuizzes = state.allQuizzes.map((q) {
        return q.quizId == quizId ? updatedQuiz : q;
      }).toList();

      state = state.copyWith(
        allQuizzes: updatedQuizzes,
        selectedQuiz: state.selectedQuiz?.quizId == quizId ? updatedQuiz : state.selectedQuiz,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to toggle publish status: $e',
      );
      return false;
    }
  }

  /// Create a complete quiz with questions and choices (Teacher)
  Future<Quiz?> createCompleteQuiz({
    required int courseId,
    required String title,
    required int createdBy,
    DateTime? dueAt,
    int? timeLimitMinutes,
    bool isPublished = false,
    required List<Map<String, dynamic>> questionsWithChoices,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final quiz = await _teacherQuizService.createCompleteQuiz(
        courseId: courseId,
        title: title,
        createdBy: createdBy,
        dueAt: dueAt,
        timeLimitMinutes: timeLimitMinutes,
        isPublished: isPublished,
        questionsWithChoices: questionsWithChoices,
      );

      // Refresh quizzes list
      final updatedQuizzes = [...state.allQuizzes, quiz];
      state = state.copyWith(
        allQuizzes: updatedQuizzes,
        isLoading: false,
      );

      return quiz;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create complete quiz: $e',
      );
      return null;
    }
  }

  /// Update a complete quiz with questions and choices (Teacher)
  Future<bool> updateCompleteQuiz({
    required int quizId,
    String? title,
    DateTime? dueAt,
    int? timeLimitMinutes,
    bool? isPublished,
    List<Map<String, dynamic>>? questionsWithChoices,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final updatedQuiz = await _teacherQuizService.updateCompleteQuiz(
        quizId: quizId,
        title: title,
        dueAt: dueAt,
        timeLimitMinutes: timeLimitMinutes,
        isPublished: isPublished,
        questionsWithChoices: questionsWithChoices,
      );

      // Update quiz in the list
      final updatedQuizzes = state.allQuizzes.map((q) {
        return q.quizId == quizId ? updatedQuiz : q;
      }).toList();

      state = state.copyWith(
        allQuizzes: updatedQuizzes,
        selectedQuiz: state.selectedQuiz?.quizId == quizId ? updatedQuiz : state.selectedQuiz,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update complete quiz: $e',
      );
      return false;
    }
  }

  /// Get question count for a quiz (Teacher)
  Future<int> getQuestionCount(int quizId) async {
    try {
      return await _teacherQuizService.getQuestionCount(quizId);
    } catch (e) {
      return 0;
    }
  }

  /// Get total points for a quiz (Teacher)
  Future<double> getTotalPoints(int quizId) async {
    try {
      return await _teacherQuizService.getTotalPoints(quizId);
    } catch (e) {
      return 0.0;
    }
  }

  /// Validate quiz before publishing (Teacher)
  Future<Map<String, dynamic>> validateQuiz(int quizId) async {
    try {
      return await _teacherQuizService.validateQuiz(quizId);
    } catch (e) {
      return {
        'valid': false,
        'message': 'Failed to validate quiz: $e',
      };
    }
  }

  /// Load quizzes for a specific course (Teacher)
  Future<void> loadQuizzesForCourse(int courseId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final quizzes = await _quizService.getQuizzesByCourse(courseId);

      state = state.copyWith(
        allQuizzes: quizzes,
        filteredQuizzes: quizzes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load quizzes: $e',
      );
    }
  }
}

// Main quiz provider
final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>(
  (ref) => QuizNotifier(ref),
);

// Convenience providers for specific data
final allQuizzesProvider = Provider<List<Quiz>>((ref) {
  return ref.watch(quizProvider).allQuizzes;
});

final filteredQuizzesProvider = Provider<List<Quiz>>((ref) {
  return ref.watch(quizProvider).filteredQuizzes;
});

final paginatedQuizzesProvider = Provider<List<Quiz>>((ref) {
  return ref.watch(quizProvider).paginatedQuizzes;
});

final selectedQuizProvider = Provider<Quiz?>((ref) {
  return ref.watch(quizProvider).selectedQuiz;
});

final selectedQuizQuestionsProvider = Provider<List<Question>>((ref) {
  return ref.watch(quizProvider).selectedQuizQuestions;
});

final quizLoadingProvider = Provider<bool>((ref) {
  return ref.watch(quizProvider).isLoading;
});

final quizDetailsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(quizProvider).isLoadingQuizDetails;
});

final quizErrorProvider = Provider<String?>((ref) {
  return ref.watch(quizProvider).error;
});

final quizFilterProvider = Provider<String>((ref) {
  return ref.watch(quizProvider).selectedFilter;
});

final quizStatsProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(quizProvider);
  
  // Calculate overdue and pending counts
  final incompleteQuizzes = state.allQuizzes.where((quiz) => !state.isQuizCompleted(quiz.quizId)).toList();
  final overdueCount = incompleteQuizzes.where((quiz) => quiz.isOverdue).length;
  final pendingCount = incompleteQuizzes.where((quiz) => !quiz.isOverdue).length;
  
  return {
    'total': state.totalQuizzes,
    'completed': state.completedQuizzes,
    'pending': pendingCount,
    'overdue': overdueCount,
  };
});

// Provider to check if quiz is completed
final quizCompletionProvider = Provider.family<bool, int>((ref, quizId) {
  return ref.watch(quizProvider).isQuizCompleted(quizId);
});

// Provider to get quiz attempt
final quizAttemptProvider = Provider.family<Attempt?, int>((ref, quizId) {
  return ref.watch(quizProvider).getQuizAttempt(quizId);
});

// Provider to get quiz score
final quizScoreProvider = Provider.family<double, int>((ref, quizId) {
  return ref.watch(quizProvider).getQuizScore(quizId);
});

// Provider for pagination info
final quizPaginationProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(quizProvider);
  return {
    'currentPage': state.currentPage,
    'totalPages': state.totalPages,
    'itemsPerPage': state.itemsPerPage,
  };
});
