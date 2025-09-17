import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/notification.dart' as model;
import '../../widgets/empty_state_widget.dart';
import '../../utils/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<model.Notification> unreadNotifications = [];
  List<model.Notification> readNotifications = [];
  int currentPage = 0;
  final int itemsPerPage = 5;
  final int currentUserId = 4; // Jan Rosalijos - student user

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final allNotifications = MockData.getNotificationsByUser(currentUserId);
    unreadNotifications = allNotifications.where((n) => !n.isRead).toList();
    readNotifications = allNotifications.where((n) => n.isRead).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: (unreadNotifications.isEmpty && readNotifications.isEmpty)
          ? _buildEmptyState()
          : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStatePresets.notifications();
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
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(12),
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
                            style: TextStyle(
                              fontSize: 16,
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          style: TextStyle(
                            fontSize: 12,
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
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _getTypeColor(notification.type),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  void _markAsRead(model.Notification notification) {
    if (!notification.isRead) {
      setState(() {
        unreadNotifications.removeWhere((n) => n.notificationId == notification.notificationId);
        readNotifications.insert(0, notification.copyWith(isRead: true));
      });
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in unreadNotifications) {
        readNotifications.insert(0, notification.copyWith(isRead: true));
      }
      unreadNotifications.clear();
      currentPage = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildNotificationsList() {
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
                ..._getPaginatedReadNotifications().map((notification) => 
                  _buildNotificationCard(notification)),
              ],
            ],
          ),
        ),
        // Pagination controls for read notifications
        if (readNotifications.length > itemsPerPage) _buildPaginationControls(),
      ],
    );
  }

  List<model.Notification> _getPaginatedReadNotifications() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, readNotifications.length);
    return readNotifications.sublist(startIndex, endIndex);
  }

  Widget _buildPaginationControls() {
    final totalPages = (readNotifications.length / itemsPerPage).ceil();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 0 ? () {
              setState(() {
                currentPage--;
              });
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
              '${currentPage + 1} / $totalPages',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          IconButton(
            onPressed: currentPage < totalPages - 1 ? () {
              setState(() {
                currentPage++;
              });
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