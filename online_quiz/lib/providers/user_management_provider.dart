import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../models/user.dart';
import '../models/teacher.dart';
import '../models/student.dart';
import '../models/user_role.dart';

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
  UserManagementNotifier() : super(const UserManagementState()) {
    _loadUsers();
  }

  void _loadUsers() {
    state = state.copyWith(isLoading: true);
    
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      state = state.copyWith(
        users: MockData.users,
        teachers: MockData.teachers,
        students: MockData.students,
        isLoading: false,
      );
    });
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
    String? department,
    String? studentId,
    int? yearLevel,
    String? section,
    String? course,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Generate new user ID
      final newUserId = MockData.users.isNotEmpty 
          ? MockData.users.map((u) => u.userId).reduce((a, b) => a > b ? a : b) + 1
          : 1;
      
      // Create new user
      final newUser = User(
        userId: newUserId,
        email: email,
        passwordHash: 'hashed_$password', // In real app, properly hash password
        fullName: fullName,
        status: 'Active',
        contactNumber: contactNumber,
        emergencyContactNumber: emergencyContactNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Add to mock data
      MockData.users.add(newUser);
      
      // Add role
      final roleId = userType == UserType.teachers ? 2 : 3; // Teacher or Student role
      MockData.userRoles.add(UserRole(userId: newUserId, roleId: roleId));
      
      // Add specific user type data
      if (userType == UserType.teachers && department != null) {
        MockData.teachers.add(Teacher(userId: newUserId, department: department));
      } else if (userType == UserType.students && studentId != null) {
        MockData.students.add(Student(
          userId: newUserId,
          studentId: studentId,
          yearLevel: yearLevel,
          section: section,
          course: course,
        ));
      }
      
      // Update state
      state = state.copyWith(
        users: List.from(MockData.users),
        teachers: List.from(MockData.teachers),
        students: List.from(MockData.students),
        isLoading: false,
      );
      
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
    String? course,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Update user in mock data
      final userIndex = MockData.users.indexWhere((u) => u.userId == user.userId);
      if (userIndex != -1) {
        MockData.users[userIndex] = user.copyWith(
          email: email ?? user.email,
          fullName: fullName ?? user.fullName,
          contactNumber: contactNumber ?? user.contactNumber,
          emergencyContactNumber: emergencyContactNumber ?? user.emergencyContactNumber,
          status: status ?? user.status,
          updatedAt: DateTime.now(),
        );
      }
      
      // Update teacher data if applicable
      if (department != null) {
        final teacherIndex = MockData.teachers.indexWhere((t) => t.userId == user.userId);
        if (teacherIndex != -1) {
          MockData.teachers[teacherIndex] = MockData.teachers[teacherIndex].copyWith(department: department);
        }
      }
      
      // Update student data if applicable
      if (studentId != null || yearLevel != null || section != null || course != null) {
        final studentIndex = MockData.students.indexWhere((s) => s.userId == user.userId);
        if (studentIndex != -1) {
          MockData.students[studentIndex] = MockData.students[studentIndex].copyWith(
            studentId: studentId ?? MockData.students[studentIndex].studentId,
            yearLevel: yearLevel ?? MockData.students[studentIndex].yearLevel,
            section: section ?? MockData.students[studentIndex].section,
            course: course ?? MockData.students[studentIndex].course,
          );
        }
      }
      
      // Update state
      state = state.copyWith(
        users: List.from(MockData.users),
        teachers: List.from(MockData.teachers),
        students: List.from(MockData.students),
        isLoading: false,
      );
      
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
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Remove from mock data
      MockData.users.removeWhere((u) => u.userId == user.userId);
      MockData.userRoles.removeWhere((ur) => ur.userId == user.userId);
      MockData.teachers.removeWhere((t) => t.userId == user.userId);
      MockData.students.removeWhere((s) => s.userId == user.userId);
      
      // Update state
      state = state.copyWith(
        users: List.from(MockData.users),
        teachers: List.from(MockData.teachers),
        students: List.from(MockData.students),
        isLoading: false,
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
