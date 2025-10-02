import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart' as model;
import '../data/mock_data.dart';

// Notification state class to hold all notification-related data and UI state
class NotificationState {
  final List<model.Notification> allNotifications;
  final List<model.Notification> unreadNotifications;
  final List<model.Notification> readNotifications;
  final List<model.Notification> filteredNotifications;
  final bool isLoading;
  final String? error;
  final String selectedFilter; // 'All', 'Unread', 'Read', 'Quiz', 'Course', 'System', 'Reminder'
  final int currentPage;
  final int itemsPerPage;
  final int unreadCount;
  final Map<int, bool> notificationReadStatus; // notificationId -> isRead

  const NotificationState({
    this.allNotifications = const [],
    this.unreadNotifications = const [],
    this.readNotifications = const [],
    this.filteredNotifications = const [],
    this.isLoading = false,
    this.error,
    this.selectedFilter = 'All',
    this.currentPage = 0,
    this.itemsPerPage = 10,
    this.unreadCount = 0,
    this.notificationReadStatus = const {},
  });

  NotificationState copyWith({
    List<model.Notification>? allNotifications,
    List<model.Notification>? unreadNotifications,
    List<model.Notification>? readNotifications,
    List<model.Notification>? filteredNotifications,
    bool? isLoading,
    String? error,
    String? selectedFilter,
    int? currentPage,
    int? itemsPerPage,
    int? unreadCount,
    Map<int, bool>? notificationReadStatus,
    bool clearError = false,
  }) {
    return NotificationState(
      allNotifications: allNotifications ?? this.allNotifications,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      readNotifications: readNotifications ?? this.readNotifications,
      filteredNotifications: filteredNotifications ?? this.filteredNotifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      unreadCount: unreadCount ?? this.unreadCount,
      notificationReadStatus: notificationReadStatus ?? this.notificationReadStatus,
    );
  }

  // Helper getters
  bool get hasUnreadNotifications => unreadCount > 0;
  bool get hasNotifications => allNotifications.isNotEmpty;
  List<model.Notification> get paginatedNotifications {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredNotifications.length);
    return filteredNotifications.sublist(startIndex, endIndex);
  }
  int get totalPages => (filteredNotifications.length / itemsPerPage).ceil();
  bool get hasNextPage => currentPage < totalPages - 1;
  bool get hasPreviousPage => currentPage > 0;
}

// Notification notifier class
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    loadNotifications();
  }

  // Load notifications for the current user
  Future<void> loadNotifications({int? userId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Use current user ID (4 for Jan Rosalijos - student user)
      final currentUserId = userId ?? 4;
      
      // Get all notifications for the user
      final allNotifications = MockData.getNotificationsByUser(currentUserId);
      
      // Sort notifications by creation date (newest first)
      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Separate read and unread notifications
      final unreadNotifications = allNotifications.where((n) => !n.isRead).toList();
      final readNotifications = allNotifications.where((n) => n.isRead).toList();
      
      // Create read status map
      final readStatusMap = <int, bool>{};
      for (final notification in allNotifications) {
        readStatusMap[notification.notificationId] = notification.isRead;
      }
      
      // Apply current filter
      final filteredNotifications = _applyFilter(allNotifications, state.selectedFilter);
      
      state = state.copyWith(
        allNotifications: allNotifications,
        unreadNotifications: unreadNotifications,
        readNotifications: readNotifications,
        filteredNotifications: filteredNotifications,
        unreadCount: unreadNotifications.length,
        notificationReadStatus: readStatusMap,
        isLoading: false,
        currentPage: 0, // Reset to first page when loading
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: ${e.toString()}',
      );
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(model.Notification notification) async {
    if (notification.isRead) return; // Already read
    
    try {
      // Update the notification in mock data
      final index = MockData.notifications.indexWhere((n) => n.notificationId == notification.notificationId);
      if (index != -1) {
        MockData.notifications[index] = notification.markAsRead();
      }
      
      // Reload notifications to reflect changes
      await loadNotifications();
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark notification as read: ${e.toString()}');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      // Update all unread notifications for the current user
      for (int i = 0; i < MockData.notifications.length; i++) {
        final notification = MockData.notifications[i];
        if (notification.userId == 4 && !notification.isRead) {
          MockData.notifications[i] = notification.markAsRead();
        }
      }
      
      // Reload notifications to reflect changes
      await loadNotifications();
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark all notifications as read: ${e.toString()}');
    }
  }

  // Set filter for notifications
  void setFilter(String filter) {
    final filteredNotifications = _applyFilter(state.allNotifications, filter);
    state = state.copyWith(
      selectedFilter: filter,
      filteredNotifications: filteredNotifications,
      currentPage: 0, // Reset to first page when filtering
    );
  }

  // Apply filter to notifications
  List<model.Notification> _applyFilter(List<model.Notification> notifications, String filter) {
    switch (filter) {
      case 'Unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'Read':
        return notifications.where((n) => n.isRead).toList();
      case 'Quiz':
        return notifications.where((n) => n.type == model.NotificationType.quiz).toList();
      case 'Course':
        return notifications.where((n) => n.type == model.NotificationType.course).toList();
      case 'System':
        return notifications.where((n) => n.type == model.NotificationType.system).toList();
      case 'Reminder':
        return notifications.where((n) => n.type == model.NotificationType.reminder).toList();
      case 'All':
      default:
        return notifications;
    }
  }

  // Set current page for pagination
  void setPage(int page) {
    if (page >= 0 && page < state.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  // Go to next page
  void nextPage() {
    if (state.hasNextPage) {
      setPage(state.currentPage + 1);
    }
  }

  // Go to previous page
  void previousPage() {
    if (state.hasPreviousPage) {
      setPage(state.currentPage - 1);
    }
  }

  // Set items per page
  void setItemsPerPage(int itemsPerPage) {
    state = state.copyWith(
      itemsPerPage: itemsPerPage,
      currentPage: 0, // Reset to first page
    );
  }

  // Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Get notifications by type
  List<model.Notification> getNotificationsByType(model.NotificationType type) {
    return state.allNotifications.where((n) => n.type == type).toList();
  }

  // Get recent notifications (last 7 days)
  List<model.Notification> getRecentNotifications() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return state.allNotifications.where((n) => n.createdAt.isAfter(sevenDaysAgo)).toList();
  }

  // Search notifications
  List<model.Notification> searchNotifications(String query) {
    if (query.isEmpty) return state.allNotifications;
    
    final lowercaseQuery = query.toLowerCase();
    return state.allNotifications.where((n) =>
      n.title.toLowerCase().contains(lowercaseQuery) ||
      n.message.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
}

// Provider instances
final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

// Computed providers for specific notification data
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(notificationNotifierProvider);
  return notificationState.unreadCount;
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final unreadCount = ref.watch(unreadNotificationCountProvider);
  return unreadCount > 0;
});

final unreadNotificationsProvider = Provider<List<model.Notification>>((ref) {
  final notificationState = ref.watch(notificationNotifierProvider);
  return notificationState.unreadNotifications;
});

final readNotificationsProvider = Provider<List<model.Notification>>((ref) {
  final notificationState = ref.watch(notificationNotifierProvider);
  return notificationState.readNotifications;
});

final recentNotificationsProvider = Provider<List<model.Notification>>((ref) {
  final notificationState = ref.watch(notificationNotifierProvider);
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  return notificationState.allNotifications.where((n) => n.createdAt.isAfter(sevenDaysAgo)).toList();
});