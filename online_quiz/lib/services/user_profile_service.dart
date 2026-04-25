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
      // Get all attempts for the student with quiz details
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
              CourseId,
              Total_Points
            )
          ''')
          .eq('UserId', userId);

      // Calculate statistics
      int totalAttempts = attemptsResponse.length;
      int completedAttempts = 0;
      double totalPercentage = 0.0;
      int totalTimeSpent = 0;

      final recentAttempts = <Map<String, dynamic>>[];
      
      // Collect quiz IDs that need total points calculation (where Total_Points is null or 0)
      final quizIdsNeedingCalculation = <int>{};

      for (var attempt in attemptsResponse) {
        if (attempt['SubmittedAt'] != null) {
          completedAttempts++;
          
          final quizId = attempt['QuizId'] as int;
          var totalPoints = (attempt['Quiz']['Total_Points'] as num?)?.toDouble() ?? 0.0;
          
          // If Total_Points is not available, mark for batch calculation
          if (totalPoints == 0.0) {
            quizIdsNeedingCalculation.add(quizId);
          }
          
          if (attempt['Time_Spent_Seconds'] != null) {
            totalTimeSpent += (attempt['Time_Spent_Seconds'] as int);
          }

          // Add to recent attempts (we'll update total points later if needed)
          recentAttempts.add({
            'attemptId': attempt['AttemptId'],
            'quizId': quizId,
            'quizTitle': attempt['Quiz']['Title'],
            'score': (attempt['Score'] as num).toDouble(),
            'totalPoints': totalPoints,
            'submittedAt': DateTime.parse(attempt['SubmittedAt'] as String),
          });
        }
      }

      // Batch calculate total points for quizzes that need it
      final Map<int, double> calculatedTotalPoints = {};
      if (quizIdsNeedingCalculation.isNotEmpty) {
        final questionsResponse = await _supabase
            .from('Question')
            .select('QuizId, Points')
            .inFilter('QuizId', quizIdsNeedingCalculation.toList());
        
        for (var question in questionsResponse) {
          final quizId = question['QuizId'] as int;
          final points = (question['Points'] as num).toDouble();
          calculatedTotalPoints[quizId] = (calculatedTotalPoints[quizId] ?? 0.0) + points;
        }
      }

      // Update recent attempts with calculated total points and calculate percentages
      for (var attempt in recentAttempts) {
        final quizId = attempt['quizId'] as int;
        if (quizIdsNeedingCalculation.contains(quizId)) {
          attempt['totalPoints'] = calculatedTotalPoints[quizId] ?? 0.0;
        }
        
        final score = attempt['score'] as double;
        final totalPoints = attempt['totalPoints'] as double;
        final percentage = totalPoints > 0 ? (score / totalPoints) * 100 : 0.0;
        totalPercentage += percentage;
      }

      // Sort recent attempts by date (most recent first)
      recentAttempts.sort((a, b) => 
        (b['submittedAt'] as DateTime).compareTo(a['submittedAt'] as DateTime)
      );

      // Get total available quizzes from enrolled courses in a single query
      final enrolledCourses = await getEnrolledCourses(userId);
      final courseIds = enrolledCourses.map((c) => c.courseId).toList();
      
      int totalQuizzes = 0;
      if (courseIds.isNotEmpty) {
        final quizzesResponse = await _supabase
            .from('Quiz')
            .select('QuizId')
            .inFilter('CourseId', courseIds)
            .eq('Is_Published', true);
        
        totalQuizzes = quizzesResponse.length;
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
      if (enrolledCourses.isEmpty) {
        return {};
      }

      final courseProgress = <int, double>{};
      final courseIds = enrolledCourses.map((c) => c.courseId).toList();

      // Fetch all quizzes for all enrolled courses in one query
      final allQuizzes = await _supabase
          .from('Quiz')
          .select('QuizId, CourseId')
          .inFilter('CourseId', courseIds)
          .eq('Is_Published', true);

      // Group quizzes by course
      final quizzesByCourse = <int, List<int>>{};
      for (var quiz in allQuizzes) {
        final courseId = quiz['CourseId'] as int;
        final quizId = quiz['QuizId'] as int;
        quizzesByCourse.putIfAbsent(courseId, () => []).add(quizId);
      }

      // Get all quiz IDs
      final allQuizIds = allQuizzes.map((q) => q['QuizId'] as int).toList();

      if (allQuizIds.isEmpty) {
        // No quizzes in any course
        for (var course in enrolledCourses) {
          courseProgress[course.courseId] = 0.0;
        }
        return courseProgress;
      }

      // Fetch all completed attempts for all quizzes in one query
      final completedAttempts = await _supabase
          .from('Attempt')
          .select('QuizId')
          .eq('UserId', userId)
          .not('SubmittedAt', 'is', null)
          .inFilter('QuizId', allQuizIds);

      // Get unique completed quiz IDs
      final completedQuizIds = <int>{};
      for (var attempt in completedAttempts) {
        completedQuizIds.add(attempt['QuizId'] as int);
      }

      // Calculate progress for each course
      for (var course in enrolledCourses) {
        final courseQuizIds = quizzesByCourse[course.courseId] ?? [];
        
        if (courseQuizIds.isEmpty) {
          courseProgress[course.courseId] = 0.0;
          continue;
        }

        // Count how many quizzes in this course are completed
        final completedCount = courseQuizIds.where((id) => completedQuizIds.contains(id)).length;
        final progress = completedCount / courseQuizIds.length;

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
