import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// Authentication state class
class AuthState {
  final User? user;
  final String? role;
  final Map<String, dynamic>? profile;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.role,
    this.profile,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({
    User? user,
    String? role,
    Map<String, dynamic>? profile,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      role: clearUser ? null : (role ?? this.role),
      profile: clearUser ? null : (profile ?? this.profile),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// Authentication notifier class
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(const AuthState()) {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Check for existing session
      final session = await _authService.getCurrentSession();
      
      if (session != null) {
        state = state.copyWith(
          user: session['user'] as User?,
          role: session['role'] as String?,
          profile: session['profile'] as Map<String, dynamic>?,
          isAuthenticated: true,
          isLoading: false,
          isInitialized: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: 'Failed to initialize authentication: $e',
      );
    }
  }

  // Login method
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final result = await _authService.login(email, password);
      
      // Update state with authenticated user
      state = state.copyWith(
        user: result['user'] as User,
        role: result['role'] as String,
        profile: result['profile'] as Map<String, dynamic>?,
        isAuthenticated: true,
        isLoading: false,
        clearError: true,
      );
      
      return true;
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = 'Invalid email or password';
      if (e.toString().contains('Database error')) {
        errorMessage = 'Unable to connect to server. Please try again.';
      } else if (e.toString().contains('Invalid email or password')) {
        errorMessage = 'Invalid email or password';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await _authService.logout();
      
      // Clear the auth state completely
      state = const AuthState(
        isInitialized: true,
        isAuthenticated: false,
        user: null,
        role: null,
        profile: null,
        isLoading: false,
        error: null,
      );
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

  // Get current user role
  String? get currentUserRole => state.role;
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