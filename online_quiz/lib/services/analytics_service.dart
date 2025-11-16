import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attempt.dart';
import '../models/user.dart' as models;
import '../models/student.dart';
import '../models/enrollment.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all attempts for a specific quiz with student details
  Future<List<Map<String, dynamic>>> getAttemptsByQuiz(int quizId) async {
    try {
      final response = await _supabase
          .from('Attempt')
          .select('''
            *,
            User:UserId (
              UserId,
              FullName,
              Email
            )
          ''')
          .eq('QuizId', quizId)
          .not('SubmittedAt', 'is', null)
          .order('SubmittedAt', ascending: false);

      final attempts = <Map<String, dynamic>>[];
      for (final attemptData in response) {
        final attempt = Attempt.fromJson(attemptData);
        final userData = attemptData['User'];
        
        attempts.add({
          'attempt': attempt,
          'user': userData != null ? models.User(
            userId: userData['UserId'] as int,
            fullName: userData['FullName'] as String,
            email: userData['Email'] as String,
            passwordHash: '', // Not needed for display
            status: 'Active',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 0,
            contactNumber: '',
            emergencyContactNumber: '',
          ) : null,
        });
      }

      return attempts;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch quiz attempts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch quiz attempts: $e');
    }
  }

  /// Get detailed quiz analytics including scores, completion rates, and student performance
  Future<Map<String, dynamic>> getQuizAnalytics(int quizId) async {
    try {
      // Get quiz details and associated course
      final quizResponse = await _supabase
          .from('Quiz')
          .select('*, CourseId')
          .eq('QuizId', quizId)
          .single();

      final courseId = quizResponse['CourseId'] as int;

      // Get all attempts for this quiz
      final attemptsResponse = await _supabase
          .from('Attempt')
          .select('*')
          .eq('QuizId', quizId)
          .not('SubmittedAt', 'is', null);

      final attempts = attemptsResponse.map((a) => Attempt.fromJson(a)).toList();

      // Get total enrolled students for completion rate
      final enrollmentsResponse = await _supabase
          .from('Enrollment')
          .select('UserId')
          .eq('CourseId', courseId);

      final totalStudents = enrollmentsResponse.length;

      // Get questions to calculate total points
      final questionsResponse = await _supabase
          .from('Question')
          .select('Points')
          .eq('QuizId', quizId);

      final totalPoints = questionsResponse.fold<double>(
        0.0,
        (sum, q) => sum + (q['Points'] as num).toDouble(),
      );

      // Calculate statistics
      final completedAttempts = attempts.length;
      final uniqueStudents = attempts.map((a) => a.userId).toSet().length;
      final completionRate = totalStudents > 0 
          ? (uniqueStudents / totalStudents) * 100 
          : 0.0;

      double averageScore = 0.0;
      double averagePercentage = 0.0;
      double highestScore = 0.0;
      double lowestScore = totalPoints;
      int totalTimeSpent = 0;

      if (attempts.isNotEmpty) {
        averageScore = attempts.fold<double>(0, (sum, a) => sum + a.score) / attempts.length;
        averagePercentage = totalPoints > 0 ? (averageScore / totalPoints) * 100 : 0.0;
        
        for (final attempt in attempts) {
          if (attempt.score > highestScore) highestScore = attempt.score;
          if (attempt.score < lowestScore) lowestScore = attempt.score;
          if (attempt.timeSpentSeconds != null) {
            totalTimeSpent += attempt.timeSpentSeconds!;
          }
        }
      }

      final averageTimeSpent = attempts.isNotEmpty && totalTimeSpent > 0
          ? totalTimeSpent ~/ attempts.length
          : 0;

      return {
        'totalPoints': totalPoints,
        'totalStudents': totalStudents,
        'completedAttempts': completedAttempts,
        'uniqueStudents': uniqueStudents,
        'completionRate': completionRate,
        'averageScore': averageScore,
        'averagePercentage': averagePercentage,
        'highestScore': highestScore,
        'lowestScore': lowestScore == totalPoints ? 0.0 : lowestScore,
        'averageTimeSpent': averageTimeSpent,
        'attempts': attempts,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch quiz analytics: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch quiz analytics: $e');
    }
  }

  /// Get course statistics including completion rates and performance metrics
  Future<Map<String, dynamic>> getCourseStatistics(int courseId) async {
    try {
      // Get all quizzes for the course
      final quizzesResponse = await _supabase
          .from('Quiz')
          .select('QuizId, Title, Is_Published')
          .eq('CourseId', courseId);

      final totalQuizzes = quizzesResponse.length;
      final publishedQuizzes = quizzesResponse.where((q) => q['Is_Published'] == true).length;
      final quizIds = quizzesResponse.map((q) => q['QuizId'] as int).toList();

      // Get all enrollments for the course
      final enrollmentsResponse = await _supabase
          .from('Enrollment')
          .select('UserId')
          .eq('CourseId', courseId);

      final totalStudents = enrollmentsResponse.length;

      if (quizIds.isEmpty) {
        return {
          'totalQuizzes': totalQuizzes,
          'publishedQuizzes': publishedQuizzes,
          'totalStudents': totalStudents,
          'totalAttempts': 0,
          'averageScore': 0.0,
          'completionRate': 0.0,
          'activeStudents': 0,
        };
      }

      // Get all attempts for course quizzes
      final attemptsResponse = await _supabase
          .from('Attempt')
          .select('*')
          .inFilter('QuizId', quizIds)
          .not('SubmittedAt', 'is', null);

      final totalAttempts = attemptsResponse.length;
      final activeStudents = attemptsResponse.map((a) => a['UserId']).toSet().length;

      // Calculate average score and completion rate
      double totalScore = 0.0;
      int scoredAttempts = 0;

      for (final attempt in attemptsResponse) {
        if (attempt['Score'] != null) {
          totalScore += (attempt['Score'] as num).toDouble();
          scoredAttempts++;
        }
      }

      final averageScore = scoredAttempts > 0 ? totalScore / scoredAttempts : 0.0;
      final completionRate = totalStudents > 0 && publishedQuizzes > 0
          ? (activeStudents / totalStudents) * 100
          : 0.0;

      return {
        'totalQuizzes': totalQuizzes,
        'publishedQuizzes': publishedQuizzes,
        'totalStudents': totalStudents,
        'totalAttempts': totalAttempts,
        'averageScore': averageScore,
        'completionRate': completionRate,
        'activeStudents': activeStudents,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch course statistics: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch course statistics: $e');
    }
  }

  /// Get student quiz results with enrollment and section information
  Future<List<Map<String, dynamic>>> getStudentQuizResults(int quizId, int courseId) async {
    try {
      // Get all enrollments for the course
      final enrollmentsResponse = await _supabase
          .from('Enrollment')
          .select('''
            *,
            User:UserId (
              UserId,
              FullName,
              Email
            )
          ''')
          .eq('CourseId', courseId);

      final results = <Map<String, dynamic>>[];

      for (final enrollmentData in enrollmentsResponse) {
        final userId = enrollmentData['UserId'] as int;
        final userData = enrollmentData['User'];

        // Get student details
        final studentResponse = await _supabase
            .from('Student')
            .select('*')
            .eq('UserId', userId)
            .maybeSingle();

        Student? student;
        if (studentResponse != null) {
          student = Student.fromJson(studentResponse);
        }

        // Get user's attempts for this quiz
        final attemptsResponse = await _supabase
            .from('Attempt')
            .select('*')
            .eq('QuizId', quizId)
            .eq('UserId', userId)
            .not('SubmittedAt', 'is', null)
            .order('SubmittedAt', ascending: false);

        final attempts = attemptsResponse.map((a) => Attempt.fromJson(a)).toList();

        // Get best attempt
        Attempt? bestAttempt;
        if (attempts.isNotEmpty) {
          bestAttempt = attempts.reduce((a, b) => a.score > b.score ? a : b);
        }

        results.add({
          'enrollment': Enrollment.fromJson(enrollmentData),
          'user': userData != null ? models.User(
            userId: userData['UserId'] as int,
            fullName: userData['FullName'] as String,
            email: userData['Email'] as String,
            passwordHash: '',
            status: 'Active',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 0,
            contactNumber: '',
            emergencyContactNumber: '',
          ) : null,
          'student': student,
          'attempts': attempts,
          'bestAttempt': bestAttempt,
          'totalAttempts': attempts.length,
        });
      }

      return results;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch student quiz results: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch student quiz results: $e');
    }
  }

  /// Get quiz sections (unique student sections enrolled in the course)
  Future<List<String>> getQuizSections(int courseId) async {
    try {
      // Get all enrollments for the course
      final enrollmentsResponse = await _supabase
          .from('Enrollment')
          .select('UserId')
          .eq('CourseId', courseId);

      final userIds = enrollmentsResponse.map((e) => e['UserId'] as int).toList();

      if (userIds.isEmpty) {
        return [];
      }

      // Get unique sections from students
      final studentsResponse = await _supabase
          .from('Student')
          .select('Section')
          .inFilter('UserId', userIds);

      final sections = <String>{};
      for (final student in studentsResponse) {
        final section = student['Section'] as String?;
        if (section != null && section.isNotEmpty) {
          sections.add(section);
        }
      }

      final sortedSections = sections.toList()..sort();
      return sortedSections;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch quiz sections: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch quiz sections: $e');
    }
  }

  /// Get detailed attempt information with questions and answers
  Future<Map<String, dynamic>> getAttemptDetails(int attemptId) async {
    try {
      // Get attempt
      final attemptResponse = await _supabase
          .from('Attempt')
          .select('*')
          .eq('AttemptId', attemptId)
          .single();

      final attempt = Attempt.fromJson(attemptResponse);

      // Get attempt answers with questions
      final answersResponse = await _supabase
          .from('AttemptAnswer')
          .select('''
            *,
            Question:QuestionId (
              QuestionId,
              QuestionText,
              QuestionType,
              Points
            )
          ''')
          .eq('AttemptId', attemptId);

      return {
        'attempt': attempt,
        'answers': answersResponse,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch attempt details: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch attempt details: $e');
    }
  }

  /// Get performance trends over time for a quiz
  Future<List<Map<String, dynamic>>> getQuizPerformanceTrends(int quizId, {int? limit}) async {
    try {
      var query = _supabase
          .from('Attempt')
          .select('Score, SubmittedAt, UserId')
          .eq('QuizId', quizId)
          .not('SubmittedAt', 'is', null)
          .order('SubmittedAt', ascending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return response.map<Map<String, dynamic>>((attempt) => {
        'score': (attempt['Score'] as num).toDouble(),
        'submittedAt': DateTime.parse(attempt['SubmittedAt'] as String),
        'userId': attempt['UserId'] as int,
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch quiz performance trends: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch quiz performance trends: $e');
    }
  }

  /// Get comparative analytics across multiple quizzes
  Future<List<Map<String, dynamic>>> getComparativeQuizAnalytics(List<int> quizIds) async {
    try {
      final analytics = <Map<String, dynamic>>[];

      for (final quizId in quizIds) {
        final quizAnalytics = await getQuizAnalytics(quizId);
        
        // Get quiz title
        final quizResponse = await _supabase
            .from('Quiz')
            .select('Title')
            .eq('QuizId', quizId)
            .single();

        analytics.add({
          'quizId': quizId,
          'title': quizResponse['Title'],
          'analytics': quizAnalytics,
        });
      }

      return analytics;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch comparative analytics: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch comparative analytics: $e');
    }
  }
}
