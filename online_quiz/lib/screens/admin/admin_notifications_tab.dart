import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_theme.dart';
import '../../data/mock_data.dart';
import '../../models/notification.dart' as model;
import '../../providers/notification_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/dialog.dart';
import '../../widgets/empty_state_widget.dart';

class AdminNotificationsTab extends ConsumerStatefulWidget {
  const AdminNotificationsTab({super.key});

  @override
  ConsumerState<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends ConsumerState<AdminNotificationsTab> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications when the tab is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).loadAllNotifications(); // Load all notifications for admin
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationNotifierProvider);
    final notificationNotifier = ref.read(notificationNotifierProvider.notifier);

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
                  : _buildContent(context, notificationState, notificationNotifier),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          right: 16, 
          bottom: notificationState.totalPages > 1 ? 120 : 16, // Dynamic padding based on pagination
        ),
        child: FloatingActionButton(
          onPressed: () => _showCreateNotificationDialog(context, notificationNotifier),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(BuildContext context, NotificationState state, NotificationNotifier notifier) {
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
          // Title and Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
                'Notification Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
              const SizedBox(height: 8),
            Text(
                'Manage system notifications and announcements',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
              const SizedBox(height: 16),
              // Quick Stats
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickStat(context, 'Total', state.allNotifications.length.toString(), Icons.notifications),
                    const SizedBox(width: 12),
                    _buildQuickStat(context, 'Unread', state.unreadCount.toString(), Icons.notifications_active),
                    const SizedBox(width: 12),
                    _buildQuickStat(context, 'Read', state.readNotifications.length.toString(), Icons.mark_email_read),
                    const SizedBox(width: 12),
                    _buildQuickStat(context, 'System', state.allNotifications.where((n) => n.type == model.NotificationType.system).length.toString(), Icons.settings),
                  ],
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
                    border: Border.all(color: AppTheme.getDividerColor(context)),
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
                        DropdownMenuItem(value: 'All', child: Text('All Notifications')),
                        DropdownMenuItem(value: 'Unread', child: Text('Unread')),
                        DropdownMenuItem(value: 'Read', child: Text('Read')),
                        DropdownMenuItem(value: 'Quiz', child: Text('Quiz')),
                        DropdownMenuItem(value: 'Course', child: Text('Course')),
                        DropdownMenuItem(value: 'System', child: Text('System')),
                        DropdownMenuItem(value: 'Reminder', child: Text('Reminder')),
                      ],
                      onChanged: (value) => notifier.setFilter(value!),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Mark All Read Button
              if (state.unreadCount > 0)
                ElevatedButton.icon(
                  onPressed: () => _showMarkAllReadDialog(context, notifier),
                  icon: const Icon(Icons.mark_email_read, size: 16),
                  label: const Text('Mark All Read'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotificationState state, NotificationNotifier notifier) {
    final paginatedNotifications = state.paginatedNotifications;
    
    if (paginatedNotifications.isEmpty) {
      return EmptyStateWidget(
        icon: state.selectedFilter != 'All' ? Icons.filter_list_off : Icons.notifications_off,
        title: state.selectedFilter != 'All' ? 'No Notifications Found' : 'No Notifications Available',
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
              itemCount: paginatedNotifications.length,
              itemBuilder: (context, index) {
                final notification = paginatedNotifications[index];
                return _buildNotificationCard(context, notification, notifier);
              },
            ),
          ),
        ),
        
        // Pagination Controls
        if (state.totalPages > 1) _buildPaginationControls(context, state, notifier),
      ],
    );
  }

  Widget _buildNotificationCard(BuildContext context, model.Notification notification, NotificationNotifier notifier) {
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
        onTap: () => _showNotificationDetailsDialog(context, notification, notifier),
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
                      color: _getNotificationTypeColor(notification.type).withValues(alpha: 0.1),
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
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getNotificationTypeLabel(notification.type),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getNotificationTypeColor(notification.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Read Status and Actions
                  Row(
                    children: [
                      // Read Status Indicator
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      
                      const SizedBox(width: 8),
                      
                      // Actions Menu
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleNotificationAction(context, value, notification, notifier),
                        itemBuilder: (context) => [
                          if (!notification.isRead)
                            const PopupMenuItem(value: 'mark_read', child: Text('Mark as Read')),
                          if (notification.isRead)
                            const PopupMenuItem(value: 'mark_unread', child: Text('Mark as Unread')),
                          const PopupMenuItem(value: 'view', child: Text('View Details')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, NotificationState state, NotificationNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        border: Border(
          top: BorderSide(
            color: AppTheme.getDividerColor(context),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Items info
          Text(
            'Showing ${state.currentPage * state.itemsPerPage + 1}-${(state.currentPage + 1) * state.itemsPerPage} of ${state.filteredNotifications.length} notifications',
            style: TextStyle(
              color: AppTheme.getSecondaryTextColor(context),
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Pagination controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              IconButton(
                onPressed: state.hasPreviousPage ? notifier.previousPage : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: state.hasPreviousPage 
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
              ),
              
              // Page numbers
              ...List.generate(
                state.totalPages.clamp(0, 5), // Show max 5 page numbers
                (index) {
                  int pageNumber;
                  if (state.totalPages <= 5) {
                    pageNumber = index;
                  } else {
                    // Smart pagination: show current page and surrounding pages
                    if (state.currentPage <= 2) {
                      pageNumber = index;
                    } else if (state.currentPage >= state.totalPages - 3) {
                      pageNumber = state.totalPages - 5 + index;
                    } else {
                      pageNumber = state.currentPage - 2 + index;
                    }
                  }
                  
                  final isCurrentPage = pageNumber == state.currentPage;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1), // Reduced padding
                    child: InkWell(
                      onTap: () => notifier.setPage(pageNumber),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 30, // Reduced width
                        height: 30, // Reduced height
                        decoration: BoxDecoration(
                          color: isCurrentPage 
                              ? AppTheme.primaryColor
                              : AppTheme.getSurfaceColor(context),
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrentPage 
                              ? null
                              : Border.all(
                                  color: AppTheme.getDividerColor(context),
                                  width: 1,
                                ),
                        ),
                        child: Center(
                          child: Text(
                            (pageNumber + 1).toString(),
                            style: TextStyle(
                              color: isCurrentPage 
                                  ? Colors.white
                                  : AppTheme.getTextColor(context),
                              fontWeight: isCurrentPage 
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12, // Reduced font size
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Next button
              IconButton(
                onPressed: state.hasNextPage ? notifier.nextPage : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: state.hasNextPage 
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleNotificationAction(BuildContext context, String action, model.Notification notification, NotificationNotifier notifier) {
    switch (action) {
      case 'mark_read':
        notifier.markAsRead(notification);
        break;
      case 'mark_unread':
        // Note: This would require adding a markAsUnread method to the provider
        break;
      case 'view':
        _showNotificationDetailsDialog(context, notification, notifier);
        break;
      case 'edit':
        _showEditNotificationDialog(context, notification, notifier);
        break;
      case 'delete':
        _showDeleteConfirmationDialog(context, notification, notifier);
        break;
    }
  }

  void _showCreateNotificationDialog(BuildContext context, NotificationNotifier notifier) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    
    model.NotificationType selectedType = model.NotificationType.system;
    int? selectedUserId;
    
    final formKey = GlobalKey<FormState>();

    AppDialog.show(
      context: context,
      title: 'Create Notification',
      type: DialogType.custom,
      maxWidth: 600,
      content: StatefulBuilder(
        builder: (context, setState) {
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
                    items: model.NotificationType.values.map((type) => 
                        DropdownMenuItem(
                          value: type,
                          child: Text(_getNotificationTypeLabel(type)),
                        )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
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
                      ...MockData.users.map((user) => 
                          DropdownMenuItem(
                            value: user.userId,
                            child: Text(user.fullName),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedUserId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
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
              final newNotification = model.Notification(
                notificationId: MockData.notifications.isNotEmpty
                    ? MockData.notifications.map((n) => n.notificationId).reduce((a, b) => a > b ? a : b) + 1
                    : 1,
                userId: selectedUserId ?? 0, // 0 means all users
                title: titleController.text,
                message: messageController.text,
                type: selectedType,
                isRead: false,
                createdAt: DateTime.now(),
              );
              
              // Add to mock data
              MockData.notifications.add(newNotification);
              
              // Refresh notifications
              await notifier.loadAllNotifications();
              
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

  void _showEditNotificationDialog(BuildContext context, model.Notification notification, NotificationNotifier notifier) {
    final titleController = TextEditingController(text: notification.title);
    final messageController = TextEditingController(text: notification.message);
    
    model.NotificationType selectedType = notification.type;
    
    final formKey = GlobalKey<FormState>();

    AppDialog.show(
      context: context,
      title: 'Edit Notification',
      type: DialogType.custom,
      maxWidth: 600,
      content: StatefulBuilder(
        builder: (context, setState) {
          return Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<model.NotificationType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: model.NotificationType.values.map((type) => 
                        DropdownMenuItem(
                          value: type,
                          child: Text(_getNotificationTypeLabel(type)),
                        )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
            ),
          ],
        ),
      ),
    );
        },
      ),
      actions: [
        DialogAction.cancel(context: context),
        DialogAction.save(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop();
              
              // Update notification in mock data
              final index = MockData.notifications.indexWhere((n) => n.notificationId == notification.notificationId);
              if (index != -1) {
                MockData.notifications[index] = notification.copyWith(
                  title: titleController.text,
                  message: messageController.text,
                  type: selectedType,
                );
              }
              
              // Refresh notifications
              await notifier.loadAllNotifications();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification updated successfully!'),
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

  void _showNotificationDetailsDialog(BuildContext context, model.Notification notification, NotificationNotifier notifier) {
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
                  color: _getNotificationTypeColor(notification.type).withValues(alpha: 0.1),
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
                    Text(
                      _getNotificationTypeLabel(notification.type),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getNotificationTypeColor(notification.type),
                        fontWeight: FontWeight.w600,
                      ),
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
          _buildInfoRow(context, 'Status', notification.isRead ? 'Read' : 'Unread', Icons.mark_email_read),
          _buildInfoRow(context, 'Created', _formatDate(notification.createdAt), Icons.schedule),
          if (notification.userId != 0)
            _buildInfoRow(context, 'Target User', MockData.getUserById(notification.userId)?.fullName ?? 'Unknown', Icons.person),
        ],
      ),
      actions: [
        DialogAction.ok(),
      ],
    );
  }

  void _showMarkAllReadDialog(BuildContext context, NotificationNotifier notifier) {
    AppDialog.show(
      context: context,
      title: 'Mark All as Read',
      type: DialogType.warning,
      content: const Text('Are you sure you want to mark all notifications as read?'),
      actions: [
        DialogAction.cancel(context: context),
        DialogAction.confirm(
          text: 'Mark All Read',
          onPressed: () async {
            Navigator.of(context).pop();
            await notifier.markAllAsRead();
            await notifier.loadAllNotifications();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, model.Notification notification, NotificationNotifier notifier) {
    AppDialog.show(
      context: context,
      title: 'Delete Notification',
      type: DialogType.warning,
      content: Text('Are you sure you want to delete "${notification.title}"? This action cannot be undone.'),
      actions: [
        DialogAction.cancel(context: context),
        DialogAction.confirm(
          text: 'Delete',
          onPressed: () async {
            Navigator.of(context).pop();
            
            // Remove from mock data
            MockData.notifications.removeWhere((n) => n.notificationId == notification.notificationId);
            
            // Refresh notifications
            await notifier.loadAllNotifications();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${notification.title} has been deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.getSecondaryTextColor(context),
          ),
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
