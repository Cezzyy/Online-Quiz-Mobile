import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart' as models;
import 'activity_log_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ActivityLogService _activityLog = ActivityLogService();
  
  // SharedPreferences keys
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserData = 'auth_user_data';
  static const String _keyUserRole = 'auth_user_role';
  static const String _keyUserProfile = 'auth_user_profile';
  static const String _keyIsAuthenticated = 'auth_is_authenticated';

  // Login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Call Supabase RPC function to verify credentials and get user data
      final response = await _supabase.rpc(
        'verify_user_credentials',
        params: {
          'user_email': email,
          'user_password': password,
        },
      );

      if (response == null || (response is List && response.isEmpty)) {
        throw Exception('Invalid email or password');
      }

      // Parse user data from the first result (RPC returns array)
      final userData = (response is List) ? response[0] as Map<String, dynamic> : response as Map<String, dynamic>;
      final user = models.User.fromJson(userData);

      // Get user role
      final roleResponse = await _supabase
          .from('UserRole')
          .select('RoleId, Role!inner(Name)')
          .eq('UserId', user.userId)
          .maybeSingle();

      if (roleResponse == null) {
        throw Exception('User role not found');
      }

      final roleName = roleResponse['Role']['Name'] as String;

      // Get additional profile data based on role
      Map<String, dynamic>? profileData;
      if (roleName == 'Student') {
        profileData = await _supabase
            .from('Student')
            .select()
            .eq('UserId', user.userId)
            .maybeSingle();
      } else if (roleName == 'Teacher') {
        profileData = await _supabase
            .from('Teacher')
            .select()
            .eq('UserId', user.userId)
            .maybeSingle();
      }

      final result = {
        'user': user,
        'role': roleName,
        'profile': profileData,
      };

      // Save session to SharedPreferences
      await _saveSession(result);

      // Log successful login
      try {
        await _activityLog.logLogin(user.userId);
      } catch (e) {
        // Don't fail login if logging fails
        debugPrint('Failed to log login activity: $e');
      }

      return result;
    } on PostgrestException catch (e) {
      // Check if it's a connection/network error
      if (e.code == null || e.code == 'PGRST301' || e.code == '08000' || e.code == '08003' || e.code == '08006') {
        throw Exception('Unable to connect to server. Please check your internet connection.');
      }
      // Otherwise it's likely an authentication failure
      throw Exception('Invalid email or password');
    } on FunctionException catch (e) {
      // RPC function returned an error - likely invalid credentials
      if (e.toString().contains('verify_user_credentials') || e.details?.contains('No rows') == true) {
        throw Exception('Invalid email or password');
      }
      throw Exception('Unable to connect to server. Please try again.');
    } catch (e) {
      // Check if the error message already indicates invalid credentials
      if (e.toString().contains('Invalid email or password')) {
        rethrow;
      }
      // Generic network/connection errors
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection') ||
          e.toString().contains('Network')) {
        throw Exception('Unable to connect to server. Please check your internet connection.');
      }
      // Default to invalid credentials for other errors
      throw Exception('Invalid email or password');
    }
  }

  // Save session to SharedPreferences
  Future<void> _saveSession(Map<String, dynamic> sessionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = sessionData['user'] as models.User;
      
      await prefs.setInt(_keyUserId, user.userId);
      await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
      await prefs.setString(_keyUserRole, sessionData['role'] as String);
      
      if (sessionData['profile'] != null) {
        await prefs.setString(_keyUserProfile, jsonEncode(sessionData['profile']));
      }
      
      await prefs.setBool(_keyIsAuthenticated, true);
    } catch (e) {
      throw Exception('Failed to save session: ${e.toString()}');
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Log logout before clearing session
      final userId = prefs.getInt(_keyUserId);
      if (userId != null) {
        try {
          await _activityLog.logLogout(userId);
        } catch (e) {
          // Don't fail logout if logging fails
          debugPrint('Failed to log logout activity: $e');
        }
      }
      
      // Clear all auth-related data
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserData);
      await prefs.remove(_keyUserRole);
      await prefs.remove(_keyUserProfile);
      await prefs.remove(_keyIsAuthenticated);
      
      // Optional: Clear all preferences if needed
      // await prefs.clear();
    } catch (e) {
      throw Exception('Failed to logout: ${e.toString()}');
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsAuthenticated) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get current user session
  Future<Map<String, dynamic>?> getCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user is authenticated
      final isAuth = prefs.getBool(_keyIsAuthenticated) ?? false;
      if (!isAuth) {
        return null;
      }

      // Retrieve user data
      final userDataJson = prefs.getString(_keyUserData);
      if (userDataJson == null) {
        return null;
      }

      final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
      final user = models.User.fromJson(userData);

      // Retrieve role
      final role = prefs.getString(_keyUserRole);
      if (role == null) {
        return null;
      }

      // Retrieve profile (optional)
      Map<String, dynamic>? profile;
      final profileJson = prefs.getString(_keyUserProfile);
      if (profileJson != null) {
        profile = jsonDecode(profileJson) as Map<String, dynamic>;
      }

      return {
        'user': user,
        'role': role,
        'profile': profile,
      };
    } catch (e) {
      // If there's any error reading session, return null
      return null;
    }
  }

  /// Get all users with their roles
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('User')
          .select('''
            *,
            UserRole!inner(
              RoleId,
              Role!inner(
                RoleId,
                Name
              )
            )
          ''')
          .order('CreatedAt', ascending: false);

      final users = <Map<String, dynamic>>[];
      for (final userData in response) {
        final user = models.User.fromJson(userData);
        final roleData = userData['UserRole'];
        final roleName = roleData is List 
            ? roleData.isNotEmpty ? roleData[0]['Role']['Name'] : 'Unknown'
            : roleData['Role']['Name'];

        users.add({
          'user': user,
          'role': roleName,
        });
      }

      return users;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch users: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Get all teachers with user details
  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    try {
      final response = await _supabase
          .from('Teacher')
          .select('''
            *,
            User!inner(*)
          ''')
          .order('UserId', ascending: false);

      final teachers = <Map<String, dynamic>>[];
      for (final teacherData in response) {
        final userData = teacherData['User'];
        final user = models.User.fromJson(userData);
        
        teachers.add({
          'user': user,
          'department': teacherData['Department'],
        });
      }

      return teachers;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch teachers: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch teachers: $e');
    }
  }

  /// Get all students with user details
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final response = await _supabase
          .from('Student')
          .select('''
            *,
            User!inner(*)
          ''')
          .order('UserId', ascending: false);

      final students = <Map<String, dynamic>>[];
      for (final studentData in response) {
        final userData = studentData['User'];
        final user = models.User.fromJson(userData);
        
        students.add({
          'user': user,
          'studentId': studentData['StudentId'],
          'section': studentData['Section'],
          'yearLevel': studentData['Year_Level'],
          'course': studentData['Course'],
        });
      }

      return students;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch students: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch students: $e');
    }
  }

  /// Create a new user with role assignment
  Future<models.User> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'Student', 'Teacher', or 'Admin'
    required int createdBy,
    String? contactNumber,
    String? emergencyContactNumber,
    String? department, // For teachers
    String? studentId, // For students
    String? section, // For students
    int? yearLevel, // For students
  }) async {
    try {
      // 1. Create user record
      final userResponse = await _supabase
          .from('User')
          .insert({
            'Email': email,
            'PasswordHash': password, // Note: In production, hash the password
            'FullName': fullName,
            'ContactNumber': contactNumber ?? '',
            'EmergencyContactNumber': emergencyContactNumber ?? '',
            'Status': 'Active',
            'CreatedBy': createdBy,
            'CreatedAt': DateTime.now().toIso8601String(),
            'UpdatedAt': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final user = models.User.fromJson(userResponse);

      // 2. Get role ID
      final roleResponse = await _supabase
          .from('Role')
          .select('RoleId')
          .eq('Name', role)
          .single();

      final roleId = roleResponse['RoleId'] as int;

      // 3. Assign user role
      await _supabase
          .from('UserRole')
          .insert({
            'UserId': user.userId,
            'RoleId': roleId,
          });

      // 4. Create role-specific record
      if (role == 'Teacher') {
        await _supabase
            .from('Teacher')
            .insert({
              'UserId': user.userId,
              'Department': department ?? '',
            });
      } else if (role == 'Student') {
        await _supabase
            .from('Student')
            .insert({
              'UserId': user.userId,
              'StudentId': studentId ?? '',
              'Section': section ?? '',
              'Year_Level': yearLevel ?? 1,
            });
      }

      return user;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create user: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user details
  Future<void> updateUser({
    required int userId,
    String? email,
    String? fullName,
    String? contactNumber,
    String? emergencyContactNumber,
    String? status,
    String? department, // For teachers
    String? studentId, // For students
    String? section, // For students
    int? yearLevel, // For students
  }) async {
    try {
      // Update user record
      final updateData = <String, dynamic>{
        'UpdatedAt': DateTime.now().toIso8601String(),
      };

      if (email != null) updateData['Email'] = email;
      if (fullName != null) updateData['FullName'] = fullName;
      if (contactNumber != null) updateData['ContactNumber'] = contactNumber;
      if (emergencyContactNumber != null) updateData['EmergencyContactNumber'] = emergencyContactNumber;
      if (status != null) updateData['Status'] = status;

      await _supabase
          .from('User')
          .update(updateData)
          .eq('UserId', userId);

      // Update teacher-specific fields if provided
      if (department != null) {
        await _supabase
            .from('Teacher')
            .update({'Department': department})
            .eq('UserId', userId);
      }

      // Update student-specific fields if provided
      if (studentId != null || section != null || yearLevel != null) {
        final studentUpdateData = <String, dynamic>{};
        if (studentId != null) studentUpdateData['StudentId'] = studentId;
        if (section != null) studentUpdateData['Section'] = section;
        if (yearLevel != null) studentUpdateData['Year_Level'] = yearLevel;

        await _supabase
            .from('Student')
            .update(studentUpdateData)
            .eq('UserId', userId);
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to update user: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete a user (soft delete by setting status to Inactive)
  Future<void> deleteUser(int userId) async {
    try {
      // Soft delete - set status to Inactive
      await _supabase
          .from('User')
          .update({
            'Status': 'Inactive',
            'UpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('UserId', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete user: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get user role
  Future<String?> getUserRole(int userId) async {
    try {
      final response = await _supabase
          .from('UserRole')
          .select('Role!inner(Name)')
          .eq('UserId', userId)
          .maybeSingle();

      if (response == null) return null;

      return response['Role']['Name'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get user role: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  /// Get user with role and profile details
  Future<Map<String, dynamic>?> getUserDetails(int userId) async {
    try {
      // Get user
      final userResponse = await _supabase
          .from('User')
          .select('*')
          .eq('UserId', userId)
          .maybeSingle();

      if (userResponse == null) return null;

      final user = models.User.fromJson(userResponse);

      // Get role
      final role = await getUserRole(userId);

      // Get profile data based on role
      Map<String, dynamic>? profileData;
      if (role == 'Student') {
        profileData = await _supabase
            .from('Student')
            .select()
            .eq('UserId', userId)
            .maybeSingle();
      } else if (role == 'Teacher') {
        profileData = await _supabase
            .from('Teacher')
            .select()
            .eq('UserId', userId)
            .maybeSingle();
      }

      return {
        'user': user,
        'role': role,
        'profile': profileData,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to get user details: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get user details: $e');
    }
  }
}
