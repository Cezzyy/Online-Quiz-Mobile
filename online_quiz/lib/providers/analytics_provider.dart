import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';

/// Analytics State
class AnalyticsState {
  final Map<int, List<Map<String, dynamic>>> quizAttempts;
  final Map<int, Map<String, dynamic>> quizAnalytics;
  final Map<int, Map<String, dynamic>> courseStatistics;
  final Map<int, List<Map<String, dynamic>>> studentResults;
  final bool isLoading;
  final String? error;

  const AnalyticsState({
    this.quizAttempts = const {},
    this.quizAnalytics = const {},
    this.courseStatistics = const {},
    this.studentResults = const {},
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith({
    Map<int, List<Map<String, dynamic>>>? quizAttempts,
    Map<int, Map<String, dynamic>>? quizAnalytics,
    Map<int, Map<String, dynamic>>? courseStatistics,
    Map<int, List<Map<String, dynamic>>>? studentResults,
    bool? isLoading,
    String? error,
  }) {
    return AnalyticsState(
      quizAttempts: quizAttempts ?? this.quizAttempts,
      quizAnalytics: quizAnalytics ?? this.quizAnalytics,
      courseStatistics: courseStatistics ?? this.courseStatistics,
      studentResults: studentResults ?? this.studentResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Analytics Notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsService _analyticsService = AnalyticsService();

  AnalyticsNotifier() : super(const AnalyticsState());

  /// Get all attempts for a quiz with caching
  Future<List<Map<String, dynamic>>> getQuizAttempts(int quizId, {bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && state.quizAttempts.containsKey(quizId)) {
      return state.quizAttempts[quizId]!;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final attempts = await _analyticsService.getAttemptsByQuiz(quizId);
      
      final updatedAttempts = Map<int, List<Map<String, dynamic>>>.from(state.quizAttempts);
      updatedAttempts[quizId] = attempts;
      
      state = state.copyWith(
        quizAttempts: updatedAttempts,
        isLoading: false,
      );
      
      return attempts;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Get detailed analytics for a quiz with caching
  Future<Map<String, dynamic>> getQuizAnalytics(int quizId, {bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && state.quizAnalytics.containsKey(quizId)) {
      return state.quizAnalytics[quizId]!;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final analytics = await _analyticsService.getQuizAnalytics(quizId);
      
      final updatedAnalytics = Map<int, Map<String, dynamic>>.from(state.quizAnalytics);
      updatedAnalytics[quizId] = analytics;
      
      state = state.copyWith(
        quizAnalytics: updatedAnalytics,
        isLoading: false,
      );
      
      return analytics;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Get course statistics with caching
  Future<Map<String, dynamic>> getCourseStatistics(int courseId, {bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && state.courseStatistics.containsKey(courseId)) {
      return state.courseStatistics[courseId]!;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final statistics = await _analyticsService.getCourseStatistics(courseId);
      
      final updatedStatistics = Map<int, Map<String, dynamic>>.from(state.courseStatistics);
      updatedStatistics[courseId] = statistics;
      
      state = state.copyWith(
        courseStatistics: updatedStatistics,
        isLoading: false,
      );
      
      return statistics;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Get student quiz results with caching
  Future<List<Map<String, dynamic>>> getStudentQuizResults(
    int quizId,
    int courseId, {
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && state.studentResults.containsKey(quizId)) {
      return state.studentResults[quizId]!;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final results = await _analyticsService.getStudentQuizResults(quizId, courseId);
      
      final updatedResults = Map<int, List<Map<String, dynamic>>>.from(state.studentResults);
      updatedResults[quizId] = results;
      
      state = state.copyWith(
        studentResults: updatedResults,
        isLoading: false,
      );
      
      return results;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Get quiz sections (no caching as this is quick)
  Future<List<String>> getQuizSections(int courseId) async {
    try {
      return await _analyticsService.getQuizSections(courseId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Get attempt details (no caching for individual attempts)
  Future<Map<String, dynamic>> getAttemptDetails(int attemptId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final details = await _analyticsService.getAttemptDetails(attemptId);
      
      state = state.copyWith(isLoading: false);
      
      return details;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Get quiz performance trends
  Future<List<Map<String, dynamic>>> getQuizPerformanceTrends(int quizId, {int? limit}) async {
    try {
      return await _analyticsService.getQuizPerformanceTrends(quizId, limit: limit);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Get comparative analytics across quizzes
  Future<List<Map<String, dynamic>>> getComparativeQuizAnalytics(List<int> quizIds) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final analytics = await _analyticsService.getComparativeQuizAnalytics(quizIds);
      
      state = state.copyWith(isLoading: false);
      
      return analytics;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Clear cache for a specific quiz
  void clearQuizCache(int quizId) {
    final updatedAttempts = Map<int, List<Map<String, dynamic>>>.from(state.quizAttempts);
    updatedAttempts.remove(quizId);
    
    final updatedAnalytics = Map<int, Map<String, dynamic>>.from(state.quizAnalytics);
    updatedAnalytics.remove(quizId);
    
    final updatedResults = Map<int, List<Map<String, dynamic>>>.from(state.studentResults);
    updatedResults.remove(quizId);
    
    state = state.copyWith(
      quizAttempts: updatedAttempts,
      quizAnalytics: updatedAnalytics,
      studentResults: updatedResults,
    );
  }

  /// Clear cache for a specific course
  void clearCourseCache(int courseId) {
    final updatedStatistics = Map<int, Map<String, dynamic>>.from(state.courseStatistics);
    updatedStatistics.remove(courseId);
    
    state = state.copyWith(
      courseStatistics: updatedStatistics,
    );
  }

  /// Clear all cache
  void clearAllCache() {
    state = const AnalyticsState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Analytics Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier();
});
