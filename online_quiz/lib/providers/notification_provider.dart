import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart' as model;
import '../models/user.dart';
import '../services/notification_service.dart';

// Notification state class to hold all notification-related data and UI state
class NotificationState {
  final List<model.Notification> allNotifications;
  final List<model.Notification> unreadNotifications;
  final List<model.Notification> readNotifications;
  final List<model.Notification> displayedNotifications;
  final List<Map<String, dynamic>> groupedNotifications; // For admin view
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String selectedFilter; // 'All', 'Unread', 'Read', 'Quiz', 'Course', 'System', 'Reminder'
  final int displayedCount;
  final int batchSize;
  final int unreadCount;
  final Map<int, bool> notificationReadStatus; // notificationId -> isRead
  final int? currentUserId; // Track the current user ID
  final bool hasMoreToLoad;

  const NotificationState({
    this.allNotifications = const [],
    this.unreadNotifications = const [],
    this.readNotifications = const [],
    this.displayedNotifications = const [],
    this.groupedNotifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.selectedFilter = 'All',
    this.displayedCount = 0,
    this.batchSize = 20,
    this.unreadCount = 0,
    this.notificationReadStatus = const {},
    this.currentUserId,
    this.hasMoreToLoad = false,
  });

  NotificationState copyWith({
    List<model.Notification>? allNotifications,
    List<model.Notification>? unreadNotifications,
    List<model.Notification>? readNotifications,
    List<model.Notification>? displayedNotifications,
    List<Map<String, dynamic>>? groupedNotifications,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? selectedFilter,
    int? displayedCount,
    int? batchSize,
    int? unreadCount,
    Map<int, bool>? notificationReadStatus,
    int? currentUserId,
    bool? hasMoreToLoad,
    bool clearError = false,
  }) {
    return NotificationState(
      allNotifications: allNotifications ?? this.allNotifications,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      readNotifications: readNotifications ?? this.readNotifications,
      displayedNotifications: displayedNotifications ?? this.displayedNotifications,
      groupedNotifications: groupedNotifications ?? this.groupedNotifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      displayedCount: displayedCount ?? this.displayedCount,
      batchSize: batchSize ?? this.batchSize,
      unreadCount: unreadCount ?? this.unreadCount,
      notificationReadStatus: notificationReadStatus ?? this.notificationReadStatus,
      currentUserId: currentUserId ?? this.currentUserId,
      hasMoreToLoad: hasMoreToLoad ?? this.hasMoreToLoad,
    );
  }

  // Helper getters
  bool get hasUnreadNotifications => unreadCount > 0;
  bool get hasNotifications => allNotifications.isNotEmpty;
  
  // Legacy getters for backward compatibility
  List<model.Notification> get paginatedNotifications => displayedNotifications;
  List<model.Notification> get filteredNotifications {
    return _applyFilterToList(allNotifications, selectedFilter);
  }
  int get totalPages => 1; // Not used in infinite scroll
  bool get hasNextPage => hasMoreToLoad;
  bool get hasPreviousPage => false; // Not used in infinite scroll
  
