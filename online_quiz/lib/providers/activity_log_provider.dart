import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_log.dart';
import '../services/activity_log_service.dart';

/// Provider for ActivityLogService
final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService();
});

/// State class for activity logs
class ActivityLogState {
  final List<ActivityLog> logs;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final ActivityStatistics? statistics;

  // Filters
  final ActivityAction? filterAction;
  final EntityType? filterEntity;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  // Pagination
  final int currentPage;
  final int itemsPerPage;

  ActivityLogState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
    this.statistics,
    this.filterAction,
    this.filterEntity,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.currentPage = 1,
    this.itemsPerPage = 20,
  });

  ActivityLogState copyWith({
    List<ActivityLog>? logs,
    bool? isLoading,
    String? error,
    int? totalCount,
    ActivityStatistics? statistics,
    ActivityAction? filterAction,
    EntityType? filterEntity,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? currentPage,
    int? itemsPerPage,
  }) {
    return ActivityLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalCount: totalCount ?? this.totalCount,
      statistics: statistics ?? this.statistics,
      filterAction: filterAction ?? this.filterAction,
      filterEntity: filterEntity ?? this.filterEntity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }

  int get totalPages => totalCount == 0 ? 1 : (totalCount / itemsPerPage).ceil();
  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}

/// Provider for activity log state
class ActivityLogNotifier extends StateNotifier<ActivityLogState> {
  final ActivityLogService _service;

  ActivityLogNotifier(this._service) : super(ActivityLogState());

  /// Load all activity logs (admin only)
  Future<void> loadActivityLogs() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final offset = (state.currentPage - 1) * state.itemsPerPage;
      
      final logs = await _service.getAllActivityLogs(
        limit: state.itemsPerPage,
        offset: offset,
        filterAction: state.filterAction,
        filterEntity: state.filterEntity,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      final totalCount = await _service.getActivityLogCount(
        filterAction: state.filterAction,
        filterEntity: state.filterEntity,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      state = state.copyWith(
        logs: logs,
        totalCount: totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load user-specific activity logs
  Future<void> loadUserActivityLogs(int userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final offset = (state.currentPage - 1) * state.itemsPerPage;
      
      final logs = await _service.getUserActivityLogs(
        userId: userId,
        limit: state.itemsPerPage,
        offset: offset,
        filterAction: state.filterAction,
        filterEntity: state.filterEntity,
      );

      final totalCount = await _service.getActivityLogCount(
        userId: userId,
        filterAction: state.filterAction,
        filterEntity: state.filterEntity,
      );

      state = state.copyWith(
        logs: logs,
        totalCount: totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load activity statistics
  Future<void> loadStatistics({int? userId, int days = 30}) async {
    try {
      final statistics = await _service.getActivityStatistics(
        userId: userId,
        days: days,
      );

      state = state.copyWith(statistics: statistics);
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Search activity logs
  Future<void> searchLogs(String query) async {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 1,
      isLoading: true,
      error: null,
    );

    try {
      final logs = await _service.searchActivityLogs(
        searchQuery: query,
        filterAction: state.filterAction,
        filterEntity: state.filterEntity,
        startDate: state.startDate,
        endDate: state.endDate,
        limit: state.itemsPerPage,
      );

      state = state.copyWith(
        logs: logs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Set filter for action type
  void setActionFilter(ActivityAction? action) {
    state = state.copyWith(
      filterAction: action,
      currentPage: 1,
    );
    loadActivityLogs();
  }

  /// Set filter for entity type
  void setEntityFilter(EntityType? entity) {
    state = state.copyWith(
      filterEntity: entity,
      currentPage: 1,
    );
    loadActivityLogs();
  }

  /// Set date range filter
  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      currentPage: 1,
    );
    loadActivityLogs();
  }

  /// Clear all filters
  void clearFilters() {
    state = ActivityLogState(
      itemsPerPage: state.itemsPerPage,
    );
    loadActivityLogs();
  }

  /// Go to next page
  Future<void> nextPage() async {
    if (state.hasNextPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      await loadActivityLogs();
    }
  }

  /// Go to previous page
  Future<void> previousPage() async {
    if (state.hasPreviousPage) {
      state = state.copyWith(currentPage: state.currentPage - 1);
      await loadActivityLogs();
    }
  }

  /// Go to specific page
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(currentPage: page);
      await loadActivityLogs();
    }
  }

  /// Refresh current page
  Future<void> refresh() async {
    await loadActivityLogs();
  }

  /// Get entity-specific logs
  Future<List<ActivityLog>> getEntityLogs({
    required EntityType entity,
    required int entityId,
    int limit = 10,
  }) async {
    try {
      return await _service.getEntityActivityLogs(
        entity: entity,
        entityId: entityId,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting entity logs: $e');
      return [];
    }
  }
}

/// Provider for activity log notifier
final activityLogProvider =
    StateNotifierProvider<ActivityLogNotifier, ActivityLogState>((ref) {
  final service = ref.watch(activityLogServiceProvider);
  return ActivityLogNotifier(service);
});

/// Provider for recent activity (last 10)
final recentActivityProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final service = ref.watch(activityLogServiceProvider);
  return service.getRecentActivity(limit: 10);
});

/// Provider for activity statistics
final activityStatisticsProvider =
    FutureProvider.family<ActivityStatistics, ActivityStatisticsParams>(
        (ref, params) async {
  final service = ref.watch(activityLogServiceProvider);
  return service.getActivityStatistics(
    userId: params.userId,
    days: params.days,
  );
});

/// Parameters for activity statistics
class ActivityStatisticsParams {
  final int? userId;
  final int days;

  ActivityStatisticsParams({
    this.userId,
    this.days = 30,
  });
}
