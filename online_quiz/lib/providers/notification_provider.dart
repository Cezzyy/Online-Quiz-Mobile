import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart' as model;
import '../models/user.dart';
import '../services/notification_service.dart';

// Notification state class to hold all notification-related data and UI state
class NotificationState {
  final List<model.Notification> allNotifications;
  final List<model.Notification> unreadNotifications;
  final List<model.Notification> readNotifications;
  final List<model.Notification> filteredNotifications;
  final List<Map<String, dynamic>> groupedNotifications; // For admin view
  final bool isLoading;
  final String? error;
  final String selectedFilter; // 'All', 'Unread', 'Read', 'Quiz', 'Course', 'System', 'Reminder'
  final int currentPage;
  final int itemsPerPage;
  final int unreadCount;
  final Map<int, bool> notificationReadStatus; // notificationId -> isRead
  final int? currentUserId; // Track the current user ID

  const NotificationState({
    this.allNotifications = const [],
    this.unreadNotifications = const [],
    this.readNotifications = const [],
    this.filteredNotifications = const [],
    this.groupedNotifications = const [],
    this.isLoading = false,
    this.error,
    this.selectedFilter = 'All',
    this.currentPage = 0,
    this.itemsPerPage = 10,
    this.unreadCount = 0,
    this.notificationReadStatus = const {},
    this.currentUserId,
  });

  NotificationState copyWith({
    List<model.Notification>? allNotifications,
    List<model.Notification>? unreadNotifications,
    List<model.Notification>? readNotifications,
    List<model.Notification>? filteredNotifications,
    List<Map<String, dynamic>>? groupedNotifications,
    bool? isLoading,
    String? error,
    String? selectedFilter,
    int? currentPage,
    int? itemsPerPage,
    int? unreadCount,
    Map<int, bool>? notificationReadStatus,
    int? currentUserId,
    bool clearError = false,
  }) {
    return NotificationState(
      allNotifications: allNotifications ?? this.allNotifications,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      readNotifications: readNotifications ?? this.readNotifications,
      filteredNotifications: filteredNotifications ?? this.filteredNotifications,
      groupedNotifications: groupedNotifications ?? this.groupedNotifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      unreadCount: unreadCount ?? this.unreadCount,
      notificationReadStatus: notificationReadStatus ?? this.notificationReadStatus,
      currentUserId: currentUserId ?? this.currentUserId,
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

// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Notification notifier class
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationNotifier(this._notificationService) : super(const NotificationState()) {
    // Don't auto-load notifications - let each screen load appropriate notifications
    // This prevents interference between admin view (all notifications) and user view (user-specific)
  }

  // Load notifications for the current user
  Future<void> loadNotifications({int? userId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Use provided userId or current userId from state
      final currentUserId = userId ?? state.currentUserId;
      if (currentUserId == null) {
        throw Exception('User ID is required to load notifications');
      }
      
      // Get all notifications for the user from Supabase
      final allNotifications = await _notificationService.getNotificationsByUser(currentUserId);
      
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
        currentUserId: currentUserId, // Track the current user ID
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: ${e.toString()}',
      );
    }
  }

  // Load all notifications (for admin view)
  Future<void> loadAllNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Get grouped notifications from Supabase (combines bulk notifications)
      final groupedNotifications = await _notificationService.getGroupedNotifications();
      
      // Get all notifications from Supabase
      final allNotifications = await _notificationService.getAllNotifications();
      
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
        groupedNotifications: groupedNotifications,
        unreadCount: unreadNotifications.length,
        notificationReadStatus: readStatusMap,
        isLoading: false,
        currentPage: 0, // Reset to first page when loading
        currentUserId: null, // Clear current user ID for admin view
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
      // Update the notification in Supabase
      await _notificationService.markNotificationAsRead(notification.notificationId);
      
      // Update the state efficiently without full reload
      final updatedNotification = notification.markAsRead();
      
      // Update all notification lists
      final updatedAllNotifications = state.allNotifications.map((n) => 
        n.notificationId == notification.notificationId ? updatedNotification : n
      ).toList();
      
      // Separate read and unread notifications
      final unreadNotifications = updatedAllNotifications.where((n) => !n.isRead).toList();
      final readNotifications = updatedAllNotifications.where((n) => n.isRead).toList();
      
      // Update read status map
      final updatedReadStatusMap = Map<int, bool>.from(state.notificationReadStatus);
      updatedReadStatusMap[notification.notificationId] = true;
      
      // Apply current filter to updated notifications
      final filteredNotifications = _applyFilter(updatedAllNotifications, state.selectedFilter);
      
      // Update state with preserved filter and pagination
      state = state.copyWith(
        allNotifications: updatedAllNotifications,
        unreadNotifications: unreadNotifications,
        readNotifications: readNotifications,
        filteredNotifications: filteredNotifications,
        unreadCount: unreadNotifications.length,
        notificationReadStatus: updatedReadStatusMap,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark notification as read: ${e.toString()}');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final unreadIds = state.unreadNotifications
          .map((n) => n.notificationId)
          .toList();
      
      if (unreadIds.isEmpty) return;
      
      // Mark all as read in Supabase
      await _notificationService.bulkMarkAsRead(unreadIds);
      
      // Reload notifications to reflect changes
      if (state.currentUserId == null) {
        // Admin view - reload all notifications
        state = state.copyWith(selectedFilter: 'All');
        await loadAllNotifications();
      } else {
        // User view - reload user-specific notifications
        await loadNotifications(userId: state.currentUserId);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark all notifications as read: ${e.toString()}');
    }
  }
  
  // Create a new notification (admin only)
  Future<void> createNotification({
    int? userId, // Nullable - if null, create broadcast notification
    required model.NotificationType type,
    required String title,
    required String message,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      if (userId == null) {
        // Broadcast to all users - get all user IDs
        final allUsers = await _notificationService.getAllUsers();
        final userIds = allUsers.map((u) => u.userId).toList();
        
        await _notificationService.createBulkNotifications(
          userIds: userIds,
          type: type,
          title: title,
          message: message,
        );
      } else {
        // Single user notification
        await _notificationService.createNotification(
          userId: userId,
          type: type,
          title: title,
          message: message,
        );
      }
      
      // Reload notifications
      await loadAllNotifications();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create notification: ${e.toString()}',
      );
    }
  }
  
