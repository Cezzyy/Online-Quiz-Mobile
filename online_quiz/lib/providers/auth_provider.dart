import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/mock_data.dart';

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
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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

    state = state.copyWith(isLoading: true, error: null);
    
    try {

      await Future.delayed(const Duration(milliseconds: 300));
      
      // Validate credentials using mock data
      try {
        final user = DummyData.getUserByCredentials(username, password);

        
        // Update state with authenticated user
        final newState = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
        

        state = newState;

        
        return true;
      } catch (e) {

        state = state.copyWith(
          isLoading: false,
          error: 'Invalid username or password',
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

    state = state.copyWith(isLoading: true);
    
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
    state = state.copyWith(error: null);
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
  static Map<String, Map<String, dynamic>> get mockCredentials => DummyData.mockCredentials;
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