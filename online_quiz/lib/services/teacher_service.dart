import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teacher.dart';

class TeacherService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get teacher details by user ID
  Future<Teacher?> getTeacherByUserId(int userId) async {
    try {
      final response = await _supabase
          .from('Teacher')
          .select('*')
          .eq('UserId', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Teacher.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch teacher: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch teacher: $e');
    }
  }

  /// Get teacher statistics including courses, quizzes, and students
  Future<Map<String, dynamic>> getTeacherStatistics(int userId) async {
    try {
      // Get teacher's courses
      final coursesResponse = await _supabase
          .from('Course')
          .select('CourseId')
          .eq('Instructor_UserId', userId);

      final List<int> courseIds = coursesResponse.map((c) => c['CourseId'] as int).toList();

      if (courseIds.isEmpty) {
        return {
          'totalCourses': 0,
          'totalQuizzes': 0,
          'totalStudents': 0,
          'totalAttempts': 0,
          'averageScore': 0.0,
        };
      }

      // Get total quizzes count
      final quizzesResponse = await _supabase
          .from('Quiz')
          .select('QuizId')
          .inFilter('CourseId', courseIds);

      final totalQuizzes = quizzesResponse.length;

      // Get total students (unique enrollments across all courses)
      final enrollmentsResponse = await _supabase
          .from('Enrollment')
          .select('UserId')
          .inFilter('CourseId', courseIds);

      final uniqueStudents = <int>{};
      for (final enrollment in enrollmentsResponse) {
        uniqueStudents.add(enrollment['UserId'] as int);
      }

      // Get quiz IDs for attempts
      final quizIds = quizzesResponse.map((q) => q['QuizId'] as int).toList();

      int totalAttempts = 0;
      double totalScore = 0.0;
      int scoredAttempts = 0;

      if (quizIds.isNotEmpty) {
        // Get all attempts for teacher's quizzes
        final attemptsResponse = await _supabase
            .from('Attempt')
            .select('Score')
            .inFilter('QuizId', quizIds)
            .not('SubmittedAt', 'is', null);

        totalAttempts = attemptsResponse.length;

        for (final attempt in attemptsResponse) {
          if (attempt['Score'] != null) {
            totalScore += (attempt['Score'] as num).toDouble();
            scoredAttempts++;
          }
        }
      }

      final averageScore = scoredAttempts > 0 ? totalScore / scoredAttempts : 0.0;

      return {
        'totalCourses': courseIds.length,
        'totalQuizzes': totalQuizzes,
        'totalStudents': uniqueStudents.length,
        'totalAttempts': totalAttempts,
        'averageScore': averageScore,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch teacher statistics: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch teacher statistics: $e');
    }
  }

  /// Get teacher with user details
  Future<Map<String, dynamic>?> getTeacherWithUser(int userId) async {
    try {
      // First get teacher data
      final teacherResponse = await _supabase
          .from('Teacher')
          .select('UserId, Department')
          .eq('UserId', userId)
          .maybeSingle();

      if (teacherResponse == null) {
        return null;
      }

      // Then get user data
      final userResponse = await _supabase
          .from('User')
          .select('UserId, FullName, Email, ContactNumber, EmergencyContactNumber, Status, CreatedAt, UpdatedAt, CreatedBy')
          .eq('UserId', userId)
          .maybeSingle();

      if (userResponse == null) {
        return null;
      }

      // Return flat map with all data
      return {
        'UserId': teacherResponse['UserId'],
        'Department': teacherResponse['Department'],
        'FullName': userResponse['FullName'],
        'Email': userResponse['Email'],
        'ContactNumber': userResponse['ContactNumber'],
        'EmergencyContactNumber': userResponse['EmergencyContactNumber'],
        'Status': userResponse['Status'],
        'CreatedAt': userResponse['CreatedAt'],
        'UpdatedAt': userResponse['UpdatedAt'],
        'CreatedBy': userResponse['CreatedBy'],
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch teacher with user: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch teacher with user: $e');
    }
  }

  /// Get recent activity for teacher (recent quiz attempts)
  Future<List<Map<String, dynamic>>> getRecentActivity(int userId, {int limit = 10}) async {
    try {
      // First get teacher's course IDs
      final coursesResponse = await _supabase
          .from('Course')
          .select('CourseId')
          .eq('Instructor_UserId', userId);

      final List<int> courseIds = coursesResponse.map((c) => c['CourseId'] as int).toList();

      if (courseIds.isEmpty) {
        return [];
      }

      // Get quiz IDs for those courses
      final quizzesResponse = await _supabase
          .from('Quiz')
          .select('QuizId, Title, CourseId')
          .inFilter('CourseId', courseIds);

      final Map<int, Map<String, dynamic>> quizMap = {};
      final List<int> quizIds = [];
      
      for (final quiz in quizzesResponse) {
        final quizId = quiz['QuizId'] as int;
        quizIds.add(quizId);
        quizMap[quizId] = {
          'quizId': quizId,
          'title': quiz['Title'],
          'courseId': quiz['CourseId'],
        };
      }

      if (quizIds.isEmpty) {
        return [];
      }

      // Get recent attempts
      final attemptsResponse = await _supabase
          .from('Attempt')
          .select('''
            *,
            User:UserId (
              UserId,
              FullName
            )
          ''')
          .inFilter('QuizId', quizIds)
          .not('SubmittedAt', 'is', null)
          .order('SubmittedAt', ascending: false)
          .limit(limit);

      final activities = <Map<String, dynamic>>[];
      for (final attempt in attemptsResponse) {
        final quizId = attempt['QuizId'] as int;
        final quizInfo = quizMap[quizId];
        
        activities.add({
          'attemptId': attempt['AttemptId'],
          'quizId': quizId,
          'quizTitle': quizInfo?['title'] ?? 'Unknown Quiz',
          'courseId': quizInfo?['courseId'],
          'userId': attempt['UserId'],
          'studentName': attempt['User']?['FullName'] ?? 'Unknown Student',
          'score': attempt['Score'],
          'submittedAt': attempt['SubmittedAt'] != null 
              ? DateTime.parse(attempt['SubmittedAt']) 
              : null,
        });
      }

      return activities;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch recent activity: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch recent activity: $e');
    }
  }

  /// Get course performance summary
  Future<Map<String, dynamic>> getCoursePerformance(int courseId) async {
    try {
      // Get course quizzes
      final quizzesResponse = await _supabase
          .from('Quiz')
          .select('QuizId, Title, Is_Published')
          .eq('CourseId', courseId);

      if (quizzesResponse.isEmpty) {
        return {
          'totalQuizzes': 0,
          'publishedQuizzes': 0,
          'totalAttempts': 0,
          'averageScore': 0.0,
          'completionRate': 0.0,
        };
      }

      final quizIds = quizzesResponse.map((q) => q['QuizId'] as int).toList();
      final publishedQuizzes = quizzesResponse.where((q) => q['Is_Published'] == true).length;

      // Get enrollment count
      final enrollmentsResponse = await _supabase
          .from('Enrollment')
          .select('UserId')
          .eq('CourseId', courseId);

      final totalStudents = enrollmentsResponse.length;

      // Get attempts
      final attemptsResponse = await _supabase
          .from('QuizSubmission')
          .select('SubmissionId, QuizId, TotalScore')
          .inFilter('QuizId', quizIds)
          .not('SubmittedAt', 'is', null);

      final totalAttempts = attemptsResponse.length;
      double totalScore = 0.0;
      int scoredAttempts = 0;

      for (final attempt in attemptsResponse) {
        if (attempt['TotalScore'] != null) {
          totalScore += (attempt['TotalScore'] as num).toDouble();
          scoredAttempts++;
        }
      }

      final averageScore = scoredAttempts > 0 ? totalScore / scoredAttempts : 0.0;
      
      // Calculate completion rate based on completed attempts
      final completedAttempts = attemptsResponse.where((a) => a['SubmittedAt'] != null).length;
      final completionRate = totalAttempts > 0 
          ? (completedAttempts / totalAttempts) * 100 
          : 0.0;

      return {
        'totalQuizzes': quizzesResponse.length,
        'publishedQuizzes': publishedQuizzes,
        'totalAttempts': totalAttempts,
        'averageScore': averageScore,
        'completionRate': completionRate,
        'totalStudents': totalStudents,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch course performance: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch course performance: $e');
    }
  }
}
