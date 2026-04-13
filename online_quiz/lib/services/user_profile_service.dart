import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../models/student.dart';
import '../models/course.dart';
import 'activity_log_service.dart';

class UserProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ActivityLogService _activityLog = ActivityLogService();

  /// Fetch complete user profile with student details
  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      // Fetch user data
      final userResponse = await _supabase
          .from('User')
          .select()
          .eq('UserId', userId)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('User not found');
      }

      final user = models.User.fromJson(userResponse);

      // Fetch student details
      final studentResponse = await _supabase
          .from('Student')
          .select()
          .eq('UserId', userId)
          .maybeSingle();

      Student? student;
      if (studentResponse != null) {
        student = Student.fromJson(studentResponse);
      }

      return {
        'user': user,
        'student': student,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch user profile: ${e.toString()}');
    }
  }

  /// Fetch enrolled courses for a student
  Future<List<Course>> getEnrolledCourses(int userId) async {
    try {
      final response = await _supabase
          .from('Enrollment')
          .select('''
            CourseId,
            Course!inner(
              CourseId,
              Code,
              Name,
              Instructor_UserId,
              Status,
              Category,
              Section,
              CreatedAt,
              UpdatedAt,
              CreatedBy
            )
          ''')
          .eq('UserId', userId);

      final courses = <Course>[];
      for (var enrollment in response) {
        final courseData = enrollment['Course'] as Map<String, dynamic>;
        courses.add(Course.fromJson(courseData));
      }

      return courses;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch enrolled courses: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch enrolled courses: ${e.toString()}');
    }
  }

  /// Fetch student quiz statistics
  Future<Map<String, dynamic>> getQuizStatistics(int userId) async {
    try {
      // Get all attempts for the student
      final attemptsResponse = await _supabase
          .from('Attempt')
          .select('''
            AttemptId,
            QuizId,
            StartedAt,
            SubmittedAt,
            Score,
            Time_Spent_Seconds,
            Quiz!inner(
              QuizId,
              Title,
              CourseId
            )
          ''')
          .eq('UserId', userId);

      // Calculate statistics
      int totalAttempts = attemptsResponse.length;
      int completedAttempts = 0;
      double totalPercentage = 0.0;
      int totalTimeSpent = 0;

      final recentAttempts = <Map<String, dynamic>>[];

      for (var attempt in attemptsResponse) {
        if (attempt['SubmittedAt'] != null) {
          completedAttempts++;
          
          // Get quiz questions to calculate total possible points
          final quizId = attempt['QuizId'] as int;
          final questionsResponse = await _supabase
              .from('Question')
              .select('Points')
              .eq('QuizId', quizId);
          
          double totalPoints = 0.0;
          for (var question in questionsResponse) {
            totalPoints += (question['Points'] as num).toDouble();
          }
          
          // Calculate percentage for this attempt
          final score = (attempt['Score'] as num).toDouble();
          final percentage = totalPoints > 0 ? (score / totalPoints) * 100 : 0.0;
          totalPercentage += percentage;
          
          if (attempt['Time_Spent_Seconds'] != null) {
            totalTimeSpent += (attempt['Time_Spent_Seconds'] as int);
          }

          // Add to recent attempts with total questions count
          recentAttempts.add({
            'attemptId': attempt['AttemptId'],
            'quizId': attempt['QuizId'],
            'quizTitle': attempt['Quiz']['Title'],
            'score': score,
            'totalQuestions': questionsResponse.length,
            'submittedAt': DateTime.parse(attempt['SubmittedAt'] as String),
          });
        }
      }

      // Sort recent attempts by date (most recent first)
      recentAttempts.sort((a, b) => 
        (b['submittedAt'] as DateTime).compareTo(a['submittedAt'] as DateTime)
      );

      // Get total available quizzes from enrolled courses
      final enrolledCourses = await getEnrolledCourses(userId);
      int totalQuizzes = 0;
      
      for (var course in enrolledCourses) {
        final quizzes = await _supabase
            .from('Quiz')
            .select('QuizId')
            .eq('CourseId', course.courseId)
            .eq('Is_Published', true);
        
        totalQuizzes += quizzes.length;
      }

      return {
        'totalQuizzes': totalQuizzes,
        'completedAttempts': completedAttempts,
        'totalAttempts': totalAttempts,
        'averageScore': completedAttempts > 0 ? totalPercentage / completedAttempts : 0.0,
        'totalTimeSpent': totalTimeSpent,
        'recentAttempts': recentAttempts.take(5).toList(),
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch quiz statistics: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch quiz statistics: ${e.toString()}');
    }
  }

  /// Get course progress for a student
  Future<Map<int, double>> getCourseProgress(int userId) async {
    try {
      final enrolledCourses = await getEnrolledCourses(userId);
      final courseProgress = <int, double>{};

      for (var course in enrolledCourses) {
        // Get total quizzes in course
        final totalQuizzes = await _supabase
            .from('Quiz')
            .select('QuizId')
            .eq('CourseId', course.courseId)
            .eq('Is_Published', true);

        // Get completed attempts for quizzes in this course
        final completedAttempts = await _supabase
            .from('Attempt')
            .select('QuizId')
            .eq('UserId', userId)
            .not('SubmittedAt', 'is', null)
            .inFilter('QuizId', totalQuizzes.map((q) => q['QuizId']).toList());

        final progress = totalQuizzes.isNotEmpty 
            ? completedAttempts.length / totalQuizzes.length 
            : 0.0;

        courseProgress[course.courseId] = progress;
      }

      return courseProgress;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch course progress: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch course progress: ${e.toString()}');
    }
  }

  /// Update user profile information
  Future<void> updateUserProfile({
    required int userId,
    String? contactNumber,
    String? emergencyContactNumber,
    String? emergencyContactPerson,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (contactNumber != null) {
        updates['ContactNumber'] = contactNumber;
      }
      if (emergencyContactNumber != null) {
        updates['EmergencyContactNumber'] = emergencyContactNumber;
      }
      if (emergencyContactPerson != null) {
        updates['EmergencyContactPerson'] = emergencyContactPerson;
      }

      if (updates.isEmpty) {
        return;
      }

      updates['UpdatedAt'] = DateTime.now().toIso8601String();

      await _supabase
          .from('User')
          .update(updates)
          .eq('UserId', userId);

      // Log profile update
      try {
        await _activityLog.logUserUpdate(
          updatedBy: userId,
          updatedUserId: userId,
          oldData: {},
          newData: updates,
        );
      } catch (e) {
        debugPrint('Failed to log profile update: $e');
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Get recent notifications for user
  Future<List<Map<String, dynamic>>> getNotifications(int userId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('Notification')
          .select()
          .eq('UserId', userId)
          .order('CreatedAt', ascending: false)
          .limit(limit);

      return response.map((n) => Map<String, dynamic>.from(n)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch notifications: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch notifications: ${e.toString()}');
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
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }
}
