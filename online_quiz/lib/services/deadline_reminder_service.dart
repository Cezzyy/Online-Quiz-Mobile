import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quiz_notification_service.dart';

/// Service for periodic deadline checking and reminder notifications
/// This service runs when the app is in use and checks for upcoming quiz deadlines
class DeadlineReminderService {
  static final DeadlineReminderService _instance = DeadlineReminderService._internal();
  factory DeadlineReminderService() => _instance;
  DeadlineReminderService._internal();

  final QuizNotificationService _notificationService = QuizNotificationService();
  Timer? _reminderTimer;
  bool _isRunning = false;

  // Keys for storing last check times
  static const String _last24HourCheckKey = 'last_24hour_reminder_check';
  static const String _last1HourCheckKey = 'last_1hour_reminder_check';

  /// Start the periodic reminder service
  /// Checks for deadlines every hour when app is running
  void startPeriodicChecks() {
    if (_isRunning) {
      if (kDebugMode) {
        debugPrint('Deadline reminder service is already running');
      }
      return;
    }

    _isRunning = true;

    if (kDebugMode) {
      debugPrint('Starting deadline reminder service');
    }

    // Run initial check immediately
    _checkDeadlines();

    // Set up periodic checks every hour
    _reminderTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) => _checkDeadlines(),
    );
  }

  /// Stop the periodic reminder service
  void stop() {
    if (kDebugMode) {
      debugPrint('Stopping deadline reminder service');
    }

    _reminderTimer?.cancel();
    _reminderTimer = null;
    _isRunning = false;
  }

  /// Check if the service is currently running
  bool get isRunning => _isRunning;

  /// Manually trigger a deadline check
  /// Useful for testing or forcing an immediate check
  Future<void> checkNow() async {
    if (kDebugMode) {
      debugPrint('Manual deadline check triggered');
    }
    await _checkDeadlines();
  }

  /// Internal method to check deadlines and send reminders
  Future<void> _checkDeadlines() async {
    if (kDebugMode) {
      debugPrint('Checking quiz deadlines...');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Check for 24-hour reminders
      await _check24HourReminders(prefs, now);

      // Check for 1-hour reminders
      await _check1HourReminders(prefs, now);

      if (kDebugMode) {
        debugPrint('Deadline check completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during deadline check: $e');
      }
    }
  }

  /// Check and send 24-hour reminders
  /// Only sends once per day to avoid spam
  Future<void> _check24HourReminders(SharedPreferences prefs, DateTime now) async {
    try {
      final lastCheckStr = prefs.getString(_last24HourCheckKey);
      final lastCheck = lastCheckStr != null 
          ? DateTime.parse(lastCheckStr) 
          : DateTime(2000); // Very old date if never checked

      // Only check once per day
      final hoursSinceLastCheck = now.difference(lastCheck).inHours;
      if (hoursSinceLastCheck < 23) {
        if (kDebugMode) {
          debugPrint('Skipping 24-hour check, last checked $hoursSinceLastCheck hours ago');
        }
        return;
      }

      // Send 24-hour reminders
      await _notificationService.send24HourReminders();

      // Update last check time
      await prefs.setString(_last24HourCheckKey, now.toIso8601String());

      if (kDebugMode) {
        debugPrint('24-hour reminders sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending 24-hour reminders: $e');
      }
    }
  }

  /// Check and send 1-hour reminders
  /// Checks every hour
  Future<void> _check1HourReminders(SharedPreferences prefs, DateTime now) async {
    try {
      final lastCheckStr = prefs.getString(_last1HourCheckKey);
      final lastCheck = lastCheckStr != null 
          ? DateTime.parse(lastCheckStr) 
          : DateTime(2000); // Very old date if never checked

      // Check every hour
      final minutesSinceLastCheck = now.difference(lastCheck).inMinutes;
      if (minutesSinceLastCheck < 55) {
        if (kDebugMode) {
          debugPrint('Skipping 1-hour check, last checked $minutesSinceLastCheck minutes ago');
        }
        return;
      }

      // Send 1-hour reminders
      await _notificationService.send1HourReminders();

      // Update last check time
      await prefs.setString(_last1HourCheckKey, now.toIso8601String());

      if (kDebugMode) {
        debugPrint('1-hour reminders sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending 1-hour reminders: $e');
      }
    }
  }

  /// Reset last check times (useful for testing)
  Future<void> resetCheckTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_last24HourCheckKey);
    await prefs.remove(_last1HourCheckKey);
    
    if (kDebugMode) {
      debugPrint('Reset last check times');
    }
  }

  /// Get last check times for debugging
  Future<Map<String, DateTime?>> getLastCheckTimes() async {
    final prefs = await SharedPreferences.getInstance();
    
    final last24Hour = prefs.getString(_last24HourCheckKey);
    final last1Hour = prefs.getString(_last1HourCheckKey);

    return {
      '24hour': last24Hour != null ? DateTime.parse(last24Hour) : null,
      '1hour': last1Hour != null ? DateTime.parse(last1Hour) : null,
    };
  }
}
