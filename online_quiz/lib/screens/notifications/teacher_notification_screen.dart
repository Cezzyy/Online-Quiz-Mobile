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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint('[TeacherNotificationScreen] Initialized');
    
    // Load notifications when screen initializes
    Future.microtask(() {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        debugPrint('[TeacherNotificationScreen] Loading notifications for user: ${currentUser.userId}');
        ref.read(notificationNotifierProvider.notifier).loadNotifications(userId: currentUser.userId);
      } else {
        debugPrint('[TeacherNotificationScreen] WARNING: No current user found');
      }
    });
    
    // Add scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
    debugPrint('[TeacherNotificationScreen] Scroll listener attached');
  }

  @override
  void dispose() {
    debugPrint('[TeacherNotificationScreen] Disposing');
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    
    // Only log when getting close to bottom
    if (distanceFromBottom < 500) {
      debugPrint('[TeacherNotificationScreen] Scroll position: ${position.pixels.toStringAsFixed(0)}/${position.maxScrollExtent.toStringAsFixed(0)} (${distanceFromBottom.toStringAsFixed(0)}px from bottom)');
    }
    
    if (distanceFromBottom <= 200) {
      debugPrint('[TeacherNotificationScreen] Trigger threshold reached - Calling loadMore()');
      ref.read(notificationNotifierProvider.notifier).loadMore();
    }
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
        ],
      ),
    );
  }

  Widget _buildFilterTabs(NotificationState state) {
    final filters = ['All', 'Unread', 'Quiz Submissions', 'Course Updates', 'System', 'Reminders'];
    
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.getDividerColor(context),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = state.selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(notificationNotifierProvider.notifier).setFilter(filter);
                }
              },
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              labelPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                    : AppTheme.getDividerColor(context),
                width: 1,
              ),
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : AppTheme.getTextColor(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
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

    if (state.displayedNotifications.isEmpty) {
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
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: state.displayedNotifications.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.displayedNotifications.length) {
            final notification = state.displayedNotifications[index];
            return _buildNotificationCard(notification);
          } else {
            // Loading indicator at the bottom
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
    
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead 
              ? AppTheme.getCardColor(context)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRead 
                ? AppTheme.getDividerColor(context)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            
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
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead) ...[
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
                  
                  // Message
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
                  
                  // Timestamp and type
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(notification.type).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getNotificationTypeLabel(notification.type),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getNotificationColor(notification.type),
                            fontWeight: FontWeight.w600,
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
