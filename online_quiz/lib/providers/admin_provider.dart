import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';

/// Provider for admin service
final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

/// State class for admin dashboard data
class AdminDashboardState {
  final Map<String, int> statistics;
  final Map<String, dynamic> recentActivity;
  final Map<String, dynamic> systemHealth;
  final bool isLoading;
  final String? error;

  const AdminDashboardState({
    this.statistics = const {},
    this.recentActivity = const {},
    this.systemHealth = const {},
    this.isLoading = false,
    this.error,
  });

  AdminDashboardState copyWith({
    Map<String, int>? statistics,
    Map<String, dynamic>? recentActivity,
    Map<String, dynamic>? systemHealth,
    bool? isLoading,
    String? error,
  }) {
    return AdminDashboardState(
      statistics: statistics ?? this.statistics,
      recentActivity: recentActivity ?? this.recentActivity,
      systemHealth: systemHealth ?? this.systemHealth,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier for managing admin dashboard data
class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final AdminService _adminService;

  AdminDashboardNotifier(this._adminService) : super(const AdminDashboardState());

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _adminService.getSystemStatistics(),
        _adminService.getRecentActivity(),
        _adminService.getSystemHealth(),
      ]);

      state = state.copyWith(
        statistics: results[0] as Map<String, int>,
        recentActivity: results[1],
        systemHealth: results[2],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('Error loading dashboard data: $e');
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Load system statistics only
  Future<void> loadStatistics() async {
    try {
      final statistics = await _adminService.getSystemStatistics();
      state = state.copyWith(statistics: statistics);
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Load recent activity only
  Future<void> loadRecentActivity() async {
    try {
      final activity = await _adminService.getRecentActivity();
      state = state.copyWith(recentActivity: activity);
    } catch (e) {
      debugPrint('Error loading recent activity: $e');
    }
  }

  /// Load system health only
  Future<void> loadSystemHealth() async {
    try {
      final health = await _adminService.getSystemHealth();
      state = state.copyWith(systemHealth: health);
    } catch (e) {
      debugPrint('Error loading system health: $e');
    }
  }
}

/// Provider for admin dashboard state
final adminDashboardProvider = StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return AdminDashboardNotifier(adminService);
});
