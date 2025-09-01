import 'user.dart';
import 'course.dart';
import 'quiz.dart';
import 'quiz_result.dart';
import 'notification_item.dart';

// Dummy Data
class DummyData {
  // Mock credentials for authentication
  static const Map<String, Map<String, dynamic>> mockCredentials = {
    'jan.rosalijos': {
      'password': 'password123',
      'userType': 'student',
      'userId': 'user_001',
    },
    'teacher.santos': {
      'password': 'teacher123',
      'userType': 'teacher',
      'userId': 'user_002',
    },
    'admin.aclc': {
      'password': 'admin123',
      'userType': 'admin',
      'userId': 'user_003',
    },
  };

  static User getUser() {
    return getUserById('user_001');
  }

  static User getUserById(String userId) {
    switch (userId) {
      case 'user_001':
        return _createStudentUser();
      case 'user_002':
        return _createTeacherUser();
      case 'user_003':
        return _createAdminUser();
      default:
        return _createStudentUser();
    }
  }

  static User getUserByCredentials(String username, String password) {
    final credentials = mockCredentials[username];
    if (credentials != null && credentials['password'] == password) {
      return getUserById(credentials['userId']);
    }
    throw Exception('Invalid credentials');
  }

  static User _createStudentUser() {
    final courses = _createCourses();
    final notifications = _createNotifications();
    
    return User(
      id: 'user_001',
      name: 'Jan Rosalijos',
      email: 'jan.rosalijos@gmail.com',
      studentId: 'C23-01-7557-MAN121',
      courses: courses,
      notifications: notifications,
      bio: 'Computer Science student passionate about mobile development and AI.',
      phoneNumber: '+63 912 345 6789',
      emergencyContact: '+63 998 765 4321',
      profileImageUrl: 'assets/images/aclclogo-nobg.png',
      degree: 'Bachelor of Science in Computer Science',
    );
  }

  static User _createTeacherUser() {
    final courses = _createTeacherCourses();
    final notifications = _createTeacherNotifications();
    
    return User(
      id: 'user_002',
      name: 'Prof. Maria Santos',
      email: 'maria.santos@aclc.edu.ph',
      studentId: 'TEACH-001',
      courses: courses,
      notifications: notifications,
      bio: 'Information Security Professor with 10+ years of experience in cybersecurity.',
      phoneNumber: '+63 917 123 4567',
      emergencyContact: '+63 998 111 2222',
      profileImageUrl: 'assets/images/aclclogo-nobg.png',
      degree: 'Master of Science in Information Technology',
    );
  }

  static User _createAdminUser() {
    final courses = _createAdminCourses();
    final notifications = _createAdminNotifications();
    
    return User(
      id: 'user_003',
      name: 'Admin User',
      email: 'admin@aclc.edu.ph',
      studentId: 'ADMIN-001',
      courses: courses,
      notifications: notifications,
      bio: 'System Administrator managing the ACLC Online Quiz Platform.',
      phoneNumber: '+63 920 999 8888',
      emergencyContact: '+63 998 777 6666',
      profileImageUrl: 'assets/images/aclclogo-nobg.png',
      degree: 'Bachelor of Science in Information Technology',
    );
  }