  // Apply filter helper
  static List<model.Notification> _applyFilterToList(List<model.Notification> notifications, String filter) {
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
    debugPrint('[Notifications] loadNotifications() started for userId: $userId');
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Use provided userId or current userId from state
      final currentUserId = userId ?? state.currentUserId;
      if (currentUserId == null) {
        throw Exception('User ID is required to load notifications');
      }
      
      // Get all notifications for the user from Supabase
      final allNotifications = await _notificationService.getNotificationsByUser(currentUserId);
      debugPrint('[Notifications] Fetched ${allNotifications.length} total notifications from API');
      
      // Sort notifications by creation date (newest first)
      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Separate read and unread notifications
      final unreadNotifications = allNotifications.where((n) => !n.isRead).toList();
      final readNotifications = allNotifications.where((n) => n.isRead).toList();
      debugPrint('[Notifications] Unread: ${unreadNotifications.length}, Read: ${readNotifications.length}');
      
      // Create read status map
      final readStatusMap = <int, bool>{};
      for (final notification in allNotifications) {
        readStatusMap[notification.notificationId] = notification.isRead;
      }
      
      // Apply current filter and get initial batch
      final filteredNotifications = _applyFilter(allNotifications, state.selectedFilter);
      final initialBatch = filteredNotifications.take(state.batchSize).toList();
      final hasMore = filteredNotifications.length > state.batchSize;
      
      debugPrint('[Notifications] Initial batch: ${initialBatch.length}/${filteredNotifications.length} (filter: ${state.selectedFilter})');
      debugPrint('[Notifications] hasMoreToLoad: $hasMore');
      
      state = state.copyWith(
        allNotifications: allNotifications,
        unreadNotifications: unreadNotifications,
        readNotifications: readNotifications,
        displayedNotifications: initialBatch,
        unreadCount: unreadNotifications.length,
        notificationReadStatus: readStatusMap,
        isLoading: false,
        displayedCount: initialBatch.length,
        hasMoreToLoad: hasMore,
        currentUserId: currentUserId, // Track the current user ID
      );
      
      debugPrint('[Notifications] loadNotifications() completed successfully');
    } catch (e) {
      debugPrint('[Notifications] ERROR loadNotifications(): ${e.toString()}');
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
      
      // Apply current filter and get initial batch
      final filteredNotifications = _applyFilter(allNotifications, state.selectedFilter);
      final initialBatch = filteredNotifications.take(state.batchSize).toList();
      final hasMore = filteredNotifications.length > state.batchSize;
      
      state = state.copyWith(
        allNotifications: allNotifications,
        unreadNotifications: unreadNotifications,
        readNotifications: readNotifications,
        displayedNotifications: initialBatch,
        groupedNotifications: groupedNotifications,
        unreadCount: unreadNotifications.length,
        notificationReadStatus: readStatusMap,
        isLoading: false,
        displayedCount: initialBatch.length,
        hasMoreToLoad: hasMore,
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
      
      // Update displayed notifications to reflect the change
      final updatedDisplayed = state.displayedNotifications.map((n) => 
        n.notificationId == notification.notificationId ? updatedNotification : n
      ).toList();
      
      // Update state with preserved filter and displayed notifications
      state = state.copyWith(
        allNotifications: updatedAllNotifications,
        unreadNotifications: unreadNotifications,
        readNotifications: readNotifications,
        displayedNotifications: updatedDisplayed,
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
      
      // Update all notifications to mark as read
      final updatedAllNotifications = state.allNotifications.map((n) {
        if (unreadIds.contains(n.notificationId)) {
          return n.markAsRead();
        }
        return n;
      }).toList();
      
      // Update displayed notifications
      final updatedDisplayed = state.displayedNotifications.map((n) {
        if (unreadIds.contains(n.notificationId)) {
          return n.markAsRead();
        }
        return n;
      }).toList();
      
      // Update read status map
      final updatedReadStatusMap = Map<int, bool>.from(state.notificationReadStatus);
      for (final id in unreadIds) {
        updatedReadStatusMap[id] = true;
      }
      
      // Update state
      state = state.copyWith(
        allNotifications: updatedAllNotifications,
        unreadNotifications: [],
        readNotifications: updatedAllNotifications,
        displayedNotifications: updatedDisplayed,
        unreadCount: 0,
        notificationReadStatus: updatedReadStatusMap,
      );
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

  // Load more notifications (for infinite scroll)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMoreToLoad) {
      debugPrint('[Notifications] loadMore() blocked - isLoadingMore: ${state.isLoadingMore}, hasMoreToLoad: ${state.hasMoreToLoad}');
      return;
    }
    
    debugPrint('[Notifications] loadMore() started - Current displayed: ${state.displayedCount}');
    state = state.copyWith(isLoadingMore: true);
    
    try {
      // Simulate a small delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Get filtered notifications
      final filteredNotifications = _applyFilter(state.allNotifications, state.selectedFilter);
      debugPrint('[Notifications] Total filtered notifications: ${filteredNotifications.length}');
      
      // Calculate next batch
      final currentCount = state.displayedCount;
      final nextBatch = filteredNotifications
          .skip(currentCount)
          .take(state.batchSize)
          .toList();
      
      debugPrint('[Notifications] Loading batch: ${nextBatch.length} items (from index $currentCount)');
      
      // Combine with existing displayed notifications
      final updatedDisplayed = [...state.displayedNotifications, ...nextBatch];
      final hasMore = updatedDisplayed.length < filteredNotifications.length;
      
      debugPrint('[Notifications] loadMore() completed - Now displaying: ${updatedDisplayed.length}/${filteredNotifications.length}, hasMore: $hasMore');
      
      state = state.copyWith(
        displayedNotifications: updatedDisplayed,
        displayedCount: updatedDisplayed.length,
        hasMoreToLoad: hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      debugPrint('[Notifications] ERROR loadMore(): ${e.toString()}');
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more notifications: ${e.toString()}',
      );
    }
  }

  // Set filter for notifications
  void setFilter(String filter) {
    debugPrint('[Notifications] setFilter() called - New filter: $filter');
    final filteredNotifications = _applyFilter(state.allNotifications, filter);
    final initialBatch = filteredNotifications.take(state.batchSize).toList();
    final hasMore = filteredNotifications.length > state.batchSize;
    
    debugPrint('[Notifications] Filter applied - Showing ${initialBatch.length}/${filteredNotifications.length}, hasMore: $hasMore');
    
    state = state.copyWith(
      selectedFilter: filter,
      displayedNotifications: initialBatch,
      displayedCount: initialBatch.length,
      hasMoreToLoad: hasMore,
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

  // Refresh notifications
  Future<void> refresh() async {
    if (state.currentUserId != null) {
      await loadNotifications(userId: state.currentUserId);
    } else {
      await loadAllNotifications();
    }
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