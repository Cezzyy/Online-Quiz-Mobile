import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SystemInfoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get app version from pubspec.yaml
  String getAppVersion() {
    // This matches the version in pubspec.yaml
    return '1.0.0+1';
  }

  /// Check if Supabase connection is active and healthy
  Future<SystemStatus> checkSystemStatus() async {
    try {
      // Try to perform a simple query to verify connection
      await _supabase
          .from('User')
          .select('UserId')
          .limit(1)
          .timeout(const Duration(seconds: 5));

      // If we get here, connection is working
      return SystemStatus(
        isOperational: true,
        message: 'All Systems Operational',
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      // Connection failed
      return SystemStatus(
        isOperational: false,
        message: 'Connection Error',
        lastChecked: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Get database statistics
  Future<DatabaseStats> getDatabaseStats() async {
    try {
      // Get total user count
      final userCountResponse = await _supabase.from('User').select('UserId');

      // Get total course count
      final courseCountResponse = await _supabase
          .from('Course')
          .select('CourseId');

      // Get total quiz count
      final quizCountResponse = await _supabase.from('Quiz').select('QuizId');

      return DatabaseStats(
        totalUsers: userCountResponse.length,
        totalCourses: courseCountResponse.length,
        totalQuizzes: quizCountResponse.length,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching database stats: $e');
      }
      return DatabaseStats(totalUsers: 0, totalCourses: 0, totalQuizzes: 0);
    }
  }
}

class SystemStatus {
  final bool isOperational;
  final String message;
  final DateTime lastChecked;
  final String? error;

  SystemStatus({
    required this.isOperational,
    required this.message,
    required this.lastChecked,
    this.error,
  });
}

class DatabaseStats {
  final int totalUsers;
  final int totalCourses;
  final int totalQuizzes;

  DatabaseStats({
    required this.totalUsers,
    required this.totalCourses,
    required this.totalQuizzes,
  });
}
