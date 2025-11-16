import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/quiz.dart';
import '../models/user.dart' as app_user;

class CourseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all courses a student is enrolled in
  Future<List<Course>> getEnrolledCourses(int userId) async {
    try {
      final response = await _supabase
          .from('Enrollment')
          .select('''
            *,
            Course:CourseId (*)
          ''')
          .eq('UserId', userId);

      final List<Course> courses = [];
      for (final enrollment in response) {
        if (enrollment['Course'] != null) {
          final courseData = enrollment['Course'];
          
          courses.add(Course(
            courseId: courseData['CourseId'],
            code: courseData['Code'],
            name: courseData['Name'],
            instructorUserId: courseData['Instructor_UserId'],
            status: courseData['Status'] ?? 'Active',
            category: courseData['Category'],
            section: courseData['Section'],
            createdAt: DateTime.parse(courseData['CreatedAt']),
            updatedAt: DateTime.parse(courseData['UpdatedAt']),
            createdBy: courseData['CreatedBy'],
          ));
        }
      }

      return courses;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch enrolled courses: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch enrolled courses: $e');
    }
  }

  // Get course details by ID
  Future<Course?> getCourseById(int courseId) async {
    try {
      final response = await _supabase
          .from('Course')
          .select('*')
          .eq('CourseId', courseId)
          .maybeSingle();

      if (response == null) return null;

      return Course(
        courseId: response['CourseId'],
        code: response['Code'],
        name: response['Name'],
        instructorUserId: response['Instructor_UserId'],
        status: response['Status'] ?? 'Active',
        category: response['Category'],
        section: response['Section'],
        createdAt: DateTime.parse(response['CreatedAt']),
        updatedAt: DateTime.parse(response['UpdatedAt']),
        createdBy: response['CreatedBy'],
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch course: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch course: $e');
    }
  }

  // Get instructor details for a course
  Future<app_user.User?> getCourseInstructor(int instructorUserId) async {
    try {
      final response = await _supabase
          .from('User')
          .select('*')
          .eq('UserId', instructorUserId)
          .maybeSingle();

      if (response == null) return null;

      return app_user.User.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch instructor: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch instructor: $e');
    }
  }

  // Get all quizzes for a course
  Future<List<Quiz>> getCourseQuizzes(int courseId) async {
    try {
      final response = await _supabase
          .from('Quiz')
          .select('*')
          .eq('CourseId', courseId)
          .eq('Is_Published', true)
          .order('CreatedAt', ascending: false);

      final List<Quiz> quizzes = [];
      for (final quizData in response) {
        quizzes.add(Quiz(
          quizId: quizData['QuizId'],
          courseId: quizData['CourseId'],
          title: quizData['Title'],
          dueAt: quizData['Due_At'] != null ? DateTime.parse(quizData['Due_At']) : null,
          timeLimitMinutes: quizData['Time_Limit_Minutes'],
          isPublished: quizData['Is_Published'] ?? false,
          createdAt: DateTime.parse(quizData['CreatedAt']),
          updatedAt: DateTime.parse(quizData['UpdatedAt']),
          createdBy: quizData['CreatedBy'],
        ));
      }

      return quizzes;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch course quizzes: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch course quizzes: $e');
    }
  }

  // Get course progress for a student (completed quizzes / total quizzes)
  Future<Map<int, double>> getCourseProgress(int userId, List<int> courseIds) async {
    try {
      final Map<int, double> courseProgress = {};

      for (final courseId in courseIds) {
        // Get all published quizzes for the course
        final quizzes = await getCourseQuizzes(courseId);
        final totalQuizzes = quizzes.length;

        if (totalQuizzes == 0) {
          courseProgress[courseId] = 0.0;
          continue;
        }

        // Get submitted attempts for this user's quizzes in this course
        final quizIds = quizzes.map((q) => q.quizId).toList();
        
        final attemptsResponse = await _supabase
            .from('Attempt')
            .select('QuizId')
            .eq('UserId', userId)
            .inFilter('QuizId', quizIds)
            .not('SubmittedAt', 'is', null);

        // Count unique quizzes that have been completed
        final completedQuizIds = <int>{};
        for (final attempt in attemptsResponse) {
          completedQuizIds.add(attempt['QuizId']);
        }

        final progress = completedQuizIds.length / totalQuizzes;
        courseProgress[courseId] = progress;
      }

      return courseProgress;
    } on PostgrestException catch (e) {
      throw Exception('Failed to calculate course progress: ${e.message}');
    } catch (e) {
      throw Exception('Failed to calculate course progress: $e');
    }
  }

  // Get quiz counts for courses (total and completed)
  Future<Map<String, Map<int, int>>> getQuizCounts(int userId, List<int> courseIds) async {
    try {
      final Map<int, int> totalCounts = {};
      final Map<int, int> completedCounts = {};

      for (final courseId in courseIds) {
        // Get all published quizzes for the course
        final quizzes = await getCourseQuizzes(courseId);
        totalCounts[courseId] = quizzes.length;

        if (quizzes.isEmpty) {
          completedCounts[courseId] = 0;
          continue;
        }

        // Get submitted attempts for this user
        final quizIds = quizzes.map((q) => q.quizId).toList();
        
        final attemptsResponse = await _supabase
            .from('Attempt')
            .select('QuizId')
            .eq('UserId', userId)
            .inFilter('QuizId', quizIds)
            .not('SubmittedAt', 'is', null);

        // Count unique completed quizzes
        final completedQuizIds = <int>{};
        for (final attempt in attemptsResponse) {
          completedQuizIds.add(attempt['QuizId']);
        }

        completedCounts[courseId] = completedQuizIds.length;
      }

      return {
        'total': totalCounts,
        'completed': completedCounts,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to get quiz counts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get quiz counts: $e');
    }
  }

  // Get enrollment details for a user and course
  Future<Enrollment?> getEnrollment(int userId, int courseId) async {
    try {
      final response = await _supabase
          .from('Enrollment')
          .select('*')
          .eq('UserId', userId)
          .eq('CourseId', courseId)
          .maybeSingle();

      if (response == null) return null;

      return Enrollment(
        enrollmentId: response['EnrollmentId'],
        userId: response['UserId'],
        courseId: response['CourseId'],
        enrolledAt: DateTime.parse(response['EnrolledAt']),
        enrolledBy: response['EnrolledBy'],
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch enrollment: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch enrollment: $e');
    }
  }

  // Check if user is enrolled in a course
  Future<bool> isEnrolled(int userId, int courseId) async {
    try {
      final enrollment = await getEnrollment(userId, courseId);
      return enrollment != null;
    } catch (e) {
      return false;
    }
  }

  // Get all enrollments for a user
  Future<List<Enrollment>> getUserEnrollments(int userId) async {
    try {
      final response = await _supabase
          .from('Enrollment')
          .select('*')
          .eq('UserId', userId)
          .order('EnrolledAt', ascending: false);

      final List<Enrollment> enrollments = [];
      for (final data in response) {
        enrollments.add(Enrollment(
          enrollmentId: data['EnrollmentId'],
          userId: data['UserId'],
          courseId: data['CourseId'],
          enrolledAt: DateTime.parse(data['EnrolledAt']),
          enrolledBy: data['EnrolledBy'],
        ));
      }

      return enrollments;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch enrollments: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch enrollments: $e');
    }
  }

  // Get all courses (for admin/teacher view)
  Future<List<Course>> getAllCourses() async {
    try {
      final response = await _supabase
          .from('Course')
          .select('*')
          .order('CreatedAt', ascending: false);

      final List<Course> courses = [];
      for (final courseData in response) {
        courses.add(Course(
          courseId: courseData['CourseId'],
          code: courseData['Code'],
          name: courseData['Name'],
          instructorUserId: courseData['Instructor_UserId'],
          status: courseData['Status'] ?? 'Active',
          category: courseData['Category'],
          section: courseData['Section'],
          createdAt: DateTime.parse(courseData['CreatedAt']),
          updatedAt: DateTime.parse(courseData['UpdatedAt']),
          createdBy: courseData['CreatedBy'],
        ));
      }

      return courses;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch all courses: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch all courses: $e');
    }
  }

  // Get courses taught by a specific instructor
  Future<List<Course>> getCoursesByInstructor(int instructorUserId) async {
    try {
      final response = await _supabase
          .from('Course')
          .select('*')
          .eq('Instructor_UserId', instructorUserId)
          .order('CreatedAt', ascending: false);

      final List<Course> courses = [];
      for (final courseData in response) {
        courses.add(Course(
          courseId: courseData['CourseId'],
          code: courseData['Code'],
          name: courseData['Name'],
          instructorUserId: courseData['Instructor_UserId'],
          status: courseData['Status'] ?? 'Active',
          category: courseData['Category'],
          section: courseData['Section'],
          createdAt: DateTime.parse(courseData['CreatedAt']),
          updatedAt: DateTime.parse(courseData['UpdatedAt']),
          createdBy: courseData['CreatedBy'],
        ));
      }

      return courses;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch instructor courses: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch instructor courses: $e');
    }
  }

  // Get students enrolled in a course (for teacher view)
  Future<List<Map<String, dynamic>>> getEnrolledStudents(int courseId) async {
    try {
      final response = await _supabase
          .from('Enrollment')
          .select('''
            *,
            User:UserId (
              UserId,
              FullName,
              Email,
              ContactNumber,
              Status
            ),
            Student:UserId (
              StudentId,
              UserId,
              Year_Level,
              Section,
              Course
            )
          ''')
          .eq('CourseId', courseId)
          .order('EnrolledAt', ascending: false);

      final List<Map<String, dynamic>> students = [];
      for (final enrollment in response) {
        if (enrollment['User'] != null) {
          students.add({
            'user': app_user.User.fromJson(enrollment['User']),
            'student': enrollment['Student'],
            'enrollment': Enrollment(
              enrollmentId: enrollment['EnrollmentId'],
              userId: enrollment['UserId'],
              courseId: enrollment['CourseId'],
              enrolledAt: DateTime.parse(enrollment['EnrolledAt']),
              enrolledBy: enrollment['EnrolledBy'],
            ),
          });
        }
      }

      return students;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch enrolled students: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch enrolled students: $e');
    }
  }
}
