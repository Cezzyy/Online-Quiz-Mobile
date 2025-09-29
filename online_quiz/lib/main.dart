import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_screen.dart';
import 'screens/home/teacher_main_screen.dart';
import 'screens/home/admin_home_screen.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'data/mock_data.dart';

extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return Color.fromARGB(
      ((alpha ?? 1.0) * 255).round(),
      (r * 255.0).round() & 0xff,
      (g * 255.0).round() & 0xff,
      (b * 255.0).round() & 0xff,
    );
  }
}

void main() {
  runApp(
    const ProviderScope(
      child: ACLCQuizApp(),
    ),
  );
}

class ACLCQuizApp extends ConsumerWidget {
  const ACLCQuizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    
    return MaterialApp(
      title: 'ACLC Online Quiz',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsState.themeMode,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.main: (context) => const MainScreen(),
        AppRoutes.teacherHome: (context) => const TeacherMainScreen(),
        AppRoutes.adminHome: (context) => const AdminHomeScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auth and check for existing session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
    });
  }
  


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // Show splash screen only during initial app startup (not during login)
    if (!authState.isInitialized) {
      return const SplashScreen();
    }
    
    // If authenticated, return the appropriate screen based on user role
    if (authState.isAuthenticated && authState.user != null) {
      final userRole = MockData.getUserRole(authState.user!.userId);
      
      switch (userRole?.toLowerCase()) {
        case 'teacher':
          return const TeacherMainScreen();
        case 'admin':
          return const AdminHomeScreen();
        case 'student':
        default:
          return const MainScreen();
      }
    }
    
    // For unauthenticated users, show login screen
    return const LoginScreen();
  }
}