  // Create bulk notifications (admin only)
  Future<void> createBulkNotifications({
    required List<int> userIds,
    required model.NotificationType type,
    required String title,
    required String message,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await _notificationService.createBulkNotifications(
        userIds: userIds,
        type: type,
        title: title,
        message: message,
      );
      
      // Reload notifications
      await loadAllNotifications();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create bulk notifications: ${e.toString()}',
      );
    }
  }
  
  // Update notification (admin only)
  Future<void> updateNotification({
    required int notificationId,
    String? title,
    String? message,
    model.NotificationType? type,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await _notificationService.updateNotification(
        notificationId: notificationId,
        title: title,
        message: message,
        type: type,
      );
      
      // Reload notifications
      await loadAllNotifications();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update notification: ${e.toString()}',
      );
    }
  }
  
  // Delete notification (admin only)
  Future<void> deleteNotification(int notificationId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Reload notifications
      await loadAllNotifications();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete notification: ${e.toString()}',
      );
    }
  }
  
  // Delete multiple notifications (admin only)
  Future<void> deleteBulkNotifications(List<int> notificationIds) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await _notificationService.deleteBulkNotifications(notificationIds);
      
      // Reload notifications
      await loadAllNotifications();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete notifications: ${e.toString()}',
      );
    }
  }
  
  // Get all users for notification targeting
  Future<List<User>> getAllUsers() async {
    try {
      final users = await _notificationService.getAllUsers();
      return users;
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch users: ${e.toString()}');
      return [];
    }
  }
  
  // Get users by role for targeted notifications
  Future<List<User>> getUsersByRole(int roleId) async {
    try {
      final users = await _notificationService.getUsersByRole(roleId);
      return users;
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch users by role: ${e.toString()}');
      return [];
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
      case 'Quiz Submissions':
        return notifications.where((n) => n.type == model.NotificationType.quiz).toList();
      case 'Course':
      case 'Course Updates':
        return notifications.where((n) => n.type == model.NotificationType.course).toList();
      case 'System':
        return notifications.where((n) => n.type == model.NotificationType.system).toList();
      case 'Reminder':
      case 'Reminders':
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
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationNotifier(notificationService);
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