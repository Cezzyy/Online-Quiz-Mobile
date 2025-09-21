import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/attempt.dart';
import '../models/attempt_answer.dart';
import '../models/choice.dart';
import '../models/course.dart';
import '../data/mock_data.dart';
import 'course_provider.dart';

// Quiz state class to hold all quiz-related data and UI state
class QuizState {
  final List<Quiz> allQuizzes;
  final List<Quiz> userQuizzes;
  final List<Quiz> filteredQuizzes;
  final Quiz? selectedQuiz;
  final List<Question> selectedQuizQuestions;
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
  final Map<int, List<Choice>> questionChoices; // questionId -> choices

  const QuizState({
    this.allQuizzes = const [],
    this.userQuizzes = const [],
    this.filteredQuizzes = const [],
    this.selectedQuiz,
    this.selectedQuizQuestions = const [],
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
    this.questionChoices = const {},
  });

  QuizState copyWith({
    List<Quiz>? allQuizzes,
    List<Quiz>? userQuizzes,
    List<Quiz>? filteredQuizzes,
    Quiz? selectedQuiz,
    List<Question>? selectedQuizQuestions,
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
    Map<int, List<Choice>>? questionChoices,
    bool clearError = false,
    bool clearSelectedQuiz = false,
  }) {
    return QuizState(
      allQuizzes: allQuizzes ?? this.allQuizzes,
      userQuizzes: userQuizzes ?? this.userQuizzes,
      filteredQuizzes: filteredQuizzes ?? this.filteredQuizzes,
      selectedQuiz: clearSelectedQuiz ? null : (selectedQuiz ?? this.selectedQuiz),
      selectedQuizQuestions: selectedQuizQuestions ?? this.selectedQuizQuestions,
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
      questionChoices: questionChoices ?? this.questionChoices,
    );
  }

  // Helper methods
  List<Quiz> get paginatedQuizzes {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredQuizzes.length);
    return filteredQuizzes.sublist(startIndex, endIndex);
  }

  int get totalPages => (filteredQuizzes.length / itemsPerPage).ceil();

  int get totalQuizzes => allQuizzes.length;
  int get completedQuizzes => quizCompletionStatus.values.where((completed) => completed).length;
  int get pendingQuizzes => totalQuizzes - completedQuizzes;

  bool isQuizCompleted(int quizId) => quizCompletionStatus[quizId] ?? false;
  Attempt? getQuizAttempt(int quizId) => quizAttempts[quizId];
  double getQuizScore(int quizId) => quizScores[quizId] ?? 0.0;
}

// Quiz notifier class to manage quiz state
class QuizNotifier extends StateNotifier<QuizState> {
  final Ref ref;
  
  QuizNotifier(this.ref) : super(const QuizState());

