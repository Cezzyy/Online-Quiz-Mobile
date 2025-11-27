import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../models/notification.dart' as model;
import '../../providers/notification_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty_state_widget.dart';

class AdminNotificationsTab extends ConsumerStatefulWidget {
  const AdminNotificationsTab({super.key});

  @override
  ConsumerState<AdminNotificationsTab> createState() =>
      _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends ConsumerState<AdminNotificationsTab> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications when the tab is first loaded
    Future.microtask(() {
      ref
          .read(notificationNotifierProvider.notifier)
          .loadAllNotifications(); // Load all notifications for admin
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationNotifierProvider);
    final notificationNotifier = ref.read(
      notificationNotifierProvider.notifier,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(context, notificationState, notificationNotifier),

            // Content Section
            Expanded(
              child: notificationState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(
                      context,
                      notificationState,
                      notificationNotifier,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          right: 16,
          bottom: notificationState.totalPages > 1
              ? 120
              : 16, // Dynamic padding based on pagination
        ),
        child: FloatingActionButton(
          heroTag: 'admin_notifications_fab',
          onPressed: () =>
              _showCreateNotificationDialog(context, notificationNotifier),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(
    BuildContext context,
    NotificationState state,
    NotificationNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Total',
                  state.allNotifications.length.toString(),
                  Icons.notifications,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Unread',
                  state.unreadCount.toString(),
                  Icons.notifications_active,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Read',
                  state.readNotifications.length.toString(),
                  Icons.mark_email_read,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickStat(
                  context,
                  'System',
                  state.allNotifications
                      .where((n) => n.type == model.NotificationType.system)
                      .length
                      .toString(),
                  Icons.settings,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter Section
          Row(
            children: [
              // Filter Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.getDividerColor(context),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.getSurfaceColor(context),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.selectedFilter,
                      isExpanded: true,
                      hint: Text(
                        'All Notifications',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All Notifications'),
                        ),
                        DropdownMenuItem(
                          value: 'Unread',
                          child: Text('Unread'),
                        ),
                        DropdownMenuItem(value: 'Read', child: Text('Read')),
                        DropdownMenuItem(value: 'Quiz', child: Text('Quiz')),
                        DropdownMenuItem(
                          value: 'Course',
                          child: Text('Course'),
                        ),
                        DropdownMenuItem(
                          value: 'System',
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: 'Reminder',
                          child: Text('Reminder'),
                        ),
                      ],
                      onChanged: (value) => notifier.setFilter(value!),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NotificationState state,
    NotificationNotifier notifier,
  ) {
    final groupedNotifications = state.groupedNotifications;

    if (groupedNotifications.isEmpty) {
      return EmptyStateWidget(
        icon: state.selectedFilter != 'All'
            ? Icons.filter_list_off
            : Icons.notifications_off,
        title: state.selectedFilter != 'All'
            ? 'No Notifications Found'
            : 'No Notifications Available',
        message: state.selectedFilter != 'All'
            ? 'No notifications match the selected filter'
            : 'Start by creating your first notification',
        action: ElevatedButton.icon(
          onPressed: () => _showCreateNotificationDialog(context, notifier),
          icon: const Icon(Icons.add),
          label: const Text('Create Notification'),
        ),
      );
    }

    return Column(
      children: [
        // Notifications List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => notifier.loadAllNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedNotifications.length,
              itemBuilder: (context, index) {
                final group = groupedNotifications[index];
                return _buildGroupedNotificationCard(context, group, notifier);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedNotificationCard(
    BuildContext context,
    Map<String, dynamic> group,
    NotificationNotifier notifier,
  ) {
    final notification = group['notification'] as model.Notification;
    final count = group['count'] as int;
    final isBroadcast = group['isBroadcast'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? AppTheme.getDividerColor(context)
              : AppTheme.primaryColor.withValues(alpha: 0.3),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getDividerColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () =>
            _showGroupedNotificationDetailsDialog(context, group, notifier),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Notification Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationTypeColor(
                        notification.type,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationTypeIcon(notification.type),
                      size: 20,
                      color: _getNotificationTypeColor(notification.type),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title and Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _getNotificationTypeLabel(notification.type),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getNotificationTypeColor(
                                  notification.type,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isBroadcast) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'BROADCAST • $count users',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions Menu
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleGroupedNotificationAction(
                      context,
                      value,
                      group,
                      notifier,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('View Details'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Message Preview
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer Row
              Row(
                children: [
                  // Date
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),

                  const Spacer(),

                  // Target Info
                  if (!isBroadcast)
                    Text(
                      'Target User ID: #${notification.userId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleGroupedNotificationAction(
    BuildContext context,
    String action,
    Map<String, dynamic> group,
    NotificationNotifier notifier,
  ) {
    switch (action) {
      case 'view':
        _showGroupedNotificationDetailsDialog(context, group, notifier);
        break;
      case 'delete':
        _showGroupedDeleteConfirmationDialog(context, group, notifier);
        break;
    }
  }

  void _showCreateNotificationDialog(
    BuildContext context,
    NotificationNotifier notifier,
  ) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Variables to hold the state
    model.NotificationType? selectedTypeHolder;
    int? selectedUserIdHolder;

    AppDialog.show(
      context: context,
      title: 'Create Notification',
      type: DialogType.custom,
      maxWidth: 600,
      content: FutureBuilder(
        future: notifier.getAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final users = snapshot.data!;

          return StatefulBuilder(
            builder: (context, setState) {
              // Initialize local state variables inside StatefulBuilder
              model.NotificationType selectedType =
                  selectedTypeHolder ?? model.NotificationType.system;
              int? selectedUserId = selectedUserIdHolder;

              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information
                      Text(
                        'Notification Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: titleController,
                        labelText: 'Title',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: messageController,
                        labelText: 'Message',
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Message is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Type Selection
                      Text(
                        'Notification Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<model.NotificationType>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: model.NotificationType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getNotificationTypeLabel(type)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTypeHolder = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Target User Selection
                      Text(
                        'Target User (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<int>(
                        initialValue: selectedUserId,
                        decoration: const InputDecoration(
                          labelText: 'Select User (Leave empty for all users)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Users'),
                          ),
                          ...users.map(
                            (user) => DropdownMenuItem(
                              value: user.userId,
                              child: Text(user.fullName),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedUserIdHolder = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      actions: [
        DialogAction.cancel(context: context),
        DialogAction.save(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop();

              // Create notification
              // Pass null for "All Users" (broadcast) - will use admin ID
              await notifier.createNotification(
                userId: selectedUserIdHolder, // null = broadcast to all users
                type: selectedTypeHolder ?? model.NotificationType.system,
                title: titleController.text,
                message: messageController.text,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  void _showGroupedNotificationDetailsDialog(
    BuildContext context,
    Map<String, dynamic> group,
    NotificationNotifier notifier,
  ) {
    final notification = group['notification'] as model.Notification;
    final userIds = group['userIds'] as List<int>;
    final count = group['count'] as int;
    final isBroadcast = group['isBroadcast'] as bool;

    AppDialog.show(
      context: context,
      title: 'Notification Details',
      type: DialogType.info,
      maxWidth: 500,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getNotificationTypeColor(
                    notification.type,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationTypeIcon(notification.type),
                  size: 24,
                  color: _getNotificationTypeColor(notification.type),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _getNotificationTypeLabel(notification.type),
                          style: TextStyle(
                            fontSize: 14,
                            color: _getNotificationTypeColor(notification.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isBroadcast) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'BROADCAST',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
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

          const SizedBox(height: 20),

          // Message
          Text(
            'Message',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notification.message,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),

          const SizedBox(height: 20),

          // Details
          _buildInfoRow(
            context,
            'Recipients',
            isBroadcast
                ? '$count users (All Users)'
                : 'Single User (#${notification.userId})',
            Icons.people,
          ),
          _buildInfoRow(
            context,
            'Created',
            _formatDate(notification.createdAt),
            Icons.schedule,
          ),
          if (isBroadcast)
            _buildInfoRow(
              context,
              'Target User IDs',
              userIds.take(10).map((id) => '#$id').join(', ') +
                  (userIds.length > 10 ? '...' : ''),
              Icons.group,
            ),
        ],
      ),
      actions: [DialogAction.ok()],
    );
  }

  void _showGroupedDeleteConfirmationDialog(
    BuildContext context,
    Map<String, dynamic> group,
    NotificationNotifier notifier,
  ) {
    final notification = group['notification'] as model.Notification;
    final count = group['count'] as int;
    final isBroadcast = group['isBroadcast'] as bool;
    final notificationIds = group['notificationIds'] as List<int>;

    AppDialog.show(
      context: context,
      title: 'Delete Notification',
      type: DialogType.warning,
      content: Text(
        isBroadcast
            ? 'Are you sure you want to delete "${notification.title}"? This will delete $count notification instances sent to all users. This action cannot be undone.'
            : 'Are you sure you want to delete "${notification.title}"? This action cannot be undone.',
      ),
      actions: [
        DialogAction.cancel(context: context),
        DialogAction.confirm(
          text: 'Delete',
          onPressed: () async {
            Navigator.of(context).pop();

            // Delete all notifications in the group
            if (isBroadcast) {
              await notifier.deleteBulkNotifications(notificationIds);
            } else {
              await notifier.deleteNotification(notificationIds.first);
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isBroadcast
                        ? '${notification.title} has been deleted ($count instances)'
                        : '${notification.title} has been deleted',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.getSecondaryTextColor(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  IconData _getNotificationTypeIcon(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.quiz:
        return Icons.quiz;
      case model.NotificationType.course:
        return Icons.book;
      case model.NotificationType.system:
        return Icons.settings;
      case model.NotificationType.reminder:
        return Icons.alarm;
    }
  }

  Color _getNotificationTypeColor(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.quiz:
        return Colors.blue;
      case model.NotificationType.course:
        return Colors.green;
      case model.NotificationType.system:
        return Colors.orange;
      case model.NotificationType.reminder:
        return Colors.purple;
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
}
