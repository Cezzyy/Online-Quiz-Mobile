import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/quiz.dart';
import '../models/user.dart' as app_user;
import '../models/activity_log.dart';
import 'activity_log_service.dart';

class CourseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ActivityLogService _activityLog = ActivityLogService();

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

  /// Create a new course (Admin only)
  /// Multiple courses with same code can exist if assigned to different teachers/sections
  Future<Course> createCourse({
    required String code,
    required String name,
    required int instructorUserId,
    String? category,
    String? section,
    required String status,
    required int createdBy,
  }) async {
    try {
      final response = await _supabase
          .from('Course')
          .insert({
            'Code': code,
            'Name': name,
            'Instructor_UserId': instructorUserId,
            'Status': status,
            'Category': category,
            'Section': section,
            'CreatedBy': createdBy,
          })
          .select()
          .single();

      final course = Course(
        courseId: response['CourseId'],
        code: response['Code'],
        name: response['Name'],
        instructorUserId: response['Instructor_UserId'],
        status: response['Status'],
        category: response['Category'],
        section: response['Section'],
        createdAt: DateTime.parse(response['CreatedAt']),
        updatedAt: DateTime.parse(response['UpdatedAt']),
        createdBy: response['CreatedBy'],
      );

      // Log course creation
      try {
        await _activityLog.logActivity(
          userId: createdBy,
          action: ActivityAction.create,
          entity: EntityType.course,
          entityId: course.courseId,
          description: 'Created course "${course.name}" (${course.code})',
          newValues: {'name': course.name, 'code': course.code, 'section': course.section},
        );
      } catch (e) {
        debugPrint('Failed to log course creation: $e');
      }

      return course;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create course: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  /// Update an existing course (Admin only)
  Future<void> updateCourse({
    required int courseId,
    required String code,
    required String name,
    required int instructorUserId,
    String? category,
    String? section,
    required String status,
    int? updatedBy,
  }) async {
    try {
      // Get old values
      final oldCourse = await getCourseById(courseId);
      
      await _supabase
          .from('Course')
          .update({
            'Code': code,
            'Name': name,
            'Instructor_UserId': instructorUserId,
            'Status': status,
            'Category': category,
            'Section': section,
            'UpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('CourseId', courseId);

      // Log course update
      if (updatedBy != null) {
        try {
          await _activityLog.logActivity(
            userId: updatedBy,
            action: ActivityAction.update,
            entity: EntityType.course,
            entityId: courseId,
            description: 'Updated course "$name"',
            oldValues: oldCourse != null ? {'name': oldCourse.name, 'code': oldCourse.code} : null,
            newValues: {'name': name, 'code': code, 'status': status},
          );
        } catch (e) {
          debugPrint('Failed to log course update: $e');
        }
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to update course: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  /// Delete a course (Admin only)
  /// Note: This will cascade delete all enrollments and quizzes
  Future<void> deleteCourse(int courseId, {int? deletedBy}) async {
    try {
      // Get course details before deletion
      final course = await getCourseById(courseId);
      
      await _supabase
          .from('Course')
          .delete()
          .eq('CourseId', courseId);

      // Log course deletion
      if (deletedBy != null && course != null) {
        try {
          await _activityLog.logActivity(
            userId: deletedBy,
            action: ActivityAction.delete,
            entity: EntityType.course,
            entityId: courseId,
            description: 'Deleted course "${course.name}" (${course.code})',
            oldValues: {'name': course.name, 'code': course.code},
          );
        } catch (e) {
          debugPrint('Failed to log course deletion: $e');
        }
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete course: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  /// Get all teachers (users with Teacher role) for course assignment
  Future<List<app_user.User>> getAllTeachers() async {
    try {
      final response = await _supabase
          .from('Teacher')
          .select('''
            *,
            User!inner(*)
          ''')
          .order('UserId', ascending: false);

      final List<app_user.User> teachers = [];
      for (final teacherData in response) {
        if (teacherData['User'] != null) {
          teachers.add(app_user.User.fromJson(teacherData['User']));
        }
      }

      return teachers;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch teachers: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch teachers: $e');
    }
  }

  /// Get available students not enrolled in a specific course
  Future<List<Map<String, dynamic>>> getAvailableStudents(int courseId) async {
    try {
      // Get all students
      final allStudentsResponse = await _supabase
          .from('Student')
          .select('''
            *,
            User!inner(*)
          ''')
          .order('UserId', ascending: false);

      // Get enrolled students in this course
      final enrolledResponse = await _supabase
          .from('Enrollment')
          .select('UserId')
          .eq('CourseId', courseId);

      final enrolledUserIds = enrolledResponse.map((e) => e['UserId'] as int).toSet();

      final List<Map<String, dynamic>> availableStudents = [];
      for (final studentData in allStudentsResponse) {
        final userId = studentData['UserId'] as int;
        if (!enrolledUserIds.contains(userId) && studentData['User'] != null) {
          availableStudents.add({
            'user': app_user.User.fromJson(studentData['User']),
            'studentId': studentData['StudentId'],
            'yearLevel': studentData['Year_Level'],
            'section': studentData['Section'],
            'course': studentData['Course'],
          });
        }
      }

      return availableStudents;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch available students: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch available students: $e');
    }
  }

  /// Enroll a student in a course (Admin or Teacher)
  Future<Enrollment> enrollStudent({
    required int userId,
    required int courseId,
    String? section,
    required int enrolledBy,
  }) async {
    try {
      final response = await _supabase
          .from('Enrollment')
          .insert({
            'UserId': userId,
            'CourseId': courseId,
            'Section': section,
            'EnrolledBy': enrolledBy,
          })
          .select()
          .single();

      final enrollment = Enrollment(
        enrollmentId: response['EnrollmentId'],
        userId: response['UserId'],
        courseId: response['CourseId'],
        section: response['Section'],
        enrolledAt: DateTime.parse(response['EnrolledAt']),
        enrolledBy: response['EnrolledBy'],
      );

      // Log enrollment
      try {
        await _activityLog.logEnrollment(
          userId: enrolledBy,
          courseId: courseId,
          enrollmentId: enrollment.enrollmentId,
        );
      } catch (e) {
        debugPrint('Failed to log enrollment: $e');
      }

      return enrollment;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Student is already enrolled in this course');
      }
      throw Exception('Failed to enroll student: ${e.message}');
    } catch (e) {
      throw Exception('Failed to enroll student: $e');
    }
  }

  /// Remove a student from a course (Admin or Teacher)
  Future<void> removeEnrollment(int enrollmentId, {int? removedBy}) async {
    try {
      // Get enrollment details before deletion
      final enrollmentResponse = await _supabase
          .from('Enrollment')
          .select()
          .eq('EnrollmentId', enrollmentId)
          .maybeSingle();

      await _supabase
          .from('Enrollment')
          .delete()
          .eq('EnrollmentId', enrollmentId);

      // Log unenrollment
      if (removedBy != null && enrollmentResponse != null) {
        try {
          await _activityLog.logActivity(
            userId: removedBy,
            action: ActivityAction.unenroll,
            entity: EntityType.enrollment,
            entityId: enrollmentId,
            description: 'Removed student from course',
            oldValues: {'courseId': enrollmentResponse['CourseId'], 'userId': enrollmentResponse['UserId']},
          );
        } catch (e) {
          debugPrint('Failed to log unenrollment: $e');
        }
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to remove enrollment: ${e.message}');
    } catch (e) {
      throw Exception('Failed to remove enrollment: $e');
    }
  }

  /// Get all courses grouped by code (for admin view showing multiple sections)
  Future<Map<String, List<Course>>> getAllCoursesGrouped() async {
    try {
      final courses = await getAllCourses();
      
      final Map<String, List<Course>> groupedCourses = {};
      for (final course in courses) {
        if (!groupedCourses.containsKey(course.code)) {
          groupedCourses[course.code] = [];
        }
        groupedCourses[course.code]!.add(course);
      }

      return groupedCourses;
    } catch (e) {
      throw Exception('Failed to fetch grouped courses: $e');
    }
  }

  /// Get all available sections from the Student table
  Future<List<String>> getAvailableSections() async {
    try {
      final response = await _supabase
          .from('Student')
          .select('Section')
          .not('Section', 'is', null);

      final sections = <String>{};
      for (final row in response) {
        final section = row['Section'] as String?;
        if (section != null && section.isNotEmpty) {
          sections.add(section);
        }
      }

      final sortedSections = sections.toList()..sort();
      return sortedSections;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch available sections: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch available sections: $e');
    }
  }
}