  // Initialize quiz data for a specific user
  Future<void> initializeQuizzes(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      // Load all quizzes
      final allQuizzes = List<Quiz>.from(MockData.quizzes);
      
      // Load user attempts
      final userAttempts = MockData.getAttemptsByUser(userId);
      
      // Calculate completion status and scores for each quiz
      final Map<int, bool> completionStatus = {};
      final Map<int, Attempt?> attempts = {};
      final Map<int, double> scores = {};
      
      for (final quiz in allQuizzes) {
        final quizAttempts = userAttempts.where((attempt) => 
            attempt.quizId == quiz.quizId && attempt.submittedAt != null).toList();
        
        final isCompleted = quizAttempts.isNotEmpty;
        final latestAttempt = quizAttempts.isNotEmpty ? quizAttempts.last : null;
        
        completionStatus[quiz.quizId] = isCompleted;
        attempts[quiz.quizId] = latestAttempt;
        
        if (latestAttempt != null) {
          final totalPoints = MockData.getQuestionsByQuiz(quiz.quizId)
              .fold<double>(0, (sum, q) => sum + q.points);
          scores[quiz.quizId] = totalPoints > 0 ? (latestAttempt.score / totalPoints) * 100 : 0.0;
        }
      }
      
      // Load attempt answers grouped by attempt ID
      final Map<int, List<AttemptAnswer>> attemptAnswersMap = {};
      for (final attempt in userAttempts) {
        final answers = MockData.attemptAnswers
            .where((answer) => answer.attemptId == attempt.attemptId)
            .toList();
        if (answers.isNotEmpty) {
          attemptAnswersMap[attempt.attemptId] = answers;
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
        userQuizzes: allQuizzes, // For now, all quizzes are available to user
        userAttempts: userAttempts,
        quizCompletionStatus: completionStatus,
        quizAttempts: attempts,
        quizScores: scores,
        attemptAnswers: attemptAnswersMap,
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
        filtered = state.allQuizzes.where((quiz) => !state.isQuizCompleted(quiz.quizId)).toList();
        break;
      case 'Completed':
        filtered = state.allQuizzes.where((quiz) => state.isQuizCompleted(quiz.quizId)).toList();
        break;
      default:
        // For 'All', prioritize pending quizzes first
        final pending = state.allQuizzes.where((quiz) => !state.isQuizCompleted(quiz.quizId)).toList();
        final completed = state.allQuizzes.where((quiz) => state.isQuizCompleted(quiz.quizId)).toList();
        filtered = [...pending, ...completed];
        break;
    }
    
    // Sort filtered quizzes
    if (filter == 'Pending' || filter == 'All') {
      final pendingQuizzes = filtered.where((quiz) => !state.isQuizCompleted(quiz.quizId)).toList();
      pendingQuizzes.sort((a, b) {
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
        filtered = [...pendingQuizzes, ...completedQuizzes];
      } else {
        filtered = pendingQuizzes;
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

  // Load quiz details
  Future<void> loadQuizDetails(int quizId) async {
    state = state.copyWith(isLoadingQuizDetails: true, clearError: true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate API call
      
      final quiz = MockData.getQuizById(quizId);
      final questions = MockData.getQuestionsByQuiz(quizId);
      
      if (quiz != null) {
        state = state.copyWith(
          selectedQuiz: quiz,
          selectedQuizQuestions: questions,
          isLoadingQuizDetails: false,
        );
      } else {
        state = state.copyWith(
          isLoadingQuizDetails: false,
          error: 'Quiz not found',
        );
      }
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
    _applyFilter(state.selectedFilter);
  }

  // Get course for quiz
  Course? getCourseForQuiz(int quizId) {
    final quiz = state.allQuizzes.firstWhere((q) => q.quizId == quizId, orElse: () => Quiz(
      quizId: 0,
      courseId: 0,
      title: '',
      isPublished: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    return quiz.quizId != 0 ? MockData.getCourseById(quiz.courseId) : null;
  }

  // Start a quiz attempt
  Future<void> startQuizAttempt(int quizId, int userId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      // Check if there's already an in-progress attempt
      final existingAttempt = MockData.attempts.where((a) => 
        a.quizId == quizId && 
        a.userId == userId && 
        a.submittedAt == null
      ).firstOrNull;
      
      if (existingAttempt == null) {
        // Create new attempt
        final attemptId = DateTime.now().millisecondsSinceEpoch;
        final newAttempt = Attempt(
          attemptId: attemptId,
          quizId: quizId,
          userId: userId,
          startedAt: DateTime.now(),
          submittedAt: null,
          score: 0.0,
          timeSpentSeconds: 0,
        );
        
        MockData.attempts.add(newAttempt);
      }
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
         isLoading: false,
         error: 'Failed to start quiz attempt: $e',
       );
     }
   }

  // Submit quiz attempt with answers
  Future<Attempt> submitQuizAttempt(
    int quizId,
    int userId,
    Map<int, dynamic> answers,
    DateTime startTime,
    bool autoSubmit,
  ) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      final questions = MockData.getQuestionsByQuiz(quizId);
      double totalScore = 0.0;
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      // Generate unique attempt ID
      final attemptId = DateTime.now().millisecondsSinceEpoch;
      List<AttemptAnswer> attemptAnswers = [];

      for (final question in questions) {
        final userAnswer = answers[question.questionId];
        double questionScore = 0.0;
        bool isCorrect = false;

        if (userAnswer != null) {
          switch (question.type) {
            case QuestionType.single:
              final choices = MockData.getChoicesByQuestion(question.questionId);
              final correctChoice = choices.firstWhere((c) => c.isCorrect);
              isCorrect = userAnswer == correctChoice.choiceId;
              if (isCorrect) {
                questionScore = question.points;
              }
              
              attemptAnswers.add(AttemptAnswer(
                attemptAnswerId: MockData.attemptAnswers.length + attemptAnswers.length + 1,
                attemptId: attemptId,
                questionId: question.questionId,
                choiceId: userAnswer as int,
                freeText: null,
                isCorrect: isCorrect,
              ));
              break;

            case QuestionType.multiple:
              final choices = MockData.getChoicesByQuestion(question.questionId);
              final correctChoiceIds = choices.where((c) => c.isCorrect).map((c) => c.choiceId).toSet();
              final selectedChoiceIds = (userAnswer as List<int>).toSet();
              
              if (correctChoiceIds.isNotEmpty && selectedChoiceIds.isNotEmpty) {
                final correctSelected = correctChoiceIds.intersection(selectedChoiceIds).length;
                final incorrectSelected = selectedChoiceIds.difference(correctChoiceIds).length;
                final totalCorrect = correctChoiceIds.length;
                
                // Check if all correct answers are selected and no incorrect ones
                isCorrect = correctSelected == totalCorrect && incorrectSelected == 0;
                
                if (isCorrect) {
                  questionScore = question.points;
                } else {
                  // Partial scoring: (correct selections - incorrect selections) / total correct
                  final partialScore = (correctSelected - incorrectSelected) / totalCorrect;
                  questionScore = (partialScore.clamp(0.0, 1.0) * question.points);
                }
              }
              
              // For multiple choice, create separate answers for each selected choice
              for (final choiceId in userAnswer) {
                final choice = choices.firstWhere((c) => c.choiceId == choiceId);
                attemptAnswers.add(AttemptAnswer(
                  attemptAnswerId: MockData.attemptAnswers.length + attemptAnswers.length + 1,
                  attemptId: attemptId,
                  questionId: question.questionId,
                  choiceId: choiceId,
                  freeText: null,
                  isCorrect: choice.isCorrect,
                ));
              }
              break;

            case QuestionType.text:
              // For text questions, give full points if there's an answer
              final textAnswer = userAnswer as String;
              isCorrect = textAnswer.trim().isNotEmpty;
              if (isCorrect) {
                questionScore = question.points;
              }
              
              attemptAnswers.add(AttemptAnswer(
                attemptAnswerId: MockData.attemptAnswers.length + attemptAnswers.length + 1,
                attemptId: attemptId,
                questionId: question.questionId,
                choiceId: null,
                freeText: textAnswer,
                isCorrect: isCorrect,
              ));
              break;
          }
        } else {
          // No answer provided
          attemptAnswers.add(AttemptAnswer(
            attemptAnswerId: MockData.attemptAnswers.length + attemptAnswers.length + 1,
            attemptId: attemptId,
            questionId: question.questionId,
            choiceId: null,
            freeText: null,
            isCorrect: false,
          ));
        }

        totalScore += questionScore;
      }

      // Create the attempt
      final attempt = Attempt(
        attemptId: attemptId,
        quizId: quizId,
        userId: userId,
        startedAt: startTime,
        submittedAt: endTime,
        score: totalScore,
        timeSpentSeconds: duration.inSeconds,
      );

      // Add to mock data
      MockData.attempts.add(attempt);
      MockData.attemptAnswers.addAll(attemptAnswers);

      // Update state with the new attempt answers
      final updatedAttemptAnswers = Map<int, List<AttemptAnswer>>.from(state.attemptAnswers);
      updatedAttemptAnswers[attemptId] = attemptAnswers;

      // Refresh quiz data to reflect the new attempt
      await initializeQuizzes(userId);
      
      // Also refresh course provider to update progress
      await ref.read(courseProvider.notifier).initializeCourses(userId);
      
      // Update state with attempt answers
      state = state.copyWith(
        isLoading: false,
        attemptAnswers: updatedAttemptAnswers,
      );
      return attempt;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit quiz: $e',
      );
      rethrow;
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
  return {
    'total': state.totalQuizzes,
    'completed': state.completedQuizzes,
    'pending': state.pendingQuizzes,
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