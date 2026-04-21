import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/biometric_lock_screen.dart';
import 'screens/home/main_screen.dart';
import 'screens/home/teacher_main_screen.dart';
import 'screens/home/admin_main_screen.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/local_auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_profile_provider.dart';
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

  await Future.wait([
    Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    ),
    LocalNotificationService().initialize(),
    Future(() {
      AppTheme.initialize();
      AppTheme.precomputeThemes();
    }),
  ]);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    DeadlineReminderService().startPeriodicChecks();
  });

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
      navigatorKey: NotificationNavigationService.navigatorKey,
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

class _AuthWrapperState extends ConsumerState<AuthWrapper> with WidgetsBindingObserver {
  bool _hasShownSplash = false;
  bool _isAppInBackground = false;
  bool _hasCompletedInitialAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    Future.microtask(() async {
      await ref.read(authProvider.notifier).initialize();
      
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated && authState.user != null) {
        debugPrint('User is authenticated on app start - locking app');
        ref.read(localAuthProvider.notifier).lockApp();
        // Reset user profile to loading state
        ref.read(userProfileProvider.notifier).resetToLoading();
      } else {
        debugPrint('User is not authenticated - no lock needed');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final authState = ref.read(authProvider);
    final localAuthState = ref.read(localAuthProvider);
    if (!authState.isAuthenticated || !_hasCompletedInitialAuth) return;

    if (localAuthState.isInQuiz) {
      debugPrint('User is in quiz - skipping lock');
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        debugPrint('App going to background');
        _isAppInBackground = true;
        break;
      case AppLifecycleState.resumed:
        debugPrint('App resumed, _isAppInBackground: $_isAppInBackground');
        if (_isAppInBackground && !localAuthState.isLocked) {
          _isAppInBackground = false;
          debugPrint('Locking app on resume');
          ref.read(localAuthProvider.notifier).lockApp();
          // Reset user profile to loading state
          ref.read(userProfileProvider.notifier).resetToLoading();
        } else if (_isAppInBackground && localAuthState.isLocked) {
          debugPrint('App already locked, skipping duplicate lock');
          _isAppInBackground = false;
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final localAuthState = ref.watch(localAuthProvider);

    if (!authState.isInitialized && !_hasShownSplash) {
      _hasShownSplash = true;
      return const SplashScreen();
    }
    if (authState.isAuthenticated &&
        authState.user != null &&
        authState.role != null) {
      if (localAuthState.isLocked) {
        return const BiometricLockScreen();
      }

      // Reset background flag when app is unlocked
      if (_isAppInBackground) {
        debugPrint('App unlocked, resetting background flag');
        _isAppInBackground = false;
      }

      if (!_hasCompletedInitialAuth) {
        debugPrint('Initial authentication completed');
        _hasCompletedInitialAuth = true;
      }
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

    return const LoginScreen();
  }
}
