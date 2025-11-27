import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_screen.dart';
import 'screens/home/teacher_main_screen.dart';
import 'screens/home/admin_main_screen.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'services/local_notification_service.dart';
import 'services/notification_navigation_service.dart';
import 'services/deadline_reminder_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Local Notification Service
  await LocalNotificationService().initialize();

  // Start deadline reminder service for quiz notifications
  DeadlineReminderService().startPeriodicChecks();

  // Initialize and precompute themes at app startup for instant switching
  AppTheme.initialize();
  AppTheme.precomputeThemes();

  runApp(const ProviderScope(child: ACLCQuizApp()));
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
      // Global navigator key for notification navigation
      navigatorKey: NotificationNavigationService.navigatorKey,
      // Minimize theme transition duration for near-instant switching
      themeAnimationDuration: const Duration(milliseconds: 50),
      themeAnimationCurve: Curves.linear,
      home: const AuthWrapper(),
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.main: (context) => const MainScreen(),
        AppRoutes.teacherHome: (context) => const TeacherMainScreen(),
        AppRoutes.adminMain: (context) => const AdminMainScreen(),
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
  bool _hasShownSplash = false;

  @override
  void initState() {
    super.initState();
    // Initialize auth and check for existing session
    Future.microtask(() {
      ref.read(authProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show splash screen only once on initial app startup
    if (!authState.isInitialized && !_hasShownSplash) {
      _hasShownSplash = true;
      return const SplashScreen();
    }

    // If authenticated, return the appropriate screen based on user role
    if (authState.isAuthenticated &&
        authState.user != null &&
        authState.role != null) {
      switch (authState.role?.toLowerCase()) {
        case 'teacher':
          return const TeacherMainScreen();
        case 'admin':
          return const AdminMainScreen();
        case 'student':
        default:
          return const MainScreen();
      }
    }

    // Show login screen for unauthenticated users
    return const LoginScreen();
  }
}
