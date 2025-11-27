import 'package:flutter/material.dart';

class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  // Global navigator key to access navigator from anywhere
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Handle notification tap and navigate to appropriate screen
  void handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      // Parse payload (assuming JSON format: {"notificationId": ..., "type": ...})
      final data = _parsePayload(payload);
      final type = data['type'] as String?;

      if (type == null) return;

      final context = navigatorKey.currentContext;
      if (context == null) return;

      // Navigate based on notification type
      switch (type.toLowerCase()) {
        case 'quiz':
          _navigateToQuizzes(context);
          break;
        case 'course':
          _navigateToCourses(context);
          break;
        case 'system':
        case 'reminder':
        default:
          _navigateToNotifications(context);
          break;
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Parse notification payload
  Map<String, dynamic> _parsePayload(String payload) {
    try {
      // Simple key-value parsing if it's formatted as "key1:value1,key2:value2"
      if (!payload.startsWith('{')) {
        // Fallback: treat as simple string
        return {'type': payload};
      }

      // Parse JSON-like format
      final Map<String, dynamic> data = {};
      final cleanPayload = payload
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll('"', '');
      final pairs = cleanPayload.split(',');

      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          data[keyValue[0].trim()] = keyValue[1].trim();
        }
      }

      return data;
    } catch (e) {
      debugPrint('Error parsing payload: $e');
      return {};
    }
  }

  /// Navigate to quizzes screen
  void _navigateToQuizzes(BuildContext context) {
    // Navigate to the main screen (student home) which has quizzes
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);

    debugPrint('Navigated to Quizzes');
  }

  /// Navigate to courses screen
  void _navigateToCourses(BuildContext context) {
    // Navigate to the main screen which has courses tab
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);

    debugPrint('Navigated to Courses');
  }

  /// Navigate to notifications list
  void _navigateToNotifications(BuildContext context) {
    // For now, navigate to main screen
    // TODO: Add dedicated notifications screen route
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);

    debugPrint('Navigated to Notifications');
  }
}
