import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get system-wide statistics for admin dashboard
  Future<Map<String, int>> getSystemStatistics() async {
    try {
      // Get total users count
      final usersResponse = await _supabase
          .from('User')
          .select('UserId');
      final totalUsers = usersResponse.length;

      // Get total courses count
      final coursesResponse = await _supabase
          .from('Course')
          .select('CourseId');
      final totalCourses = coursesResponse.length;

      // Get total quizzes count
      final quizzesResponse = await _supabase
          .from('Quiz')
          .select('QuizId');
      final totalQuizzes = quizzesResponse.length;

      // Get total attempts count
      final attemptsResponse = await _supabase
          .from('Attempt')
          .select('AttemptId');
      final totalAttempts = attemptsResponse.length;

      // Get active students count (students with at least one enrollment)
      final enrollmentsData = await _supabase
          .from('Enrollment')
          .select('UserId');
      final uniqueStudentIds = <int>{};
      for (final enrollment in enrollmentsData) {
        uniqueStudentIds.add(enrollment['UserId'] as int);
      }
      final activeStudents = uniqueStudentIds.length;

      // Get active teachers count (teachers assigned to at least one course)
      final coursesData = await _supabase
          .from('Course')
          .select('Instructor_UserId');
      final uniqueTeacherIds = <int>{};
      for (final course in coursesData) {
        final instructorId = course['Instructor_UserId'];
        if (instructorId != null) {
          uniqueTeacherIds.add(instructorId as int);
        }
      }
      final activeTeachers = uniqueTeacherIds.length;

      return {
        'totalUsers': totalUsers,
        'totalCourses': totalCourses,
        'totalQuizzes': totalQuizzes,
        'totalAttempts': totalAttempts,
        'activeStudents': activeStudents,
        'activeTeachers': activeTeachers,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch system statistics: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch system statistics: $e');
    }
  }

  /// Get recent activity across the system
  Future<Map<String, dynamic>> getRecentActivity() async {
    try {
      // Get recent quiz attempts using the "QuizAttemptSummary" VIEW
      // This view already joins Attempt -> Student -> User
      final attemptsData = await _supabase
          .from('QuizAttemptSummary')
          .select('*')
          .order('SubmittedAt', ascending: false)
          .limit(10);

      // Get recently created courses using the "ActiveCoursesWithInstructor" VIEW
      // This view correctly joins Course -> Teacher -> User
      final coursesData = await _supabase
          .from('ActiveCoursesWithInstructor')
          .select('*')
          .order('CreatedAt', ascending: false)
          .limit(5);

      // Get recently created quizzes (last 5) with course details
      final recentQuizzes = await _supabase
          .from('Quiz')
          .select('*, Course:CourseId (Name, Code)')
          .order('CreatedAt', ascending: false)
          .limit(5);

      return {
        'recentAttempts': attemptsData,
        'recentCourses': coursesData,
        'recentQuizzes': recentQuizzes,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch recent activity: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch recent activity: $e');
    }
  }

  /// Get system health metrics
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      // Get completion rate (submitted attempts / total attempts)
      final totalAttempts = await _supabase
          .from('Attempt')
          .select('AttemptId');
      
      final submittedAttempts = await _supabase
          .from('Attempt')
          .select('AttemptId')
          .not('SubmittedAt', 'is', null);

      final totalCount = totalAttempts.length;
      final submittedCount = submittedAttempts.length;
      final completionRate = totalCount > 0 ? (submittedCount / totalCount * 100).round() : 0;

      // Get average quiz score
      final attempts = await _supabase
          .from('Attempt')
          .select('Score')
          .not('SubmittedAt', 'is', null);
      
      double totalScore = 0;
      int validAttempts = 0;
      for (final attempt in attempts) {
        final score = attempt['Score'];
        if (score != null) {
          totalScore += (score as num).toDouble();
          validAttempts++;
        }
      }
      final averageScore = validAttempts > 0 ? (totalScore / validAttempts).round() : 0;

      // Get active courses (status = 'Active')
      final activeCourses = await _supabase
          .from('Course')
          .select('CourseId')
          .eq('Status', 'Active');

      // Get published quizzes
      final publishedQuizzes = await _supabase
          .from('Quiz')
          .select('QuizId')
          .eq('Is_Published', true);

      return {
        'completionRate': completionRate,
        'averageScore': averageScore,
        'activeCourses': activeCourses.length,
        'publishedQuizzes': publishedQuizzes.length,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch system health: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch system health: $e');
    }
  }
}
