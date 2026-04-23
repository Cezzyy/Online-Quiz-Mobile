import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification.dart' as model;
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/empty_state_widget.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint('[NotificationScreen] Initialized');
    
    // Load notifications when screen initializes
    Future.microtask(() {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        debugPrint('[NotificationScreen] Loading notifications for user: ${currentUser.userId}');
        ref.read(notificationNotifierProvider.notifier).loadNotifications(userId: currentUser.userId);
      } else {
        debugPrint('[NotificationScreen] WARNING: No current user found');
      }
    });
    
    // Add scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
    debugPrint('[NotificationScreen] Scroll listener attached');
  }

  @override
  void dispose() {
    debugPrint('[NotificationScreen] Disposing');
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    
    // Only log when getting close to bottom
    if (distanceFromBottom < 500) {
      debugPrint('[NotificationScreen] Scroll position: ${position.pixels.toStringAsFixed(0)}/${position.maxScrollExtent.toStringAsFixed(0)} (${distanceFromBottom.toStringAsFixed(0)}px from bottom)');
    }
    
    if (distanceFromBottom <= 200) {
      debugPrint('[NotificationScreen] Trigger threshold reached - Calling loadMore()');
      ref.read(notificationNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationNotifierProvider);
    final unreadNotifications = ref.watch(unreadNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          if (unreadNotifications.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(notificationNotifierProvider.notifier).markAllAsRead(),
              child: Text(
                'Mark all read',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: notificationState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notifications',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notificationState.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final currentUser = ref.read(currentUserProvider);
                          if (currentUser != null) {
                            ref.read(notificationNotifierProvider.notifier).loadNotifications(userId: currentUser.userId);
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : notificationState.displayedNotifications.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.notifications_none,
                      title: 'No notifications',
                      message: 'You\'ll see notifications here when you have them.',
                    )
                  : _buildNotificationsList(notificationState),
    );
  }

  Widget _buildNotificationCard(model.Notification notification) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationNotifierProvider.notifier).markAsRead(notification);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? AppTheme.getCardColor(context)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: notification.isRead 
                ? AppTheme.getDividerColor(context)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification.type),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: notification.isRead 
                                ? FontWeight.w500 
                                : FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 11,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(notification.type).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTypeLabel(notification.type),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getTypeColor(notification.type),
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(model.NotificationType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case model.NotificationType.quiz:
        iconData = Icons.quiz_outlined;
        iconColor = AppTheme.getQuizTypeColor('quiz');
        break;
      case model.NotificationType.course:
        iconData = Icons.school_outlined;
        iconColor = AppTheme.getQuizTypeColor('course');
        break;
      case model.NotificationType.reminder:
        iconData = Icons.notifications_outlined;
        iconColor = AppTheme.getQuizTypeColor('reminder');
        break;
      case model.NotificationType.system:
        iconData = Icons.info_outline;
        iconColor = AppTheme.getQuizTypeColor('system');
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        iconData,
        size: 16,
        color: iconColor,
      ),
    );
  }

  Color _getTypeColor(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.quiz:
        return AppTheme.getQuizTypeColor('quiz');
      case model.NotificationType.course:
        return AppTheme.getQuizTypeColor('course');
      case model.NotificationType.reminder:
        return AppTheme.getQuizTypeColor('reminder');
      case model.NotificationType.system:
        return AppTheme.getQuizTypeColor('system');
    }
  }

  String _getTypeLabel(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.quiz:
        return 'QUIZ';
      case model.NotificationType.course:
        return 'COURSE';
      case model.NotificationType.reminder:
        return 'REMINDER';
      case model.NotificationType.system:
        return 'SYSTEM';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildNotificationsList(NotificationState state) {
    // Separate unread and read from displayed notifications
    final displayedUnread = state.displayedNotifications.where((n) => !n.isRead).toList();
    final displayedRead = state.displayedNotifications.where((n) => n.isRead).toList();
    
    return RefreshIndicator(
      onRefresh: () async {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          await ref.read(notificationNotifierProvider.notifier).loadNotifications(userId: currentUser.userId);
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _calculateItemCount(displayedUnread, displayedRead, state),
        itemBuilder: (context, index) {
          return _buildListItem(index, displayedUnread, displayedRead, state);
        },
      ),
    );
  }

  int _calculateItemCount(List<model.Notification> unread, List<model.Notification> read, NotificationState state) {
    int count = 0;
    
    // Unread section
    if (unread.isNotEmpty) {
      count += 1; // Header
      count += unread.length; // Notifications
    }
    
    // Read section
    if (read.isNotEmpty) {
      count += 1; // Header
      count += read.length; // Notifications
    }
    
    // Loading indicator
    if (state.isLoadingMore) {
      count += 1;
    }
    
    return count;
  }

  Widget _buildListItem(int index, List<model.Notification> unread, List<model.Notification> read, NotificationState state) {
    int currentIndex = index;
    
    // Unread section
    if (unread.isNotEmpty) {
      if (currentIndex == 0) {
        return _buildSectionHeader('Unread', true);
      }
      currentIndex--;
      
      if (currentIndex < unread.length) {
        return _buildNotificationCard(unread[currentIndex]);
      }
      currentIndex -= unread.length;
    }
    
    // Read section
    if (read.isNotEmpty) {
      if (currentIndex == 0) {
        return _buildSectionHeader('Read', false);
      }
      currentIndex--;
      
      if (currentIndex < read.length) {
        return _buildNotificationCard(read[currentIndex]);
      }
      currentIndex -= read.length;
    }
    
    // Loading indicator
    if (state.isLoadingMore) {
      return _buildLoadingIndicator();
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String title, bool isUnread) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          if (isUnread)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            )
          else
            Icon(
              Icons.check_circle_outline,
              color: AppTheme.getSecondaryTextColor(context),
              size: 12,
            ),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isUnread
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.getSecondaryTextColor(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}