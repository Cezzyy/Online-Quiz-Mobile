import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors for the university theme
  static const Color primaryColor = Color(0xFF1565C0); // Blue
  static const Color secondaryColor = Color(0xFF0D47A1); // Dark Blue
  static const Color accentColor = Color(0xFF42A5F5); // Light Blue
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);

  // Pre-built and cached theme data for instant switching
  static late final ThemeData _lightTheme;
  static late final ThemeData _darkTheme;
  static bool _isInitialized = false;

  // Pre-built color schemes for instant access
  static late final ColorScheme _lightColorScheme;
  static late final ColorScheme _darkColorScheme;

  // Theme-aware color cache
  static final Map<String, Color> _lightColors = {};
  static final Map<String, Color> _darkColors = {};

  // Initialize themes once at app startup with maximum optimization
  static void initialize() {
    if (_isInitialized) return;
    
    // Pre-build color schemes with caching
    _lightColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );
    
    _darkColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );

    // Pre-build complete themes with all components
    _lightTheme = _buildLightTheme();
    _darkTheme = _buildDarkTheme();

    // Pre-cache theme-aware colors for instant access
    _initializeColorCache();
    
    // Pre-warm theme data to ensure instant switching
    _preWarmThemeData();
    
    _isInitialized = true;
  }

  // Pre-warm theme data for instant access
  static void _preWarmThemeData() {
    // Access key theme properties to ensure they're cached
    _lightTheme.colorScheme;
    _lightTheme.appBarTheme;
    _lightTheme.elevatedButtonTheme;
    _lightTheme.inputDecorationTheme;
    _lightTheme.cardTheme;
    _lightTheme.bottomNavigationBarTheme;
    
    _darkTheme.colorScheme;
    _darkTheme.appBarTheme;
    _darkTheme.elevatedButtonTheme;
    _darkTheme.inputDecorationTheme;
    _darkTheme.cardTheme;
    _darkTheme.bottomNavigationBarTheme;
  }

  // Initialize color cache for instant theme-aware color access
  static void _initializeColorCache() {
    // Light theme colors
    _lightColors['textColor'] = _lightColorScheme.onSurface;
    _lightColors['secondaryTextColor'] = _lightColorScheme.onSurface.withValues(alpha: 0.6);
    _lightColors['surfaceColor'] = _lightColorScheme.surface;
    _lightColors['cardColor'] = _lightColorScheme.surface;
    _lightColors['dividerColor'] = _lightColorScheme.outline.withValues(alpha: 0.2);
    _lightColors['backgroundColor'] = _lightColorScheme.surface;
    _lightColors['primaryColor'] = _lightColorScheme.primary;
    _lightColors['onPrimaryColor'] = _lightColorScheme.onPrimary;

    // Dark theme colors
    _darkColors['textColor'] = _darkColorScheme.onSurface;
    _darkColors['secondaryTextColor'] = _darkColorScheme.onSurface.withValues(alpha: 0.6);
    _darkColors['surfaceColor'] = _darkColorScheme.surface;
    _darkColors['cardColor'] = _darkColorScheme.surface;
    _darkColors['dividerColor'] = _darkColorScheme.outline.withValues(alpha: 0.2);
    _darkColors['backgroundColor'] = _darkColorScheme.surface;
    _darkColors['primaryColor'] = _darkColorScheme.primary;
    _darkColors['onPrimaryColor'] = _darkColorScheme.onPrimary;
  }

  // Optimized theme-aware color getters using cached colors
  static Color getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors['textColor']! : _lightColors['textColor']!;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors['secondaryTextColor']! : _lightColors['secondaryTextColor']!;
  }

  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors['surfaceColor']! : _lightColors['surfaceColor']!;
  }

  static Color getCardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors['cardColor']! : _lightColors['cardColor']!;
  }

  static Color getDividerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors['dividerColor']! : _lightColors['dividerColor']!;
  }

  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors['backgroundColor']! : _lightColors['backgroundColor']!;
  }

  static Color getPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors['primaryColor']! : _lightColors['primaryColor']!;
  }

  static Color getOnPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkColors['onPrimaryColor']! : _lightColors['onPrimaryColor']!;
  }

  static Color getQuizTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return const Color(0xFF2196F3); // Blue
      case 'course':
        return const Color(0xFF4CAF50); // Green
      case 'reminder':
        return const Color(0xFFFF9800); // Orange
      case 'system':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF2196F3);
    }
  }

  static Color getCourseColor(String courseCode) {
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF009688), // Teal
    ];
    return colors[courseCode.hashCode % colors.length];
  }

  static Color getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF4CAF50); // Green
    if (score >= 60) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  // Pre-built light theme for instant access
  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Pre-built dark theme for instant access
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF121212),
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Instant theme access - no rebuilding required
  static ThemeData get lightTheme {
    if (!_isInitialized) initialize();
    return _lightTheme;
  }

  static ThemeData get darkTheme {
    if (!_isInitialized) initialize();
    return _darkTheme;
  }

  // Performance optimization: Get theme by mode instantly
  static ThemeData getThemeByMode(ThemeMode mode, Brightness systemBrightness) {
    if (!_isInitialized) initialize();
    
    switch (mode) {
      case ThemeMode.light:
        return _lightTheme;
      case ThemeMode.dark:
        return _darkTheme;
      case ThemeMode.system:
        return systemBrightness == Brightness.dark ? _darkTheme : _lightTheme;
    }
  }

  // Force theme pre-computation for maximum performance
  static void precomputeThemes() {
    if (!_isInitialized) initialize();
    
    // Force computation of all theme properties
    _lightTheme.textTheme;
    _lightTheme.colorScheme;
    _lightTheme.appBarTheme;
    _lightTheme.elevatedButtonTheme;
    _lightTheme.inputDecorationTheme;
    _lightTheme.cardTheme;
    _lightTheme.bottomNavigationBarTheme;
    
    _darkTheme.textTheme;
    _darkTheme.colorScheme;
    _darkTheme.appBarTheme;
    _darkTheme.elevatedButtonTheme;
    _darkTheme.inputDecorationTheme;
    _darkTheme.cardTheme;
    _darkTheme.bottomNavigationBarTheme;
    
    // Force computation of all cached colors
    for (final color in _lightColors.values) {
      (color.r * 255.0).round() & 0xff; // Access color components to force computation
    }
    for (final color in _darkColors.values) {
      (color.r * 255.0).round() & 0xff; // Access color components to force computation
    }
    
    // Force computation of quiz type colors
    getQuizTypeColor('quiz');
    getQuizTypeColor('course');
    getQuizTypeColor('reminder');
    getQuizTypeColor('system');
  }

  // Check if themes are ready for instant switching
  static bool get isOptimized => _isInitialized;
}