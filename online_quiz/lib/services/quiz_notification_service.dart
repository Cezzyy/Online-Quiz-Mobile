import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as models;
import '../models/quiz.dart';
import '../models/course.dart';
import 'notification_service.dart';

/// Service for handling quiz-related notifications
/// Includes: new quiz notifications, enrollment notifications, deadline reminders
class QuizNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  /// Send notification when a new quiz is published
  /// Notifies all students enrolled in the course
  Future<void> notifyNewQuiz({
    required Quiz quiz,
    required Course course,
  }) async {
    try {
      // Get all students enrolled in the course
      final enrolledStudents = await _getEnrolledStudents(course.courseId);
      
      if (enrolledStudents.isEmpty) {
        if (kDebugMode) {
          debugPrint('No enrolled students to notify for quiz: ${quiz.title}');
        }
        return;
      }

      final studentIds = enrolledStudents.map((s) => s['UserId'] as int).toList();
      
      // Create notification title and message
      final title = 'New Quiz Available: ${quiz.title}';
      final dueDate = quiz.dueAt != null 
          ? ' Due: ${_formatDateTime(quiz.dueAt!)}'
          : '';
      final message = 'A new quiz "${quiz.title}" has been published in ${course.name}.$dueDate';

      // Send bulk notifications to all enrolled students
      await _notificationService.createBulkNotifications(
        userIds: studentIds,
        type: models.NotificationType.quiz,
        title: title,
        message: message,
      );

      if (kDebugMode) {
        debugPrint('Sent new quiz notification to ${studentIds.length} students');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending new quiz notification: $e');
      }
      rethrow;
    }
  }

  /// Send notification when a student is enrolled in a course
  /// Notifies about existing quizzes in the course
  Future<void> notifyEnrollment({
    required int studentId,
    required Course course,
  }) async {
    try {
      // Get active quizzes in the course
      final quizzes = await _getActiveQuizzes(course.courseId);
      
      if (quizzes.isEmpty) {
        // Just notify about enrollment
        await _notificationService.createNotification(
          userId: studentId,
          type: models.NotificationType.course,
          title: 'Enrolled in ${course.name}',
          message: 'You have been successfully enrolled in ${course.name}. Quizzes will appear here when they are published.',
        );
      } else {
        // Notify about enrollment and available quizzes
        final quizCount = quizzes.length;
        final quizWord = quizCount == 1 ? 'quiz' : 'quizzes';
        
        await _notificationService.createNotification(
          userId: studentId,
          type: models.NotificationType.course,
          title: 'Enrolled in ${course.name}',
          message: 'You have been enrolled in ${course.name}. There ${quizCount == 1 ? 'is' : 'are'} $quizCount active $quizWord available.',
        );
      }

      if (kDebugMode) {
        debugPrint('Sent enrollment notification to student ID: $studentId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending enrollment notification: $e');
      }
      rethrow;
    }
  }

  /// Send 24-hour deadline reminder for quizzes
  /// Should be called periodically (e.g., daily cron job or background task)
  Future<void> send24HourReminders() async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(hours: 24));
      final dayAfter = now.add(const Duration(hours: 25)); // 1 hour buffer

      // Get quizzes due in the next 24 hours
      final quizzes = await _getQuizzesDueBetween(tomorrow, dayAfter);
      
      if (kDebugMode) {
        debugPrint('Found ${quizzes.length} quizzes due in next 24 hours');
      }

      for (final quiz in quizzes) {
        await _sendDeadlineReminder(
          quiz: quiz,
          hoursRemaining: 24,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending 24-hour reminders: $e');
      }
      rethrow;
    }
  }

  /// Send 1-hour deadline reminder for quizzes
  /// Should be called periodically (e.g., hourly cron job or background task)
  Future<void> send1HourReminders() async {
    try {
      final now = DateTime.now();
      final oneHourLater = now.add(const Duration(hours: 1));
      final twoHoursLater = now.add(const Duration(hours: 2)); // 1 hour buffer

      // Get quizzes due in the next 1 hour
      final quizzes = await _getQuizzesDueBetween(oneHourLater, twoHoursLater);
      
      if (kDebugMode) {
        debugPrint('Found ${quizzes.length} quizzes due in next 1 hour');
      }

      for (final quiz in quizzes) {
        await _sendDeadlineReminder(
          quiz: quiz,
          hoursRemaining: 1,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending 1-hour reminders: $e');
      }
      rethrow;
    }
  }

  /// Send deadline reminder to students who haven't completed the quiz
  Future<void> _sendDeadlineReminder({
    required Map<String, dynamic> quiz,
    required int hoursRemaining,
  }) async {
    try {
      final quizId = quiz['QuizId'] as int;
      final quizTitle = quiz['Title'] as String;
      final courseId = quiz['CourseId'] as int;
      final dueAt = DateTime.parse(quiz['Due_At'] as String);

      // Get course info
      final courseResponse = await _supabase
          .from('Course')
          .select('CourseName, CourseCode')
          .eq('CourseId', courseId)
          .single();

      final courseName = courseResponse['CourseName'] as String;

      // Get enrolled students
      final enrolledStudents = await _getEnrolledStudents(courseId);
      
      if (enrolledStudents.isEmpty) return;

      // Get students who have already completed the quiz
      final attemptResponse = await _supabase
          .from('Attempt')
          .select('UserId')
          .eq('QuizId', quizId)
          .not('SubmittedAt', 'is', null); // Only submitted attempts

      final completedUserIds = attemptResponse
          .map((a) => a['UserId'] as int)
          .toSet();

      // Filter to students who haven't completed the quiz
      final notCompleted = enrolledStudents
          .where((s) => !completedUserIds.contains(s['UserId'] as int))
          .map((s) => s['UserId'] as int)
          .toList();

      if (notCompleted.isEmpty) {
        if (kDebugMode) {
          debugPrint('All students completed quiz: $quizTitle');
        }
        return;
      }

      // Create reminder notification
      final title = hoursRemaining == 24
          ? '⏰ Quiz Due Tomorrow: $quizTitle'
          : '🚨 Quiz Due Soon: $quizTitle';
      
      final timeRemaining = hoursRemaining == 24 ? '24 hours' : '1 hour';
      final message = 'Reminder: "$quizTitle" in $courseName is due in $timeRemaining (${_formatDateTime(dueAt)}). Complete it before the deadline!';

      // Send bulk notifications
      await _notificationService.createBulkNotifications(
        userIds: notCompleted,
        type: models.NotificationType.reminder,
        title: title,
        message: message,
      );

      if (kDebugMode) {
        debugPrint('Sent $hoursRemaining-hour reminder to ${notCompleted.length} students for quiz: $quizTitle');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending deadline reminder: $e');
      }
      rethrow;
    }
  }

  /// Get students enrolled in a course
  Future<List<Map<String, dynamic>>> _getEnrolledStudents(int courseId) async {
    try {
      final response = await _supabase
          .from('Enrollment')
          .select('UserId')
          .eq('CourseId', courseId);

      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting enrolled students: $e');
      }
      rethrow;
    }
  }

  /// Get active (published) quizzes in a course
  Future<List<Map<String, dynamic>>> _getActiveQuizzes(int courseId) async {
    try {
      final response = await _supabase
          .from('Quiz')
          .select('QuizId, Title, Due_At')
          .eq('CourseId', courseId)
          .eq('Is_Published', true)
          .order('Due_At', ascending: true);

      return response.map((q) => Map<String, dynamic>.from(q)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting active quizzes: $e');
      }
      rethrow;
    }
  }

  /// Get quizzes with due dates between two timestamps
  Future<List<Map<String, dynamic>>> _getQuizzesDueBetween(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase
          .from('Quiz')
          .select('QuizId, Title, CourseId, Due_At')
          .eq('Is_Published', true)
          .gte('Due_At', start.toIso8601String())
          .lt('Due_At', end.toIso8601String());

      return response.map((q) => Map<String, dynamic>.from(q)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting quizzes due between dates: $e');
      }
      rethrow;
    }
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      // Today
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      // Tomorrow
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else {
      // Specific date
      return '${_formatDate(dateTime)} at ${_formatTime(dateTime)}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
