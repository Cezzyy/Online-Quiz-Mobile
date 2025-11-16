import '../models/user.dart';
import '../models/role.dart';
import '../models/user_role.dart';
import '../models/teacher.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/choice.dart';
import '../models/attempt.dart';
import '../models/attempt_answer.dart';
import '../models/notification.dart';
import '../models/export_import_log.dart';

class MockData {
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
    User(
      userId: 5,
      email: 'maria.santos@student.edu',
      passwordHash: 'hashed_password_maria',
      fullName: 'Maria Santos',
      status: 'Active',
      createdAt: DateTime(2024, 1, 5),
      updatedAt: DateTime(2024, 1, 5),
      contactNumber: '+63 912 345 6790',
      emergencyContactNumber: '+63 987 654 3211',
    ),
    User(
      userId: 6,
      email: 'john.dela.cruz@student.edu',
      passwordHash: 'hashed_password_john',
      fullName: 'John Dela Cruz',
      status: 'Active',
      createdAt: DateTime(2024, 1, 6),
      updatedAt: DateTime(2024, 1, 6),
      contactNumber: '+63 912 345 6791',
      emergencyContactNumber: '+63 987 654 3212',
    ),
    User(
      userId: 7,
      email: 'anna.garcia@student.edu',
      passwordHash: 'hashed_password_anna',
      fullName: 'Anna Garcia',
      status: 'Active',
      createdAt: DateTime(2024, 1, 7),
      updatedAt: DateTime(2024, 1, 7),
      contactNumber: '+63 912 345 6792',
      emergencyContactNumber: '+63 987 654 3213',
    ),
    User(
      userId: 8,
      email: 'michael.reyes@student.edu',
      passwordHash: 'hashed_password_michael',
      fullName: 'Michael Reyes',
      status: 'Active',
      createdAt: DateTime(2024, 1, 8),
      updatedAt: DateTime(2024, 1, 8),
      contactNumber: '+63 912 345 6793',
      emergencyContactNumber: '+63 987 654 3214',
    ),
    
    // Additional Teachers
    User(
      userId: 9,
      email: 'prof.smith@university.edu',
      passwordHash: 'hashed_password_smith',
      fullName: 'Prof. Sarah Smith',
      status: 'Active',
      createdAt: DateTime(2024, 1, 9),
      updatedAt: DateTime(2024, 1, 9),
      contactNumber: '+63 912 345 6794',
      emergencyContactNumber: '+63 987 654 3215',
    ),
    User(
      userId: 10,
      email: 'dr.johnson@university.edu',
      passwordHash: 'hashed_password_johnson',
      fullName: 'Dr. Mark Johnson',
      status: 'Active',
      createdAt: DateTime(2024, 1, 10),
      updatedAt: DateTime(2024, 1, 10),
      contactNumber: '+63 912 345 6795',
      emergencyContactNumber: '+63 987 654 3216',
    ),
    User(
      userId: 11,
      email: 'ms.garcia@university.edu',
      passwordHash: 'hashed_password_garcia',
      fullName: 'Ms. Maria Garcia',
      status: 'Active',
      createdAt: DateTime(2024, 1, 11),
      updatedAt: DateTime(2024, 1, 11),
      contactNumber: '+63 912 345 6796',
      emergencyContactNumber: '+63 987 654 3217',
    ),
    User(
      userId: 12,
      email: 'mr.brown@university.edu',
      passwordHash: 'hashed_password_brown',
      fullName: 'Mr. David Brown',
      status: 'Active',
      createdAt: DateTime(2024, 1, 12),
      updatedAt: DateTime(2024, 1, 12),
      contactNumber: '+63 912 345 6797',
      emergencyContactNumber: '+63 987 654 3218',
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
    UserRole(userId: 9, roleId: 2), // Teacher
    UserRole(userId: 10, roleId: 2), // Teacher
    UserRole(userId: 11, roleId: 2), // Teacher
    UserRole(userId: 12, roleId: 2), // Teacher
    UserRole(userId: 4, roleId: 3), // Student
    UserRole(userId: 5, roleId: 3), // Student
    UserRole(userId: 6, roleId: 3), // Student
    UserRole(userId: 7, roleId: 3), // Student
    UserRole(userId: 8, roleId: 3), // Student
  ];

  // Teachers
  static final List<Teacher> teachers = [
    Teacher(userId: 2, department: 'Computer Science'), // Donald Francisco
    Teacher(userId: 9, department: 'Computer Science'), // Prof. Sarah Smith
    Teacher(userId: 10, department: 'Mathematics'), // Dr. Mark Johnson
    Teacher(userId: 11, department: 'Information Technology'), // Ms. Maria Garcia
    Teacher(userId: 12, department: 'Computer Science'), // Mr. David Brown
  ];