  static List<Course> _createCourses() {
    return [
      Course(
        id: 'course_001',
        name: 'Information Assurance and Security I',
        code: 'IAS101',
        instructor: 'Prof. Maria Santos',
        units: 3,
        quizzes: [
          Quiz(
            id: 'quiz_001',
            title: 'Fundamentals of Information Security',
            courseId: 'course_001',
            dueDate: DateTime.now().subtract(const Duration(days: 5)),
            dateAdded: DateTime.now().subtract(const Duration(days: 15)),
            totalQuestions: 20,
            timeLimit: 30,
            isCompleted: true,
            result: QuizResult(
              id: 'result_001',
              quizId: 'quiz_001',
              correctAnswers: 17,
              totalQuestions: 20,
              completedAt: DateTime.now().subtract(const Duration(days: 5)),
              timeSpent: 25,
              questionResults: [],
            ),
          ),
          Quiz(
            id: 'quiz_002',
            title: 'Cryptography Basics',
            courseId: 'course_001',
            dueDate: DateTime.now().add(const Duration(days: 3)),
            dateAdded: DateTime.now().subtract(const Duration(days: 10)),
            totalQuestions: 25,
            timeLimit: 45,
            isCompleted: false,
          ),
        ],
      ),
      Course(
        id: 'course_002',
        name: 'Programming Languages with Compiler',
        code: 'PLC201',
        instructor: 'Prof. John Cruz',
        units: 3,
        quizzes: [
          Quiz(
            id: 'quiz_003',
            title: 'Lexical Analysis',
            courseId: 'course_002',
            dueDate: DateTime.now().subtract(const Duration(days: 8)),
            dateAdded: DateTime.now().subtract(const Duration(days: 20)),
            totalQuestions: 15,
            timeLimit: 40,
            isCompleted: true,
            result: QuizResult(
              id: 'result_002',
              quizId: 'quiz_003',
              correctAnswers: 13,
              totalQuestions: 15,
              completedAt: DateTime.now().subtract(const Duration(days: 8)),
              timeSpent: 35,
              questionResults: [],
            ),
          ),
          Quiz(
            id: 'quiz_004',
            title: 'Syntax Analysis and Parsing',
            courseId: 'course_002',
            dueDate: DateTime.now().add(const Duration(days: 7)),
            dateAdded: DateTime.now().subtract(const Duration(days: 12)),
            totalQuestions: 18,
            timeLimit: 50,
            isCompleted: false,
          ),
        ],
      ),
      Course(
        id: 'course_003',
        name: 'Software Engineering I',
        code: 'SE101',
        instructor: 'Prof. Ana Reyes',
        units: 3,
        quizzes: [
          Quiz(
            id: 'quiz_005',
            title: 'Software Development Life Cycle',
            courseId: 'course_003',
            dueDate: DateTime.now().subtract(const Duration(days: 3)),
            dateAdded: DateTime.now().subtract(const Duration(days: 18)),
            totalQuestions: 22,
            timeLimit: 35,
            isCompleted: true,
            result: QuizResult(
              id: 'result_003',
              quizId: 'quiz_005',
              correctAnswers: 20,
              totalQuestions: 22,
              completedAt: DateTime.now().subtract(const Duration(days: 3)),
              timeSpent: 30,
              questionResults: [],
            ),
          ),
          Quiz(
            id: 'quiz_006',
            title: 'Requirements Engineering',
            courseId: 'course_003',
            dueDate: DateTime.now().add(const Duration(days: 5)),
            dateAdded: DateTime.now().subtract(const Duration(days: 8)),
            totalQuestions: 20,
            timeLimit: 40,
            isCompleted: false,
          ),
        ],
      ),
      Course(
        id: 'course_004',
        name: 'Automata Theory and Formal Languages',
        code: 'ATFL301',
        instructor: 'Prof. Robert Garcia',
        units: 3,
        quizzes: [
          Quiz(
            id: 'quiz_007',
            title: 'Finite Automata',
            courseId: 'course_004',
            dueDate: DateTime.now().subtract(const Duration(days: 10)),
            dateAdded: DateTime.now().subtract(const Duration(days: 25)),
            totalQuestions: 16,
            timeLimit: 45,
            isCompleted: true,
            result: QuizResult(
              id: 'result_004',
              quizId: 'quiz_007',
              correctAnswers: 14,
              totalQuestions: 16,
              completedAt: DateTime.now().subtract(const Duration(days: 10)),
              timeSpent: 40,
              questionResults: [],
            ),
          ),
          Quiz(
            id: 'quiz_008',
            title: 'Context-Free Grammars',
            courseId: 'course_004',
            dueDate: DateTime.now().add(const Duration(days: 2)),
            dateAdded: DateTime.now().subtract(const Duration(days: 6)),
            totalQuestions: 18,
            timeLimit: 50,
            isCompleted: false,
          ),
        ],
      ),
      Course(
        id: 'course_005',
        name: 'Computer Architecture and Organization',
        code: 'CAO201',
        instructor: 'Prof. Lisa Mendoza',
        units: 3,
        quizzes: [
          Quiz(
            id: 'quiz_009',
            title: 'CPU Architecture',
            courseId: 'course_005',
            dueDate: DateTime.now().subtract(const Duration(days: 7)),
            dateAdded: DateTime.now().subtract(const Duration(days: 22)),
            totalQuestions: 24,
            timeLimit: 40,
            isCompleted: true,
            result: QuizResult(
              id: 'result_005',
              quizId: 'quiz_009',
              correctAnswers: 21,
              totalQuestions: 24,
              completedAt: DateTime.now().subtract(const Duration(days: 7)),
              timeSpent: 35,
              questionResults: [],
            ),
          ),
          Quiz(
            id: 'quiz_010',
            title: 'Memory Hierarchy',
            courseId: 'course_005',
            dueDate: DateTime.now().add(const Duration(days: 4)),
            dateAdded: DateTime.now().subtract(const Duration(days: 9)),
            totalQuestions: 20,
            timeLimit: 35,
            isCompleted: false,
          ),
        ],
      ),
      Course(
        id: 'course_006',
        name: 'Pagsasaling Pampanitikan',
        code: 'FIL201',
        instructor: 'Prof. Carmen Dela Cruz',
        units: 3,
        quizzes: [
          Quiz(
            id: 'quiz_011',
            title: 'Mga Uri ng Pagsasalin',
            courseId: 'course_006',
            dueDate: DateTime.now().subtract(const Duration(days: 6)),
            dateAdded: DateTime.now().subtract(const Duration(days: 21)),
            totalQuestions: 18,
            timeLimit: 30,
            isCompleted: true,
            result: QuizResult(
              id: 'result_006',
              quizId: 'quiz_011',
              correctAnswers: 16,
              totalQuestions: 18,
              completedAt: DateTime.now().subtract(const Duration(days: 6)),
              timeSpent: 25,
              questionResults: [],
            ),
          ),
          Quiz(
            id: 'quiz_012',
            title: 'Teorya ng Pagsasalin',
            courseId: 'course_006',
            dueDate: DateTime.now().add(const Duration(days: 6)),
            dateAdded: DateTime.now().subtract(const Duration(days: 7)),
            totalQuestions: 15,
            timeLimit: 25,
            isCompleted: false,
          ),
        ],
      ),
      Course(
        id: 'course_007',
        name: 'Professional Ethics in IT/ Social & Professional I',
        code: 'ETHICS101',
        instructor: 'Prof. Michael Torres',
        units: 3,
        quizzes: [
          Quiz(
            id: 'quiz_013',
            title: 'IT Ethics Fundamentals',
            courseId: 'course_007',
            dueDate: DateTime.now().subtract(const Duration(days: 4)),
            dateAdded: DateTime.now().subtract(const Duration(days: 19)),
            totalQuestions: 20,
            timeLimit: 30,
            isCompleted: true,
            result: QuizResult(
              id: 'result_007',
              quizId: 'quiz_013',
              correctAnswers: 18,
              totalQuestions: 20,
              completedAt: DateTime.now().subtract(const Duration(days: 4)),
              timeSpent: 28,
              questionResults: [],
            ),
          ),
          Quiz(
            id: 'quiz_014',
            title: 'Professional Responsibility',
            courseId: 'course_007',
            dueDate: DateTime.now().add(const Duration(days: 8)),
            dateAdded: DateTime.now().subtract(const Duration(days: 5)),
            totalQuestions: 22,
            timeLimit: 35,
            isCompleted: false,
          ),
        ],
      ),
      Course(
        id: 'course_008',
        name: 'Mobile Programming 1',
        code: 'MP101',
        instructor: 'Prof. Sarah Villanueva',
        units: 3,
        quizzes: [
          Quiz(
            id: 'quiz_015',
            title: 'Flutter Basics',
            courseId: 'course_008',
            dueDate: DateTime.now().subtract(const Duration(days: 2)),
            dateAdded: DateTime.now().subtract(const Duration(days: 17)),
            totalQuestions: 25,
            timeLimit: 45,
            isCompleted: true,
            result: QuizResult(
              id: 'result_008',
              quizId: 'quiz_015',
              correctAnswers: 23,
              totalQuestions: 25,
              completedAt: DateTime.now().subtract(const Duration(days: 2)),
              timeSpent: 40,
              questionResults: [],
            ),
          ),
          Quiz(
            id: 'quiz_016',
            title: 'State Management in Flutter',
            courseId: 'course_008',
            dueDate: DateTime.now().add(const Duration(days: 1)),
            dateAdded: DateTime.now().subtract(const Duration(days: 4)),
            totalQuestions: 20,
            timeLimit: 40,
            isCompleted: false,
          ),
        ],
      ),
    ];
  }

