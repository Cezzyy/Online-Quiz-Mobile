import '../models/new_user.dart';
import '../models/new_role.dart';
import '../models/new_user_role.dart';
import '../models/new_teacher.dart';
import '../models/new_student.dart';
import '../models/new_course.dart';
import '../models/new_enrollment.dart';
import '../models/new_quiz.dart';
import '../models/new_question.dart';
import '../models/new_choice.dart';
import '../models/new_attempt.dart';
import '../models/new_attempt_answer.dart';
import '../models/new_notification.dart';
import '../models/new_export_import_log.dart';

class NewMockData {
  // Users
  static final List<User> users = [
    User(
      userId: 1,
      email: 'admin.aclc@quiz.com',
      passwordHash: 'hashed_password_admin',
      fullName: 'System Administrator',
      status: 'Active',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    User(
      userId: 2,
      email: 'donald.francisco@university.edu',
      passwordHash: 'hashed_password_donald',
      fullName: 'Donald Francisco',
      status: 'Active',
      createdAt: DateTime(2024, 1, 2),
      updatedAt: DateTime(2024, 1, 2),
    ),

    User(
      userId: 4,
      email: 'jan.rosalijos@student.edu',
      passwordHash: 'hashed_password_jan',
      fullName: 'Jan Rosalijos',
      status: 'Active',
      createdAt: DateTime(2024, 1, 4),
      updatedAt: DateTime(2024, 1, 4),
      contactNumber: '+63 912 345 6789',
      emergencyContactNumber: '+63 987 654 3210',
    ),
  ];

  // Roles
  static final List<Role> roles = [
    Role(roleId: 1, name: 'Admin'),
    Role(roleId: 2, name: 'Teacher'),
    Role(roleId: 3, name: 'Student'),
  ];

  // User Roles
  static final List<UserRole> userRoles = [
    UserRole(userId: 1, roleId: 1), // Admin
    UserRole(userId: 2, roleId: 2), // Teacher

    UserRole(userId: 4, roleId: 3), // Student
  ];

  // Teachers
  static final List<Teacher> teachers = [
    Teacher(userId: 2, department: 'Computer Science'),
  ];

  // Students
  static final List<Student> students = [
    Student(userId: 4, studentId: 'C23-01-7557-MAN121', yearLevel: 2, section: 'A', course: 'Computer Science'),
  ];

  // Courses
  static final List<Course> courses = [
    Course(
      courseId: 1,
      code: 'CS101',
      name: 'Introduction to Programming',
      instructorUserId: 2,
    ),
    Course(
      courseId: 2,
      code: 'MATH201',
      name: 'Calculus I',
      instructorUserId: 2,
    ),
    Course(
      courseId: 3,
      code: 'CS201',
      name: 'Data Structures',
      instructorUserId: 2,
    ),
  ];

  // Enrollments
  static final List<Enrollment> enrollments = [
    Enrollment(
      enrollmentId: 1,
      userId: 4,
      courseId: 1,
      enrolledAt: DateTime(2024, 1, 10),
    ),
    Enrollment(
      enrollmentId: 2,
      userId: 4,
      courseId: 2,
      enrolledAt: DateTime(2024, 1, 10),
    ),

  ];

  // Quizzes
  static final List<Quiz> quizzes = [
    Quiz(
      quizId: 1,
      courseId: 1,
      title: 'Variables and Data Types',
      dueAt: DateTime.now().add(Duration(days: 7)),
      timeLimitMinutes: 30,
      isPublished: true,
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
    ),
    Quiz(
      quizId: 2,
      courseId: 1,
      title: 'Control Structures',
      dueAt: DateTime.now().add(Duration(days: 14)),
      timeLimitMinutes: 45,
      isPublished: true,
      createdAt: DateTime(2024, 1, 16),
      updatedAt: DateTime(2024, 1, 16),
    ),
    Quiz(
      quizId: 3,
      courseId: 2,
      title: 'Limits and Continuity',
      dueAt: DateTime.now().add(Duration(days: 5)),
      timeLimitMinutes: 60,
      isPublished: true,
      createdAt: DateTime(2024, 1, 17),
      updatedAt: DateTime(2024, 1, 17),
    ),
  ];

  // Questions
  static final List<Question> questions = [
    Question(
      questionId: 1,
      quizId: 1,
      type: QuestionType.single,
      body: 'Which of the following is a valid variable name in most programming languages?',
      points: 2.0,
      sortOrder: 1,
    ),
    Question(
      questionId: 2,
      quizId: 1,
      type: QuestionType.multiple,
      body: 'Which of the following are primitive data types? (Select all that apply)',
      points: 3.0,
      sortOrder: 2,
    ),
    Question(
      questionId: 3,
      quizId: 1,
      type: QuestionType.text,
      body: 'Explain the difference between a variable and a constant.',
      points: 5.0,
      sortOrder: 3,
    ),
    Question(
      questionId: 4,
      quizId: 2,
      type: QuestionType.single,
      body: 'Which loop is guaranteed to execute at least once?',
      points: 2.0,
      sortOrder: 1,
    ),
    Question(
      questionId: 5,
      quizId: 3,
      type: QuestionType.single,
      body: 'What is the limit of f(x) = x² as x approaches 2?',
      points: 3.0,
      sortOrder: 1,
    ),
    Question(
      questionId: 6,
      quizId: 3,
      type: QuestionType.single,
      body: 'A function is continuous at a point if:',
      points: 3.0,
      sortOrder: 2,
    ),
    Question(
      questionId: 7,
      quizId: 3,
      type: QuestionType.text,
      body: 'Explain the concept of continuity in calculus.',
      points: 4.0,
      sortOrder: 3,
    ),
  ];

  // Choices
  static final List<Choice> choices = [
    // Question 1 choices
    Choice(choiceId: 1, questionId: 1, body: 'myVariable', isCorrect: true),
    Choice(choiceId: 2, questionId: 1, body: '2variable', isCorrect: false),
    Choice(choiceId: 3, questionId: 1, body: 'my-variable', isCorrect: false),
    Choice(choiceId: 4, questionId: 1, body: 'class', isCorrect: false),
    
    // Question 2 choices
    Choice(choiceId: 5, questionId: 2, body: 'int', isCorrect: true),
    Choice(choiceId: 6, questionId: 2, body: 'String', isCorrect: false),
    Choice(choiceId: 7, questionId: 2, body: 'boolean', isCorrect: true),
    Choice(choiceId: 8, questionId: 2, body: 'Array', isCorrect: false),
    
    // Question 4 choices
    Choice(choiceId: 9, questionId: 4, body: 'for loop', isCorrect: false),
    Choice(choiceId: 10, questionId: 4, body: 'while loop', isCorrect: false),
    Choice(choiceId: 11, questionId: 4, body: 'do-while loop', isCorrect: true),
    Choice(choiceId: 12, questionId: 4, body: 'foreach loop', isCorrect: false),
    
    // Question 5 choices (Quiz 3)
    Choice(choiceId: 13, questionId: 5, body: '4', isCorrect: true),
    Choice(choiceId: 14, questionId: 5, body: '2', isCorrect: false),
    Choice(choiceId: 15, questionId: 5, body: '0', isCorrect: false),
    Choice(choiceId: 16, questionId: 5, body: 'undefined', isCorrect: false),
    
    // Question 6 choices (Quiz 3)
    Choice(choiceId: 17, questionId: 6, body: 'The limit exists and equals the function value', isCorrect: true),
    Choice(choiceId: 18, questionId: 6, body: 'The function is defined at that point', isCorrect: false),
    Choice(choiceId: 19, questionId: 6, body: 'The limit exists', isCorrect: false),
    Choice(choiceId: 20, questionId: 6, body: 'The function is differentiable', isCorrect: false),
  ];

  // Attempts
  static final List<Attempt> attempts = [
    Attempt(
      attemptId: 1,
      quizId: 1,
      userId: 4,
      startedAt: DateTime.now().subtract(Duration(days: 2, hours: 1)),
      submittedAt: DateTime.now().subtract(Duration(days: 2)),
      score: 8.5,
      timeSpentSeconds: 1800, // 30 minutes
    ),

    Attempt(
      attemptId: 3,
      quizId: 2,
      userId: 4,
      startedAt: DateTime.now().subtract(Duration(minutes: 30)),
      submittedAt: null, // In progress
      score: 0.0,
      timeSpentSeconds: null,
    ),
  ];

  // Attempt Answers
  static final List<AttemptAnswer> attemptAnswers = [
    // Alice's answers for Quiz 1
    AttemptAnswer(
      attemptAnswerId: 1,
      attemptId: 1,
      questionId: 1,
      choiceId: 1, // Correct
      freeText: null,
      isCorrect: true,
    ),
    AttemptAnswer(
      attemptAnswerId: 2,
      attemptId: 1,
      questionId: 2,
      choiceId: 5, // Partially correct (int)
      freeText: null,
      isCorrect: false, // Missing boolean
    ),
    AttemptAnswer(
      attemptAnswerId: 3,
      attemptId: 1,
      questionId: 3,
      choiceId: null,
      freeText: 'A variable can change its value during program execution, while a constant cannot be modified once initialized.',
      isCorrect: true,
    ),

  ];

  // Notifications
  static final List<Notification> notifications = [
    Notification(
      notificationId: 1,
      userId: 4,
      type: NotificationType.quiz,
      title: 'New Quiz Available',
      message: 'A new quiz "Variables and Data Types" has been published for CS101.',
      isRead: true,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    Notification(
      notificationId: 2,
      userId: 4,
      type: NotificationType.reminder,
      title: 'Quiz Due Soon',
      message: 'Quiz "Control Structures" is due in 2 days.',
      isRead: false,
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
    Notification(
      notificationId: 3,
      userId: 5,
      type: NotificationType.course,
      title: 'Course Enrollment',
      message: 'You have been enrolled in CS101 - Introduction to Programming.',
      isRead: true,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    Notification(
      notificationId: 4,
      userId: 2,
      type: NotificationType.system,
      title: 'System Maintenance',
      message: 'The system will undergo maintenance on Sunday from 2 AM to 4 AM.',
      isRead: false,
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
  ];

  // Export Import Logs
  static final List<ExportImportLog> exportImportLogs = [
    ExportImportLog(
      logId: 1,
      userId: 1,
      type: LogType.export,
      fileName: 'quiz_results_2024_01.csv',
      status: LogStatus.completed,
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      completedAt: DateTime.now().subtract(Duration(days: 7, minutes: -5)),
      errorMessage: null,
    ),
    ExportImportLog(
      logId: 2,
      userId: 2,
      type: LogType.import,
      fileName: 'questions_batch_1.json',
      status: LogStatus.failed,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      completedAt: DateTime.now().subtract(Duration(days: 3, minutes: -2)),
      errorMessage: 'Invalid JSON format in line 45',
    ),
    ExportImportLog(
      logId: 3,
      userId: 1,
      type: LogType.export,
      fileName: 'user_report_2024.pdf',
      status: LogStatus.inProgress,
      createdAt: DateTime.now().subtract(Duration(minutes: 15)),
      completedAt: null,
      errorMessage: null,
    ),
  ];

  // Helper methods to get data by relationships
  static List<Course> getCoursesByInstructor(int instructorId) {
    return courses.where((course) => course.instructorUserId == instructorId).toList();
  }

  static List<Quiz> getQuizzesByCourse(int courseId) {
    return quizzes.where((quiz) => quiz.courseId == courseId).toList();
  }

  static List<Question> getQuestionsByQuiz(int quizId) {
    return questions.where((question) => question.quizId == quizId).toList();
  }

  static List<Choice> getChoicesByQuestion(int questionId) {
    return choices.where((choice) => choice.questionId == questionId).toList();
  }

  static List<Attempt> getAttemptsByUser(int userId) {
    return attempts.where((attempt) => attempt.userId == userId).toList();
  }

  static List<Attempt> getAttemptsByQuiz(int quizId) {
    return attempts.where((attempt) => attempt.quizId == quizId).toList();
  }

  static List<AttemptAnswer> getAnswersByAttempt(int attemptId) {
    return attemptAnswers.where((answer) => answer.attemptId == attemptId).toList();
  }

  static List<Notification> getNotificationsByUser(int userId) {
    return notifications.where((notification) => notification.userId == userId).toList();
  }

  static List<Notification> getUnreadNotificationsByUser(int userId) {
    return notifications
        .where((notification) => notification.userId == userId && !notification.isRead)
        .toList();
  }

  static List<Enrollment> getEnrollmentsByUser(int userId) {
    return enrollments.where((enrollment) => enrollment.userId == userId).toList();
  }

  static List<Enrollment> getEnrollmentsByCourse(int courseId) {
    return enrollments.where((enrollment) => enrollment.courseId == courseId).toList();
  }

  static User? getUserById(int userId) {
    try {
      return users.firstWhere((user) => user.userId == userId);
    } catch (e) {
      return null;
    }
  }

  static Course? getCourseById(int courseId) {
    try {
      return courses.firstWhere((course) => course.courseId == courseId);
    } catch (e) {
      return null;
    }
  }

  static Quiz? getQuizById(int quizId) {
    try {
      return quizzes.firstWhere((quiz) => quiz.quizId == quizId);
    } catch (e) {
      return null;
    }
  }
}