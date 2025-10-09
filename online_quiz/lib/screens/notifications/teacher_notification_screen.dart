import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification.dart' as model;
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/empty_state_widget.dart';

class TeacherNotificationScreen extends ConsumerStatefulWidget {
  const TeacherNotificationScreen({super.key});

  @override
  ConsumerState<TeacherNotificationScreen> createState() => _TeacherNotificationScreenState();
}

class _TeacherNotificationScreenState extends ConsumerState<TeacherNotificationScreen> {
  final int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    // Load notifications when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Notifications'),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(notificationNotifierProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          _buildFilterTabs(notificationState),
          
          // Notifications list
          Expanded(
            child: _buildNotificationsList(notificationState),
          ),
          
          // Pagination
          if (notificationState.totalPages > 1)
            _buildPagination(notificationState),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(NotificationState state) {
    final filters = ['All', 'Unread', 'Quiz Submissions', 'Course Updates', 'System', 'Reminders'];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = state.selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(notificationNotifierProvider.notifier).setFilter(filter);
                }
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList(NotificationState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return EmptyStatePresets.error(
        title: 'Failed to Load Notifications',
        message: state.error!,
        onRetry: () {
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            ref.read(notificationNotifierProvider.notifier).loadNotifications(userId: currentUser.userId);
          }
        },
      );
    }

    if (state.filteredNotifications.isEmpty) {
      return _buildEmptyState(state.selectedFilter);
    }

      return RefreshIndicator(
        onRefresh: () async {
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            await ref.read(notificationNotifierProvider.notifier).loadNotifications(userId: currentUser.userId);
          }
        },
        child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.paginatedNotifications.length,
        itemBuilder: (context, index) {
          final notification = state.paginatedNotifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    switch (filter) {
      case 'Unread':
        return EmptyStatePresets.notifications();
      case 'Quiz Submissions':
        return const EmptyStateWidget(
          icon: Icons.quiz_outlined,
          title: 'No Quiz Submissions',
          message: 'No quiz submissions to review at the moment.',
          subtitle: 'Student submissions will appear here when they complete quizzes.',
        );
      case 'Course Updates':
        return const EmptyStateWidget(
          icon: Icons.class_outlined,
          title: 'No Course Updates',
          message: 'No course-related notifications at the moment.',
          subtitle: 'Course enrollment and updates will appear here.',
        );
      case 'System':
        return const EmptyStateWidget(
          icon: Icons.settings_outlined,
          title: 'No System Notifications',
          message: 'No system notifications at the moment.',
          subtitle: 'System updates and maintenance notices will appear here.',
        );
      case 'Reminders':
        return const EmptyStateWidget(
          icon: Icons.schedule_outlined,
          title: 'No Reminders',
          message: 'No reminders at the moment.',
          subtitle: 'Quiz deadlines and important reminders will appear here.',
        );
      default:
        return EmptyStatePresets.notifications();
    }
  }

  Widget _buildNotificationCard(model.Notification notification) {
    final isRead = notification.isRead;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead 
          ? BorderSide.none 
          : BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and read status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Message
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Timestamp and type
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getNotificationTypeLabel(notification.type),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getNotificationColor(notification.type),
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildPagination(NotificationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous page button
          ElevatedButton.icon(
            onPressed: state.hasPreviousPage 
              ? () => ref.read(notificationNotifierProvider.notifier).previousPage()
              : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          
          // Page indicator
          Text(
            'Page ${state.currentPage + 1} of ${state.totalPages}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Next page button
          ElevatedButton.icon(
            onPressed: state.hasNextPage 
              ? () => ref.read(notificationNotifierProvider.notifier).nextPage()
              : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(model.Notification notification) {
    if (!notification.isRead) {
      ref.read(notificationNotifierProvider.notifier).markAsRead(notification);
    }
    
    // Show notification details in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.quiz:
        return Icons.quiz_outlined;
      case model.NotificationType.course:
        return Icons.class_outlined;
      case model.NotificationType.system:
        return Icons.settings_outlined;
      case model.NotificationType.reminder:
        return Icons.schedule_outlined;
    }
  }

  Color _getNotificationColor(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.quiz:
        return AppTheme.getQuizTypeColor('quiz');
      case model.NotificationType.course:
        return AppTheme.getQuizTypeColor('course');
      case model.NotificationType.system:
        return AppTheme.getQuizTypeColor('system');
      case model.NotificationType.reminder:
        return AppTheme.getQuizTypeColor('reminder');
    }
  }

  String _getNotificationTypeLabel(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.quiz:
        return 'Quiz';
      case model.NotificationType.course:
        return 'Course';
      case model.NotificationType.system:
        return 'System';
      case model.NotificationType.reminder:
        return 'Reminder';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
