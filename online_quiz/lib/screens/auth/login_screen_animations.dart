import 'package:flutter/material.dart';

/// Mixin that provides staggered animations for the login screen
mixin LoginScreenAnimations<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  // Animation controllers for staggered animations
  late AnimationController logoController;
  late AnimationController titleController;
  late AnimationController subtitleController;
  late AnimationController formController;
  late AnimationController forgotPasswordController;

  // Animations
  late Animation<double> logoFadeAnimation;
  late Animation<Offset> logoSlideAnimation;
  late Animation<double> titleFadeAnimation;
  late Animation<Offset> titleSlideAnimation;
  late Animation<double> subtitleFadeAnimation;
  late Animation<Offset> subtitleSlideAnimation;
  late Animation<double> formFadeAnimation;
  late Animation<Offset> formSlideAnimation;
  late Animation<double> forgotPasswordFadeAnimation;
  late Animation<Offset> forgotPasswordSlideAnimation;

  /// Initialize all animation controllers and animations
  void initializeLoginAnimations() {
    _createAnimationControllers();
    _createAnimations();
  }

  /// Start the staggered animation sequence
  void startLoginAnimations() {
    // Wait for the widget to be fully built before starting animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStaggeredAnimations();
    });
  }

  /// Run the actual staggered animation sequence
  void _runStaggeredAnimations() async {
    // Start animations with minimal delays for better performance
    logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 100));
    titleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 100));
    subtitleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 150));
    formController.forward();
    
    await Future.delayed(const Duration(milliseconds: 100));
    forgotPasswordController.forward();
  }

  /// Dispose all animation controllers
  void disposeLoginAnimations() {
    logoController.dispose();
    titleController.dispose();
    subtitleController.dispose();
    formController.dispose();
    forgotPasswordController.dispose();
  }

  /// Create animation controllers with consistent duration
  void _createAnimationControllers() {
    const duration = Duration(milliseconds: 800);
    
    logoController = AnimationController(duration: duration, vsync: this);
    titleController = AnimationController(duration: duration, vsync: this);
    subtitleController = AnimationController(duration: duration, vsync: this);
    formController = AnimationController(duration: duration, vsync: this);
    forgotPasswordController = AnimationController(duration: duration, vsync: this);
  }

  /// Create all fade and slide animations
  void _createAnimations() {
    // Logo animations
    logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: logoController,
      curve: Curves.easeOut,
    ));

    logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: logoController,
      curve: Curves.easeOutCubic,
    ));

    // Title animations
    titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: titleController,
      curve: Curves.easeOut,
    ));

    titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: titleController,
      curve: Curves.easeOutCubic,
    ));

    // Subtitle animations
    subtitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: subtitleController,
      curve: Curves.easeOut,
    ));

    subtitleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: subtitleController,
      curve: Curves.easeOutCubic,
    ));

    // Form animations
    formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: formController,
      curve: Curves.easeOut,
    ));

    formSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: formController,
      curve: Curves.easeOutCubic,
    ));

    // Forgot password animations
    forgotPasswordFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: forgotPasswordController,
      curve: Curves.easeOut,
    ));

    forgotPasswordSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: forgotPasswordController,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Helper method to create animated widget with fade and slide
  Widget createAnimatedWidget({
    required Widget child,
    required Animation<double> fadeAnimation,
    required Animation<Offset> slideAnimation,
  }) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}