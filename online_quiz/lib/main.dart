import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_screen.dart';
import 'screens/home/teacher_home_screen.dart';
import 'screens/home/admin_home_screen.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';
import 'providers/auth_provider.dart';

extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return withValues(alpha: 1);
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
    return MaterialApp(
      title: 'ACLC Online Quiz',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.main: (context) => const MainScreen(),
        AppRoutes.teacherHome: (context) => const TeacherHomeScreen(),
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
      // Navigation will be handled in the build method
      print('AUTH_WRAPPER: initState called');
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    print('AUTH_WRAPPER: Building with state - authenticated: ${authState.isAuthenticated}, user: ${authState.user?.userType ?? 'none'}, loading: ${authState.isLoading}, initialized: ${authState.isInitialized}');
    
    // SIMPLIFIED APPROACH: Use MaterialApp.router with GoRouter for navigation
    // Instead of trying to navigate from within the build method or using ref.listen,
    // we'll directly return the appropriate screen based on auth state
    
    // Show loading indicator while auth state is being determined
    if (!authState.isInitialized) {
      print('AUTH_WRAPPER: Auth not initialized yet, showing loading indicator');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // If authenticated, return the appropriate screen based on user role
    if (authState.isAuthenticated && authState.user != null) {
      final userType = authState.user!.userType;
      print('AUTH_WRAPPER: User authenticated as $userType, returning appropriate screen');
      
      switch (userType) {
        case 'teacher':
          return const TeacherHomeScreen();
        case 'admin':
          return const AdminHomeScreen();
        case 'student':
        default:
          return const MainScreen();
      }
    }
    
    // For unauthenticated users, show login screen directly
    // This is a key change - we're bypassing the onboarding screen for simplicity
    print('AUTH_WRAPPER: User not authenticated, returning login screen');
    return const LoginScreen();
  }
}