  static List<NotificationItem> _createNotifications() {
    return [
      NotificationItem(
        id: 'notif_001',
        title: 'Quiz Due Tomorrow',
        message: 'State Management in Flutter quiz is due tomorrow at 11:59 PM',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'reminder',
        isRead: false,
        courseId: 'course_008',
      ),
      NotificationItem(
        id: 'notif_002',
        title: 'Quiz Result Available',
        message: 'Your Flutter Basics quiz result is now available. Score: 92%',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'result',
        isRead: true,
        courseId: 'course_008',
      ),
      NotificationItem(
        id: 'notif_003',
        title: 'New Quiz Available',
        message: 'Context-Free Grammars quiz is now available in Automata Theory',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: 'quiz',
        isRead: true,
        courseId: 'course_004',
      ),
      NotificationItem(
        id: 'notif_004',
        title: 'Quiz Deadline Approaching',
        message: 'Requirements Engineering quiz is due in 2 days',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        type: 'reminder',
        isRead: false,
        courseId: 'course_003',
      ),
      NotificationItem(
        id: 'notif_005',
        title: 'Quiz Reminder',
        message: 'Cryptography Basics quiz is due in 3 days',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        type: 'reminder',
        isRead: true,
        courseId: 'course_001',
      ),
      NotificationItem(
        id: 'notif_006',
        title: 'Grade Posted',
        message: 'Your IT Ethics Fundamentals quiz grade has been posted: 90%',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        type: 'result',
        isRead: true,
        courseId: 'course_007',
      ),
      NotificationItem(
        id: 'notif_007',
        title: 'New Quiz Available',
        message: 'Memory Hierarchy quiz is now available in Computer Architecture',
        timestamp: DateTime.now().subtract(const Duration(days: 6)),
        type: 'quiz',
        isRead: true,
        courseId: 'course_005',
      ),
      NotificationItem(
        id: 'notif_008',
        title: 'Quiz Completed',
        message: 'You have successfully completed the CPU Architecture quiz',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        type: 'result',
        isRead: true,
        courseId: 'course_005',
      ),
    ];
  }