  // Students
  static final List<Student> students = [
    Student(userId: 4, studentId: 'C23-01-7557-MAN121', yearLevel: 2, section: 'CS31A', course: 'Computer Science'),
    Student(userId: 5, studentId: 'C23-02-7558-MAN122', yearLevel: 1, section: 'IT11B', course: 'Information Technology'),
    Student(userId: 6, studentId: 'C23-03-7559-MAN123', yearLevel: 3, section: 'CS31A', course: 'Computer Science'),
    Student(userId: 7, studentId: 'C23-04-7560-MAN124', yearLevel: 1, section: 'CS11C', course: 'Computer Science'),
    Student(userId: 8, studentId: 'C23-05-7561-MAN125', yearLevel: 2, section: 'IT21A', course: 'Information Technology'),
  ];

  // Courses
  static final List<Course> courses = [
    // CS101 - Introduction to Programming (Multiple Sections matching student sections)
    Course(
      courseId: 1,
      code: 'CS101',
      name: 'Introduction to Programming',
      instructorUserId: 2, // Donald Francisco
      status: 'Active',
      category: 'Computer Science',
      section: 'CS31A',
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
      createdBy: 1, // Admin
    ),
    Course(
      courseId: 6,
      code: 'CS101',
      name: 'Introduction to Programming',
      instructorUserId: 9, // Prof. Sarah Smith
      status: 'Active',
      category: 'Computer Science',
      section: 'CS11C',
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
      createdBy: 1, // Admin
    ),
    
    // MATH201 - Calculus I (Multiple Sections)
    Course(
      courseId: 2,
      code: 'MATH201',
      name: 'Calculus I',
      instructorUserId: 10, // Dr. Mark Johnson
      status: 'Active',
      category: 'Mathematics',
      section: 'CS31A',
      createdAt: DateTime(2024, 1, 16),
      updatedAt: DateTime(2024, 1, 16),
      createdBy: 1, // Admin
    ),
    Course(
      courseId: 7,
      code: 'MATH201',
      name: 'Calculus I',
      instructorUserId: 10, // Dr. Mark Johnson
      status: 'Active',
      category: 'Mathematics',
      section: 'IT21A',
      createdAt: DateTime(2024, 1, 16),
      updatedAt: DateTime(2024, 1, 16),
      createdBy: 1, // Admin
    ),
    
    // CS201 - Data Structures
    Course(
      courseId: 3,
      code: 'CS201',
      name: 'Data Structures',
      instructorUserId: 12, // Mr. David Brown
      status: 'Active',
      category: 'Computer Science',
      section: 'CS31A',
      createdAt: DateTime(2024, 1, 17),
      updatedAt: DateTime(2024, 1, 17),
      createdBy: 1, // Admin
    ),
    
    // IT301 - Database Management
    Course(
      courseId: 4,
      code: 'IT301',
      name: 'Database Management',
      instructorUserId: 11, // Ms. Maria Garcia
      status: 'Active',
      category: 'Information Technology',
      section: 'IT11B',
      createdAt: DateTime(2024, 1, 18),
      updatedAt: DateTime(2024, 1, 18),
      createdBy: 1, // Admin
    ),
    Course(
      courseId: 8,
      code: 'IT301',
      name: 'Database Management',
      instructorUserId: 11, // Ms. Maria Garcia
      status: 'Active',
      category: 'Information Technology',
      section: 'IT21A',
      createdAt: DateTime(2024, 1, 18),
      updatedAt: DateTime(2024, 1, 18),
      createdBy: 1, // Admin
    ),
    
    // CS301 - Software Engineering
    Course(
      courseId: 5,
      code: 'CS301',
      name: 'Software Engineering',
      instructorUserId: 9, // Prof. Sarah Smith
      status: 'Inactive',
      category: 'Computer Science',
      section: 'CS31A',
      createdAt: DateTime(2024, 1, 19),
      updatedAt: DateTime(2024, 1, 19),
      createdBy: 1, // Admin
    ),
    
    // Additional courses for different sections
    Course(
      courseId: 9,
      code: 'CS102',
      name: 'Object-Oriented Programming',
      instructorUserId: 2, // Donald Francisco
      status: 'Active',
      category: 'Computer Science',
      section: 'CS31A',
      createdAt: DateTime(2024, 1, 20),
      updatedAt: DateTime(2024, 1, 20),
      createdBy: 1, // Admin
    ),
    Course(
      courseId: 10,
      code: 'CS102',
      name: 'Object-Oriented Programming',
      instructorUserId: 12, // Mr. David Brown
      status: 'Active',
      category: 'Computer Science',
      section: 'CS11C',
      createdAt: DateTime(2024, 1, 20),
      updatedAt: DateTime(2024, 1, 20),
      createdBy: 1, // Admin
    ),
    
    Course(
      courseId: 11,
      code: 'IT101',
      name: 'Introduction to Information Technology',
      instructorUserId: 11, // Ms. Maria Garcia
      status: 'Active',
      category: 'Information Technology',
      section: 'IT11B',
      createdAt: DateTime(2024, 1, 21),
      updatedAt: DateTime(2024, 1, 21),
      createdBy: 1, // Admin
    ),
    Course(
      courseId: 12,
      code: 'IT101',
      name: 'Introduction to Information Technology',
      instructorUserId: 11, // Ms. Maria Garcia
      status: 'Active',
      category: 'Information Technology',
      section: 'IT21A',
      createdAt: DateTime(2024, 1, 21),
      updatedAt: DateTime(2024, 1, 21),
      createdBy: 1, // Admin
    ),
  ];

