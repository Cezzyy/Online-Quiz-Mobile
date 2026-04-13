import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Service for handling local biometric authentication
/// Supports fingerprint, face recognition, and fallback to device credentials (PIN/pattern)
class LocalAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if the device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Check if device has biometrics enrolled
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Get human-readable authentication method
  Future<String> getAuthenticationMethod() async {
    final biometrics = await getAvailableBiometrics();
    
    if (biometrics.contains(BiometricType.face)) {
      return 'Face Recognition';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris Scan';
    } else {
      return 'Device PIN/Pattern';
    }
  }

  /// Main authentication method with sticky auth and fallback
  /// This is the primary method to use throughout the app
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
  }) async {
    try {
      debugPrint('LocalAuth: authenticate() called with reason: $reason');
      
      // Check if device supports authentication
      final isSupported = await isDeviceSupported();
      debugPrint('LocalAuth: Device supported: $isSupported');
      
      if (!isSupported) {
        debugPrint('LocalAuth: Device does not support authentication');
        throw PlatformException(
          code: 'NotAvailable',
          message: 'Device does not support authentication',
        );
      }

      debugPrint('LocalAuth: Calling _localAuth.authenticate()...');
      
      // Authenticate with biometrics or device credentials
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
      );

      debugPrint('LocalAuth: Authentication result: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('LocalAuth: PlatformException: ${e.code} - ${e.message}');
      // Handle specific error cases
      switch (e.code) {
        case 'NotAvailable':
        case 'NotEnrolled':
          // No biometrics enrolled, but device credentials might be available
          return false;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          // Too many failed attempts
          return false;
        case 'PasscodeNotSet':
          // No device credentials set up
          return false;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('LocalAuth: General exception: $e');
      return false;
    }
  }

  /// Authenticate for app resume (when app comes to foreground)
  Future<bool> authenticateOnAppResume() async {
    try {
      // First check if device is supported
      final isSupported = await isDeviceSupported();
      debugPrint('LocalAuth: Device supported: $isSupported');
      
      if (!isSupported) {
        debugPrint('LocalAuth: Device does not support authentication');
        return false;
      }

      // Check available biometrics
      final biometrics = await getAvailableBiometrics();
      debugPrint('LocalAuth: Available biometrics: $biometrics');

      return await authenticate(
        reason: 'Authenticate to continue using the app',
        useErrorDialogs: true,
      );
    } catch (e) {
      debugPrint('LocalAuth: Error in authenticateOnAppResume: $e');
      return false;
    }
  }

  /// Authenticate before taking a quiz
  Future<bool> authenticateForQuiz(String quizTitle) async {
    return await authenticate(
      reason: 'Authenticate to start "$quizTitle"',
      useErrorDialogs: true,
    );
  }

  /// Test authentication (for settings screen)
  Future<bool> testAuthentication() async {
    return await authenticate(
      reason: 'Test your authentication setup',
      useErrorDialogs: true,
    );
  }

  /// Get detailed authentication capability info
  Future<Map<String, dynamic>> getAuthenticationInfo() async {
    final isSupported = await isDeviceSupported();
    final canCheckBiometrics = await isBiometricAvailable();
    final availableBiometrics = await getAvailableBiometrics();
    final authMethod = await getAuthenticationMethod();

    return {
      'isSupported': isSupported,
      'canCheckBiometrics': canCheckBiometrics,
      'availableBiometrics': availableBiometrics,
      'authenticationMethod': authMethod,
      'hasFaceRecognition': availableBiometrics.contains(BiometricType.face),
      'hasFingerprint': availableBiometrics.contains(BiometricType.fingerprint),
      'hasIris': availableBiometrics.contains(BiometricType.iris),
    };
  }
}
