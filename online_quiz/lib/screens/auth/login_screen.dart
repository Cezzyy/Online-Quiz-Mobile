import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildAnimatedHeader(),
              const SizedBox(height: 40),
              _buildAnimatedLoginCard(_isLoggingIn),
              const SizedBox(height: 24),
              _buildAnimatedForgotPassword(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Column(
      children: [
        // Animated Logo
        createAnimatedWidget(
          fadeAnimation: logoFadeAnimation,
          slideAnimation: logoSlideAnimation,
          child: Image.asset(
            'assets/images/aclclogo-nobg.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.school,
                size: 130,
                color: Theme.of(context).primaryColor,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        // Animated Title
        createAnimatedWidget(
          fadeAnimation: titleFadeAnimation,
          slideAnimation: titleSlideAnimation,
          child: Text(
            'ACLC Online Quiz',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              fontSize: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Animated Subtitle
        createAnimatedWidget(
          fadeAnimation: subtitleFadeAnimation,
          slideAnimation: subtitleSlideAnimation,
          child: Text(
            'Welcome back! Please sign in to continue',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              fontSize: 16,
            ),
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
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildLoginForm(),
            _buildErrorMessage(),
            const SizedBox(height: 32),
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
          CustomTextField(
            controller: _emailController,
            labelText: 'Username',
            hintText: 'Enter your username',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your username';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: !_isPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);
        
        if (authState.error == null) {
          return const SizedBox.shrink();
        }
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFE5E5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFDC2626),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authentication Error',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      authState.error!,
                      style: const TextStyle(
                        color: Color(0xFF7F1D1D),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(authProvider.notifier).clearError();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFFDC2626),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Need Account Access?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All accounts are managed by the school administration.\nPlease contact your admin for login credentials.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final username = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      
      
      try {
        // Set loading state to show progress indicator
        setState(() {
          _isLoggingIn = true;
        });
        
        // Attempt login
        final success = await ref.read(authProvider.notifier).login(username, password);
        
        if (success) {

          // No need to navigate - AuthWrapper will handle it automatically
          // by returning the appropriate screen based on auth state
        } else {
          // Show error message if login failed

          if (mounted) {
            final errorMsg = ref.read(authProvider).error ?? 'Login failed';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Reset loading state
        if (mounted) {
          setState(() {
            _isLoggingIn = false;
          });
        }
      }
    }
  }
}