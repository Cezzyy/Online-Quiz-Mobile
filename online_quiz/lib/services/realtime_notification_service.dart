import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as models;
import 'local_notification_service.dart';

class RealtimeNotificationService {
  static final RealtimeNotificationService _instance =
      RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();

  RealtimeChannel? _channel;
  int? _currentUserId;

  /// Subscribe to notifications for a specific user
  Future<void> subscribeToNotifications(int userId) async {
    // Unsubscribe from any existing subscription first
    await unsubscribe();

    _currentUserId = userId;

    if (kDebugMode) {
      debugPrint('Subscribing to notifications for user: $userId');
    }

    try {
      // Create a channel for this user's notifications
      _channel = _supabase.channel('notifications:$userId');

      // Subscribe to INSERT events on the Notification table
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'Notification',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'UserId',
          value: userId,
        ),
        callback: (payload) {
          if (kDebugMode) {
            debugPrint('New notification received: ${payload.newRecord}');
          }
          _handleNewNotification(payload.newRecord);
        },
      );

      // Subscribe to the channel
      _channel!.subscribe();

      if (kDebugMode) {
        debugPrint('Successfully subscribed to notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error subscribing to notifications: $e');
      }
    }
  }

  /// Handle new notification from database
  void _handleNewNotification(Map<String, dynamic> data) {
    try {
      // Parse the notification
      final notification = models.Notification.fromJson(data);

      // Create payload with notification metadata
      final payload = jsonEncode({
        'notificationId': notification.notificationId,
        'type': notification.type.value,
      });

      // Show local notification
      _localNotificationService.showNotification(
        title: notification.title,
        body: notification.message,
        payload: payload,
        type: notification.type.value,
      );

      if (kDebugMode) {
        debugPrint('Local notification shown for: ${notification.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error handling new notification: $e');
      }
    }
  }

  /// Unsubscribe from notifications
  Future<void> unsubscribe() async {
    if (_channel != null) {
      if (kDebugMode) {
        debugPrint('Unsubscribing from notifications');
      }

      try {
        await _supabase.removeChannel(_channel!);
        _channel = null;
        _currentUserId = null;

        if (kDebugMode) {
          debugPrint('Successfully unsubscribed from notifications');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error unsubscribing from notifications: $e');
        }
      }
    }
  }

  /// Check if currently subscribed
  bool get isSubscribed => _channel != null && _currentUserId != null;

  /// Get current subscribed user ID
  int? get currentUserId => _currentUserId;
}
