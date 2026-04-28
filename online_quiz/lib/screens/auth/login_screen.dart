import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'login_screen_animations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin, LoginScreenAnimations {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    initializeLoginAnimations();
    startLoginAnimations();
  }

  @override
  void dispose() {
    disposeLoginAnimations();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      _buildAnimatedHeader(),
                      const Spacer(flex: 1),
                      _buildAnimatedLoginCard(_isLoggingIn),
                      const SizedBox(height: 16),
                      _buildAnimatedForgotPassword(),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated Logo
        createAnimatedWidget(
          fadeAnimation: logoFadeAnimation,
          slideAnimation: logoSlideAnimation,
          child: Image.asset(
            'assets/images/aclclogo-nobg.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.school,
                size: 100,
                color: AppTheme.primaryColor,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Animated Title
        createAnimatedWidget(
          fadeAnimation: titleFadeAnimation,
          slideAnimation: titleSlideAnimation,
          child: Text(
            'ACLC Online Quiz',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Animated Subtitle
        createAnimatedWidget(
          fadeAnimation: subtitleFadeAnimation,
          slideAnimation: subtitleSlideAnimation,
          child: Text(
            'Welcome back! Please sign in to continue',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLoginCard(bool isLoading) {
    return createAnimatedWidget(
      fadeAnimation: formFadeAnimation,
      slideAnimation: formSlideAnimation,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLoginForm(),
            const SizedBox(height: 24),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              return CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Enter your email address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  // Clear authentication error when user starts typing
                  if (authState.error != null) {
                    ref.read(authProvider.notifier).clearError();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              return CustomTextField(
                 controller: _passwordController,
                 labelText: 'Password',
                 hintText: 'Enter your password',
                 prefixIcon: Icons.lock_outline,
                 obscureText: !_isPasswordVisible,
                 onChanged: (value) {
                   // Clear authentication error when user starts typing
                   if (authState.error != null) {
                     ref.read(authProvider.notifier).clearError();
                   }
                 },
                 suffixIcon: IconButton(
                   icon: Icon(
                     _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                     color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                   ),
                   onPressed: () {
                     setState(() {
                       _isPasswordVisible = !_isPasswordVisible;
                     });
                   },
                 ),
                 validator: (value) {
                   // Check for authentication error first
                   if (authState.error != null && !_isLoggingIn) {
                     return authState.error;
                   }
                   
                   // Then check for basic validation
                   if (value == null || value.isEmpty) {
                     return 'Please enter your password';
                   }
                   if (value.length < 6) {
                     return 'Password must be at least 6 characters';
                   }
                   return null;
                 },
               );
            },
          ),
        ],
      ),
    );
  }



  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoggingIn ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoggingIn
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildAnimatedForgotPassword() {
    return createAnimatedWidget(
      fadeAnimation: forgotPasswordFadeAnimation,
      slideAnimation: forgotPasswordSlideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Need Account Access?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All accounts are managed by the school.\nPlease contact your teacher or school staff for login credentials.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear any existing errors before starting login
    ref.read(authProvider.notifier).clearError();

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final success = await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }

      if (!success) {
        // Login failed - add a small delay to ensure the auth state error is propagated
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Trigger form validation to show the error below password field
        if (mounted) {
          _formKey.currentState!.validate();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
        
        // Add a small delay to ensure the auth state error is propagated
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Trigger form validation to show the error below password field
        if (mounted) {
          _formKey.currentState!.validate();
        }
      }
    }
  }
}