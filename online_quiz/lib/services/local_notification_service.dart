import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'notification_navigation_service.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final NotificationNavigationService _navigationService =
      NotificationNavigationService();

  bool _isInitialized = false;
  Function(String?)? onNotificationTap;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          if (kDebugMode) {
            print('Notification tapped with payload: ${response.payload}');
          }
          // Handle navigation
          _navigationService.handleNotificationTap(response.payload);
          //Trigger callback if set
          onNotificationTap?.call(response.payload);
        }
      },
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('LocalNotificationService initialized');
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Quiz notifications channel
    const quizChannel = AndroidNotificationChannel(
      'quiz_channel',
      'Quiz Notifications',
      description: 'Notifications about new quizzes and quiz updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Course notifications channel
    const courseChannel = AndroidNotificationChannel(
      'course_channel',
      'Course Notifications',
      description: 'Notifications about courses and enrollments',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // System notifications channel
    const systemChannel = AndroidNotificationChannel(
      'system_channel',
      'System Notifications',
      description: 'General system notifications',
      importance: Importance.low,
      playSound: false,
    );

    // Reminder notifications channel
    const reminderChannel = AndroidNotificationChannel(
      'reminder_channel',
      'Reminder Notifications',
      description: 'Quiz and assignment reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create channels
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(quizChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(courseChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(systemChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(reminderChannel);
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    // iOS permissions are requested automatically on first notification
    return true;
  }

  /// Check if notification permission is granted
  Future<bool> isPermissionGranted() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await Permission.notification.isGranted;
    }
    return true;
  }

  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String type = 'System',
  }) async {
    // Ensure initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Check permission
    final hasPermission = await isPermissionGranted();
    if (!hasPermission) {
      if (kDebugMode) {
        print('Notification permission not granted');
      }
      return;
    }

    // Determine channel based on notification type
    String channelId;
    String channelName;
    Importance importance;

    switch (type.toLowerCase()) {
      case 'quiz':
        channelId = 'quiz_channel';
        channelName = 'Quiz Notifications';
        importance = Importance.high;
        break;
      case 'course':
        channelId = 'course_channel';
        channelName = 'Course Notifications';
        importance = Importance.defaultImportance;
        break;
      case 'reminder':
        channelId = 'reminder_channel';
        channelName = 'Reminder Notifications';
        importance = Importance.high;
        break;
      default:
        channelId = 'system_channel';
        channelName = 'System Notifications';
        importance = Importance.low;
    }

    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: importance == Importance.high
          ? Priority.high
          : Priority.defaultPriority,
      showWhen: true,
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    if (kDebugMode) {
      debugPrint('Notification shown: $title');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
