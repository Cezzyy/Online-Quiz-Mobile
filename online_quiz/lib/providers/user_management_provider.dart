import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/teacher.dart';
import '../models/student.dart';
import '../services/auth_service.dart';

// User management state
class UserManagementState {
  final List<User> users;
  final List<Teacher> teachers;
  final List<Student> students;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final UserType selectedUserType;
  final User? selectedUser;
  final int currentPage;
  final int itemsPerPage;

  const UserManagementState({
    this.users = const [],
    this.teachers = const [],
    this.students = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedUserType = UserType.all,
    this.selectedUser,
    this.currentPage = 1,
    this.itemsPerPage = 20,
  });

  UserManagementState copyWith({
    List<User>? users,
    List<Teacher>? teachers,
    List<Student>? students,
    bool? isLoading,
    String? error,
    String? searchQuery,
    UserType? selectedUserType,
    User? selectedUser,
    int? currentPage,
    int? itemsPerPage,
    bool clearError = false,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      teachers: teachers ?? this.teachers,
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedUserType: selectedUserType ?? this.selectedUserType,
      selectedUser: selectedUser ?? this.selectedUser,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }
}

enum UserType { all, teachers, students }

// User management notifier
class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final AuthService _authService = AuthService();

  UserManagementNotifier() : super(const UserManagementState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final usersData = await _authService.getAllUsers();
      final teachersData = await _authService.getAllTeachers();
      final studentsData = await _authService.getAllStudents();

      final users = usersData.map((data) => data['user'] as User).toList();
      final teachers = <Teacher>[];
      final students = <Student>[];

      // Process teachers
      for (final data in teachersData) {
        final user = data['user'] as User;
        teachers.add(Teacher(
          userId: user.userId,
          department: data['department'] as String? ?? '',
        ));
      }

      // Process students
      for (final data in studentsData) {
        final user = data['user'] as User;
        students.add(Student(
          userId: user.userId,
          studentId: data['studentId'] as String? ?? '',
          yearLevel: data['yearLevel'] as int?,
          section: data['section'] as String?,
          course: data['course'] as String?,
        ));
      }

      state = state.copyWith(
        users: users,
        teachers: teachers,
        students: students,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
  }

  void updateSelectedUserType(UserType userType) {
    state = state.copyWith(selectedUserType: userType, currentPage: 1);
  }

  void selectUser(User? user) {
    state = state.copyWith(selectedUser: user);
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void nextPage() {
    final totalPages = getTotalPages();
    if (state.currentPage < totalPages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  int getTotalPages() {
    final filteredUsers = _getFilteredUsers();
    return (filteredUsers.length / state.itemsPerPage).ceil();
  }

  List<User> getFilteredUsers() {
    return _getFilteredUsers();
  }

  List<User> getPaginatedUsers() {
    final filteredUsers = _getFilteredUsers();
    final startIndex = (state.currentPage - 1) * state.itemsPerPage;
    final endIndex = (startIndex + state.itemsPerPage).clamp(0, filteredUsers.length);
    return filteredUsers.sublist(startIndex, endIndex);
  }

  List<User> _getFilteredUsers() {
    List<User> users = state.users;
    
    // Filter by user type
    switch (state.selectedUserType) {
      case UserType.teachers:
        final teacherUserIds = state.teachers.map((t) => t.userId).toSet();
        users = users.where((u) => teacherUserIds.contains(u.userId)).toList();
        break;
      case UserType.students:
        final studentUserIds = state.students.map((s) => s.userId).toSet();
        users = users.where((u) => studentUserIds.contains(u.userId)).toList();
        break;
      case UserType.all:
        // Show all users
        break;
    }
    
    // Filter by search query
    if (state.searchQuery.isNotEmpty) {
      users = users.where((user) {
        final query = state.searchQuery.toLowerCase();
        return user.fullName.toLowerCase().contains(query) ||
               user.email.toLowerCase().contains(query) ||
               user.contactNumber.contains(query);
      }).toList();
    }
    
    return users;
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String contactNumber,
    required String emergencyContactNumber,
    required UserType userType,
    required int createdBy,
    String? department,
    String? studentId,
    int? yearLevel,
    String? section,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final roleName = userType == UserType.teachers ? 'Teacher' : 'Student';
      
      await _authService.createUser(
        email: email,
        password: password,
        fullName: fullName,
        role: roleName,
        createdBy: createdBy,
        contactNumber: contactNumber,
        emergencyContactNumber: emergencyContactNumber,
        department: department,
        studentId: studentId,
        section: section,
        yearLevel: yearLevel,
      );
      
      // Reload users after creation
      await loadUsers();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create user: $e',
      );
    }
  }

  Future<void> updateUser(User user, {
    String? email,
    String? fullName,
    String? contactNumber,
    String? emergencyContactNumber,
    String? status,
    String? department,
    String? studentId,
    int? yearLevel,
    String? section,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await _authService.updateUser(
        userId: user.userId,
        email: email,
        fullName: fullName,
        contactNumber: contactNumber,
        emergencyContactNumber: emergencyContactNumber,
        status: status,
        department: department,
        studentId: studentId,
        section: section,
        yearLevel: yearLevel,
      );
      
      // Reload users after update
      await loadUsers();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update user: $e',
      );
    }
  }

  Future<void> deleteUser(User user) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await _authService.deleteUser(user.userId);
      
      // Reload users after deletion
      await loadUsers();
      
      state = state.copyWith(
        selectedUser: null,
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete user: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider
final userManagementProvider = StateNotifierProvider<UserManagementNotifier, UserManagementState>(
  (ref) => UserManagementNotifier(),
);