  static List<Course> _createTeacherCourses() {
    return [
      Course(
        id: 'course_001',
        name: 'Information Assurance and Security I',
        code: 'IAS101',
        instructor: 'Prof. Maria Santos',
        units: 3,
        quizzes: _createCourses()[0].quizzes,
      ),
      Course(
        id: 'course_006',
        name: 'Advanced Cybersecurity',
        code: 'CS401',
        instructor: 'Prof. Maria Santos',
        units: 3,
        quizzes: [],
      ),
    ];
  }

  static List<Course> _createAdminCourses() {
    return _createCourses(); // Admin can see all courses
  }

  static List<NotificationItem> _createTeacherNotifications() {
    return [
      NotificationItem(
        id: 'notif_teacher_001',
        title: 'New Student Enrolled',
        message: 'A new student has enrolled in your IAS101 course',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'info',
        isRead: false,
        courseId: 'course_001',
      ),
      NotificationItem(
        id: 'notif_teacher_002',
        title: 'Quiz Submissions',
        message: '15 students have submitted their quiz assignments',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'result',
        isRead: true,
        courseId: 'course_001',
      ),
    ];
  }

  static List<NotificationItem> _createAdminNotifications() {
    return [
      NotificationItem(
        id: 'notif_admin_001',
        title: 'System Maintenance',
        message: 'Scheduled maintenance will occur this weekend',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: 'warning',
        isRead: false,
        courseId: '',
      ),
      NotificationItem(
        id: 'notif_admin_002',
        title: 'New Course Created',
        message: 'Advanced Cybersecurity course has been added to the system',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: 'info',
        isRead: true,
        courseId: 'course_006',
      ),
    ];
  }
}