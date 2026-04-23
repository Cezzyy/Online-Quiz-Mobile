/// Utility class for converting technical error messages into user-friendly messages
class ErrorMessages {
  /// Converts a technical error message into a user-friendly message
  static String getUserFriendlyMessage(String? error) {
    if (error == null || error.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    final errorLower = error.toLowerCase();

    // Network/Connection errors
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('failed to connect') ||
        errorLower.contains('socketexception')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    // Authentication errors
    if (errorLower.contains('unauthorized') ||
        errorLower.contains('authentication') ||
        errorLower.contains('token') ||
        errorLower.contains('session expired')) {
      return 'Your session has expired. Please log in again.';
    }

    // Permission errors
    if (errorLower.contains('permission') ||
        errorLower.contains('forbidden') ||
        errorLower.contains('access denied')) {
      return 'You don\'t have permission to access this content.';
    }

    // Database/Supabase errors
    if (errorLower.contains('supabase') ||
        errorLower.contains('postgres') ||
        errorLower.contains('database') ||
        errorLower.contains('query')) {
      return 'Unable to load data. Please try again later.';
    }

    // Server errors
    if (errorLower.contains('500') ||
        errorLower.contains('internal server') ||
        errorLower.contains('server error')) {
      return 'Server is temporarily unavailable. Please try again later.';
    }

    // Not found errors
    if (errorLower.contains('404') ||
        errorLower.contains('not found')) {
      return 'The requested content could not be found.';
    }

    // Timeout errors
    if (errorLower.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Data format errors
    if (errorLower.contains('format') ||
        errorLower.contains('parse') ||
        errorLower.contains('invalid')) {
      return 'Unable to process data. Please try again.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Common error messages for specific scenarios
  static const String noInternet = 'No internet connection. Please check your network settings.';
  static const String loadingFailed = 'Failed to load data. Please try again.';
  static const String sessionExpired = 'Your session has expired. Please log in again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'Something went wrong. Please try again.';
}
