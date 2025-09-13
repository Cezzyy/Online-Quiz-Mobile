import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/new_user.dart';
import '../data/new_mock_data.dart';

// Authentication state class
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// Authentication notifier class
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {

    state = state.copyWith(isLoading: true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      
      // For now, start with no authenticated user
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
      );

    } catch (e) {

      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: 'Failed to initialize authentication: $e',
      );
    }
  }

  // Login method
  Future<bool> login(String username, String password) async {

    state = state.copyWith(isLoading: true, clearError: true);
    
    try {

      await Future.delayed(const Duration(milliseconds: 300));
      
      // Validate credentials (mock data for early development)
      final user = NewMockData.getUserByCredentials(username, password);
      
      if (user != null) {
        // Update state with authenticated user
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
          clearError: true,
        );
        
        return true;
      } else {
        // Invalid credentials
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid email or password',
        );
        return false;
      }
    } catch (e) {

      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: $e',
      );
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {

    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      

      state = const AuthState(isInitialized: true);

    } catch (e) {

      state = state.copyWith(
        isLoading: false,
        error: 'Logout failed: $e',
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Public initialize method
  Future<void> initialize() async {
    await _initializeAuth();
  }

  // Check if user is authenticated
  bool get isLoggedIn => state.isAuthenticated && state.user != null;

  // Get current user
  User? get currentUser => state.user;

  // Get available mock credentials for development
  static Map<String, Map<String, dynamic>> get mockCredentials => NewMockData.mockCredentials;
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});