  // Enrollments
  static final List<Enrollment> enrollments = [
    // Jan Rosalijos (userId: 4) - CS31A section
    Enrollment(
      enrollmentId: 1,
      userId: 4,
      courseId: 1, // CS101-CS31A
      enrolledAt: DateTime(2024, 1, 10),
      section: 'CS31A',
      enrolledBy: 2, // Donald Francisco (instructor of CS101-CS31A)
    ),
    Enrollment(
      enrollmentId: 2,
      userId: 4,
      courseId: 2, // MATH201-CS31A
      enrolledAt: DateTime(2024, 1, 10),
      section: 'CS31A',
      enrolledBy: 10, // Dr. Mark Johnson (instructor of MATH201-CS31A)
    ),
    Enrollment(
      enrollmentId: 9,
      userId: 4,
      courseId: 3, // CS201-CS31A
      enrolledAt: DateTime(2024, 1, 10),
      section: 'CS31A',
      enrolledBy: 12, // Mr. David Brown (instructor of CS201-CS31A)
    ),
    Enrollment(
      enrollmentId: 10,
      userId: 4,
      courseId: 9, // CS102-CS31A
      enrolledAt: DateTime(2024, 1, 10),
      section: 'CS31A',
      enrolledBy: 2, // Donald Francisco (instructor of CS102-CS31A)
    ),
    
    // Maria Santos (userId: 5) - IT11B section
    Enrollment(
      enrollmentId: 3,
      userId: 5,
      courseId: 4, // IT301-IT11B
      enrolledAt: DateTime(2024, 1, 11),
      section: 'IT11B',
      enrolledBy: 11, // Ms. Maria Garcia (instructor of IT301-IT11B)
    ),
    Enrollment(
      enrollmentId: 11,
      userId: 5,
      courseId: 11, // IT101-IT11B
      enrolledAt: DateTime(2024, 1, 11),
      section: 'IT11B',
      enrolledBy: 11, // Ms. Maria Garcia (instructor of IT101-IT11B)
    ),
    
    // John Dela Cruz (userId: 6) - CS31A section
    Enrollment(
      enrollmentId: 5,
      userId: 6,
      courseId: 1, // CS101-CS31A
      enrolledAt: DateTime(2024, 1, 12),
      section: 'CS31A',
      enrolledBy: 2, // Donald Francisco (instructor of CS101-CS31A)
    ),
    Enrollment(
      enrollmentId: 6,
      userId: 6,
      courseId: 2, // MATH201-CS31A
      enrolledAt: DateTime(2024, 1, 12),
      section: 'CS31A',
      enrolledBy: 10, // Dr. Mark Johnson (instructor of MATH201-CS31A)
    ),
    Enrollment(
      enrollmentId: 7,
      userId: 6,
      courseId: 3, // CS201-CS31A
      enrolledAt: DateTime(2024, 1, 12),
      section: 'CS31A',
      enrolledBy: 12, // Mr. David Brown (instructor of CS201-CS31A)
    ),
    Enrollment(
      enrollmentId: 12,
      userId: 6,
      courseId: 9, // CS102-CS31A
      enrolledAt: DateTime(2024, 1, 12),
      section: 'CS31A',
      enrolledBy: 2, // Donald Francisco (instructor of CS102-CS31A)
    ),
    
    // Jane Smith (userId: 7) - CS11C section
    Enrollment(
      enrollmentId: 8,
      userId: 7,
      courseId: 6, // CS101-CS11C
      enrolledAt: DateTime(2024, 1, 13),
      section: 'CS11C',
      enrolledBy: 9, // Prof. Sarah Smith (instructor of CS101-CS11C)
    ),
    Enrollment(
      enrollmentId: 13,
      userId: 7,
      courseId: 10, // CS102-CS11C
      enrolledAt: DateTime(2024, 1, 13),
      section: 'CS11C',
      enrolledBy: 12, // Mr. David Brown (instructor of CS102-CS11C)
    ),
    
    // Michael Reyes (userId: 8) - IT21A section
    Enrollment(
      enrollmentId: 14,
      userId: 8,
      courseId: 7, // MATH201-IT21A
      enrolledAt: DateTime(2024, 1, 14),
      section: 'IT21A',
      enrolledBy: 10, // Dr. Mark Johnson (instructor of MATH201-IT21A)
    ),
    Enrollment(
      enrollmentId: 15,
      userId: 8,
      courseId: 8, // IT301-IT21A
      enrolledAt: DateTime(2024, 1, 14),
      section: 'IT21A',
      enrolledBy: 11, // Ms. Maria Garcia (instructor of IT301-IT21A)
    ),
    Enrollment(
      enrollmentId: 16,
      userId: 8,
      courseId: 12, // IT101-IT21A
      enrolledAt: DateTime(2024, 1, 14),
      section: 'IT21A',
      enrolledBy: 11, // Ms. Maria Garcia (instructor of IT101-IT21A)
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
      createdBy: 2, // Donald Francisco (instructor of CS101-CS31A)
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
      createdBy: 2, // Donald Francisco (instructor of CS101-CS31A)
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
      createdBy: 10, // Dr. Mark Johnson (instructor of MATH201-CS31A)
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
    Notification(
      notificationId: 5,
      userId: 2,
      type: NotificationType.quiz,
      title: 'Quiz Submission Received',
      message: 'Jan Rosalijos has submitted the "Variables and Data Types" quiz.',
      isRead: true,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Notification(
      notificationId: 6,
      userId: 2,
      type: NotificationType.quiz,
      title: 'Quiz Submission Received',
      message: 'Maria Santos has submitted the "Variables and Data Types" quiz.',
      isRead: false,
      createdAt: DateTime.now().subtract(Duration(hours: 3)),
    ),
    Notification(
      notificationId: 7,
      userId: 2,
      type: NotificationType.course,
      title: 'New Student Enrollment',
      message: 'John Dela Cruz has enrolled in CS101 - Introduction to Programming.',
      isRead: true,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    Notification(
      notificationId: 8,
      userId: 2,
      type: NotificationType.reminder,
      title: 'Quiz Due Soon',
      message: 'Quiz "Control Structures" is due in 2 days. Consider sending reminders to students.',
      isRead: false,
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
    Notification(
      notificationId: 9,
      userId: 2,
      type: NotificationType.system,
      title: 'Grade Export Available',
      message: 'Your quiz grades for CS101 have been successfully exported.',
      isRead: true,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    Notification(
      notificationId: 10,
      userId: 2,
      type: NotificationType.quiz,
      title: 'Quiz Results Ready',
      message: 'All submissions for "Limits and Continuity" quiz have been graded.',
      isRead: false,
      createdAt: DateTime.now().subtract(Duration(minutes: 30)),
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

  // Authentication method
  static User? getUserByCredentials(String email, String password) {
    try {
      // For demo purposes, we'll use simple password matching
      // In a real app, you'd hash the password and compare with passwordHash
      final user = users.firstWhere((user) => user.email == email);
      
      // Simple password validation for demo
      String expectedPassword;
      switch (email) {
        case 'admin.aclc@quiz.com':
          expectedPassword = 'admin123';
          break;
        case 'donald.francisco@university.edu':
          expectedPassword = 'teacher123';
          break;
        case 'jan.rosalijos@student.edu':
          expectedPassword = 'student123';
          break;
        default:
          return null;
      }
      
      if (password == expectedPassword && user.isActive) {
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user role
  static String? getUserRole(int userId) {
    try {
      final userRole = userRoles.firstWhere((ur) => ur.userId == userId);
      final role = roles.firstWhere((r) => r.roleId == userRole.roleId);
      return role.name;
    } catch (e) {
      return null;
    }
  }

  // Get student by user ID
  static Student? getStudentByUserId(int userId) {
    try {
      return students.firstWhere((student) => student.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Get mock credentials for development
  static Map<String, Map<String, dynamic>> get mockCredentials => {
    'Admin': {
      'email': 'admin.aclc@quiz.com',
      'password': 'admin123',
      'role': 'Admin',
    },
    'Teacher': {
      'email': 'donald.francisco@university.edu',
      'password': 'teacher123',
      'role': 'Teacher',
    },
    'Student': {
      'email': 'jan.rosalijos@student.edu',
      'password': 'student123',
      'role': 'Student',
    },
  };
}