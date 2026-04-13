import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_auth_service.dart';

/// State for local authentication
class LocalAuthState {
  final bool isAuthenticated;
  final bool isLocked;
  final bool isAuthenticating;
  final String? error;
  final DateTime? lastAuthTime;
  final Map<String, dynamic>? authInfo;
  final bool isInQuiz; // Track if user is taking a quiz
  final bool shouldReloadData; // Flag to indicate data should be reloaded after unlock

  const LocalAuthState({
    this.isAuthenticated = false,
    this.isLocked = false,
    this.isAuthenticating = false,
    this.error,
    this.lastAuthTime,
    this.authInfo,
    this.isInQuiz = false,
    this.shouldReloadData = false,
  });

  LocalAuthState copyWith({
    bool? isAuthenticated,
    bool? isLocked,
    bool? isAuthenticating,
    String? error,
    DateTime? lastAuthTime,
    Map<String, dynamic>? authInfo,
    bool? isInQuiz,
    bool? shouldReloadData,
    bool clearError = false,
  }) {
    return LocalAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLocked: isLocked ?? this.isLocked,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      error: clearError ? null : (error ?? this.error),
      lastAuthTime: lastAuthTime ?? this.lastAuthTime,
      authInfo: authInfo ?? this.authInfo,
      isInQuiz: isInQuiz ?? this.isInQuiz,
      shouldReloadData: shouldReloadData ?? this.shouldReloadData,
    );
  }
}

/// Notifier for local authentication state
class LocalAuthNotifier extends StateNotifier<LocalAuthState> {
  final LocalAuthService _localAuthService = LocalAuthService();

  LocalAuthNotifier() : super(const LocalAuthState()) {
    _initialize();
  }

  /// Initialize authentication info
  Future<void> _initialize() async {
    final authInfo = await _localAuthService.getAuthenticationInfo();
    state = state.copyWith(authInfo: authInfo);
  }

  /// Lock the app (requires authentication to unlock)
  void lockApp() {
    debugPrint('LocalAuthProvider: Locking app');
    state = state.copyWith(
      isLocked: true,
      isAuthenticated: false,
      shouldReloadData: true, // Flag to indicate data should be reloaded
    );
  }

  /// Unlock the app after successful authentication
  void unlockApp() {
    debugPrint('LocalAuthProvider: Unlocking app');
    state = state.copyWith(
      isLocked: false,
      isAuthenticated: true,
      lastAuthTime: DateTime.now(),
      shouldReloadData: false, // Reset the flag
      clearError: true,
    );
  }

  /// Authenticate for app resume
  Future<bool> authenticateOnAppResume() async {
    state = state.copyWith(isAuthenticating: true, clearError: true);

    try {
      final success = await _localAuthService.authenticateOnAppResume();
      
      if (success) {
        unlockApp();
      } else {
        state = state.copyWith(
          isAuthenticating: false,
          error: 'Authentication failed',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isAuthenticating: false,
        error: 'Authentication error: $e',
      );
      return false;
    }
  }

  /// Authenticate for quiz
  Future<bool> authenticateForQuiz(String quizTitle) async {
    state = state.copyWith(isAuthenticating: true, clearError: true);

    try {
      final success = await _localAuthService.authenticateForQuiz(quizTitle);
      
      state = state.copyWith(
        isAuthenticating: false,
        clearError: success,
      );

      if (!success) {
        state = state.copyWith(
          error: 'Authentication required to start quiz',
        );
      } else {
        // Mark that user is now in a quiz
        state = state.copyWith(isInQuiz: true);
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isAuthenticating: false,
        error: 'Authentication error: $e',
      );
      return false;
    }
  }

  /// Mark quiz as started (prevent locking during quiz)
  void startQuiz() {
    debugPrint('LocalAuthProvider: Starting quiz - disabling auto-lock');
    state = state.copyWith(isInQuiz: true);
  }

  /// Mark quiz as ended (re-enable locking)
  void endQuiz() {
    debugPrint('LocalAuthProvider: Ending quiz - re-enabling auto-lock');
    state = state.copyWith(isInQuiz: false);
  }

  /// Test authentication (for settings)
  Future<bool> testAuthentication() async {
    state = state.copyWith(isAuthenticating: true, clearError: true);

    try {
      final success = await _localAuthService.testAuthentication();
      
      state = state.copyWith(
        isAuthenticating: false,
        clearError: success,
      );

      if (!success) {
        state = state.copyWith(
          error: 'Authentication test failed',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isAuthenticating: false,
        error: 'Authentication error: $e',
      );
      return false;
    }
  }

  /// Refresh authentication info
  Future<void> refreshAuthInfo() async {
    final authInfo = await _localAuthService.getAuthenticationInfo();
    state = state.copyWith(authInfo: authInfo);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Check if authentication is required based on time elapsed
  bool shouldRequireAuth({Duration timeout = const Duration(minutes: 5)}) {
    if (state.lastAuthTime == null) return true;
    
    final elapsed = DateTime.now().difference(state.lastAuthTime!);
    return elapsed > timeout;
  }
}

/// Provider for local authentication
final localAuthProvider = StateNotifierProvider<LocalAuthNotifier, LocalAuthState>(
  (ref) => LocalAuthNotifier(),
);

/// Convenience providers
final isAppLockedProvider = Provider<bool>((ref) {
  return ref.watch(localAuthProvider).isLocked;
});

final isAuthenticatingProvider = Provider<bool>((ref) {
  return ref.watch(localAuthProvider).isAuthenticating;
});

final authInfoProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(localAuthProvider).authInfo;
});
