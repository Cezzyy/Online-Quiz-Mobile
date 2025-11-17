import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as models;
import '../models/user.dart' as models;

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all notifications (admin view)
  Future<List<models.Notification>> getAllNotifications() async {
    try {
      final response = await _supabase
          .from('Notification')
          .select('*')
          .order('CreatedAt', ascending: false);

      return response
          .map((json) => models.Notification.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch all notifications: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch all notifications: $e');
    }
  }

  /// Get notifications by user ID
  /// Returns notifications for the specific user
  Future<List<models.Notification>> getNotificationsByUser(int userId) async {
    try {
      final response = await _supabase
          .from('Notification')
          .select('*')
          .eq('UserId', userId)
          .order('CreatedAt', ascending: false);

      return response
          .map((json) => models.Notification.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user notifications: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch user notifications: $e');
    }
  }

  /// Get notifications filtered by type
  Future<List<models.Notification>> getNotificationsByType(
      models.NotificationType type) async {
    try {
      final response = await _supabase
          .from('Notification')
          .select('*')
          .eq('Type', type.value)
          .order('CreatedAt', ascending: false);

      return response
          .map((json) => models.Notification.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch notifications by type: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch notifications by type: $e');
    }
  }

  /// Create a new notification
  Future<models.Notification> createNotification({
    required int userId,
    required models.NotificationType type,
    required String title,
    required String message,
  }) async {
    try {
      final response = await _supabase
          .from('Notification')
          .insert({
            'UserId': userId,
            'Type': type.value,
            'Title': title,
            'Message': message,
            'Is_Read': false,
          })
          .select()
          .single();

      return models.Notification.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create notification: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Create notifications for multiple users (broadcast)
  Future<List<models.Notification>> createBulkNotifications({
    required List<int> userIds,
    required models.NotificationType type,
    required String title,
    required String message,
  }) async {
    try {
      final notifications = userIds.map((userId) => {
            'UserId': userId,
            'Type': type.value,
            'Title': title,
            'Message': message,
            'Is_Read': false,
          }).toList();

      final response = await _supabase
          .from('Notification')
          .insert(notifications)
          .select();

      return response
          .map((json) => models.Notification.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to create bulk notifications: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create bulk notifications: $e');
    }
  }

  /// Update notification
  Future<void> updateNotification({
    required int notificationId,
    String? title,
    String? message,
    models.NotificationType? type,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['Title'] = title;
      if (message != null) updates['Message'] = message;
      if (type != null) updates['Type'] = type.value;

      if (updates.isEmpty) return;

      await _supabase
          .from('Notification')
          .update(updates)
          .eq('NotificationId', notificationId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update notification: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update notification: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _supabase
          .from('Notification')
          .delete()
          .eq('NotificationId', notificationId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete notification: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete multiple notifications
  Future<void> deleteBulkNotifications(List<int> notificationIds) async {
    try {
      await _supabase
          .from('Notification')
          .delete()
          .inFilter('NotificationId', notificationIds);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete notifications: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete notifications: $e');
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _supabase
          .from('Notification')
          .update({'Is_Read': true})
          .eq('NotificationId', notificationId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to mark notification as read: ${e.message}');
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark multiple notifications as read
  Future<void> bulkMarkAsRead(List<int> notificationIds) async {
    try {
      await _supabase
          .from('Notification')
          .update({'Is_Read': true})
          .inFilter('NotificationId', notificationIds);
    } on PostgrestException catch (e) {
      throw Exception('Failed to mark notifications as read: ${e.message}');
    } catch (e) {
      throw Exception('Failed to mark notifications as read: $e');
    }
  }

  /// Get all users (for notification targeting)
  Future<List<models.User>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('User')
          .select('*')
          .eq('Status', 'Active')
          .order('FullName', ascending: true);

      return response.map((json) => models.User.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch users: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Get users by role (for targeted notifications)
  Future<List<models.User>> getUsersByRole(int roleId) async {
    try {
      final response = await _supabase
          .from('UserRole')
          .select('UserId')
          .eq('RoleId', roleId);

      final userIds = response.map((r) => r['UserId'] as int).toList();

      if (userIds.isEmpty) return [];

      final usersResponse = await _supabase
          .from('User')
          .select('*')
          .inFilter('UserId', userIds)
          .eq('Status', 'Active')
          .order('FullName', ascending: true);

      return usersResponse.map((json) => models.User.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch users by role: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch users by role: $e');
    }
  }

  /// Get grouped notifications for admin view
  Future<List<Map<String, dynamic>>> getGroupedNotifications() async {
    try {
      final response = await _supabase
          .from('Notification')
          .select('*')
          .order('CreatedAt', ascending: false);

      final notifications = response
          .map((json) => models.Notification.fromJson(json))
          .toList();

      // Group notifications by title, message, type, and creation time
      final Map<String, List<models.Notification>> groups = {};
      
      for (var notification in notifications) {
        // Create a key based on title, message, type, and creation time (rounded to nearest second)
        final createdAt = notification.createdAt;
        final timeKey = DateTime(createdAt.year, createdAt.month, createdAt.day, 
                                 createdAt.hour, createdAt.minute, createdAt.second);
        
        final key = '${notification.title}|${notification.message}|${notification.type}|$timeKey';
        
        if (!groups.containsKey(key)) {
          groups[key] = [];
        }
        groups[key]!.add(notification);
      }

      // Convert groups to list of maps with metadata
      final List<Map<String, dynamic>> groupedNotifications = [];
      
      for (var entry in groups.entries) {
        final notificationList = entry.value;
        final first = notificationList.first;
        
        groupedNotifications.add({
          'notification': first, // Representative notification
          'userIds': notificationList.map((n) => n.userId).toSet().toList(),
          'count': notificationList.length,
          'isBroadcast': notificationList.length > 1, // Multiple users = broadcast
          'notificationIds': notificationList.map((n) => n.notificationId).toList(),
        });
      }

      return groupedNotifications;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch grouped notifications: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch grouped notifications: $e');
    }
  }

  /// Get notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final allNotifications = await _supabase
          .from('Notification')
          .select('NotificationId, Is_Read');

      final total = allNotifications.length;
      final unread = allNotifications.where((n) => n['Is_Read'] == false).length;
      final read = total - unread;

      return {
        'total': total,
        'read': read,
        'unread': unread,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch notification stats: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch notification stats: $e');
    }
  }
}
