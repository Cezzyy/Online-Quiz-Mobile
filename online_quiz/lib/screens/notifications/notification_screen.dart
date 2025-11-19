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
  final int itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    // Load notifications when screen initializes
    Future.microtask(() {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.read(notificationNotifierProvider.notifier).loadNotifications(userId: currentUser.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationNotifierProvider);
    final unreadNotifications = ref.watch(unreadNotificationsProvider);
    final readNotifications = ref.watch(readNotificationsProvider);

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
              : unreadNotifications.isEmpty && readNotifications.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.notifications_none,
                      title: 'No notifications',
                      message: 'You\'ll see notifications here when you have them.',
                    )
                  : _buildNotificationsList(unreadNotifications, readNotifications),
    );
  }

  Widget _buildNotificationCard(model.Notification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: notification.isRead 
                                ? FontWeight.w500 
                                : FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                             color: Theme.of(context).colorScheme.primary,
                             shape: BoxShape.circle,
                           ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      if (notification.type != model.NotificationType.system) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTypeLabel(notification.type),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: _getTypeColor(notification.type),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (!notification.isRead)
                        TextButton(
                          onPressed: () => ref.read(notificationNotifierProvider.notifier).markAsRead(notification),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Mark as Read',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
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
        iconData = Icons.quiz;
        iconColor = AppTheme.getQuizTypeColor('quiz');
        break;
      case model.NotificationType.course:
        iconData = Icons.grade;
        iconColor = AppTheme.getQuizTypeColor('course');
        break;
      case model.NotificationType.reminder:
        iconData = Icons.alarm;
        iconColor = AppTheme.getQuizTypeColor('reminder');
        break;
      case model.NotificationType.system:
        iconData = Icons.campaign;
        iconColor = AppTheme.getQuizTypeColor('system');
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 20,
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

  Widget _buildNotificationsList(List<model.Notification> unreadNotifications, List<model.Notification> readNotifications) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Unread notifications section
              if (unreadNotifications.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Theme.of(context).colorScheme.primary, size: 8),
                      const SizedBox(width: 8),
                      Text(
                        'Unread',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                ...unreadNotifications.map((notification) => 
                  _buildNotificationCard(notification)),
                const SizedBox(height: 24),
              ],
              // Read notifications section
              if (readNotifications.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Read',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._getPaginatedReadNotifications(readNotifications).map((notification) => 
                  _buildNotificationCard(notification)),
              ],
            ],
          ),
        ),
        // Pagination controls for read notifications
        if (readNotifications.length > itemsPerPage) _buildPaginationControls(readNotifications),
      ],
    );
  }

  List<model.Notification> _getPaginatedReadNotifications(List<model.Notification> readNotifications) {
    final notificationState = ref.read(notificationNotifierProvider);
    final startIndex = notificationState.currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, readNotifications.length);
    return readNotifications.sublist(startIndex, endIndex);
  }

  Widget _buildPaginationControls(List<model.Notification> readNotifications) {
    final notificationState = ref.watch(notificationNotifierProvider);
    final totalPages = (readNotifications.length / itemsPerPage).ceil();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: notificationState.currentPage > 0 ? () {
              ref.read(notificationNotifierProvider.notifier).setPage(notificationState.currentPage - 1);
            } : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${notificationState.currentPage + 1} / $totalPages',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          IconButton(
            onPressed: notificationState.currentPage < totalPages - 1 ? () {
              ref.read(notificationNotifierProvider.notifier).setPage(notificationState.currentPage + 1);
            } : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}