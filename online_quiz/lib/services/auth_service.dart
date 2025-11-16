import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart' as models;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
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

      if (response == null) {
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

      return result;
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } on FunctionException {
      throw Exception('RPC function error: Function may not exist or has wrong parameters');
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
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
}
