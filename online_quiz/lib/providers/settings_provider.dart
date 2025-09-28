import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Settings state class to hold all app settings
class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool isLoading;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.isLoading = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? isLoading,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Helper getters
  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isLightMode => themeMode == ThemeMode.light;
  bool get isSystemMode => themeMode == ThemeMode.system;
}

// Settings provider notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  static const String _themeModeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';
  
  // Debouncing timer for saving settings
  Timer? _saveTimer;
  static const Duration _saveDebounceDuration = Duration(milliseconds: 500);

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
      final themeMode = ThemeMode.values[themeModeIndex];
      
      // Load other settings
      final notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      
      state = SettingsState(
        themeMode: themeMode,
        notificationsEnabled: notificationsEnabled,
        isLoading: false,
      );
    } catch (e) {
      // If loading fails, use default settings
      state = state.copyWith(isLoading: false);
    }
  }

  // Save settings to SharedPreferences with debouncing
  void _debouncedSaveSettings() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounceDuration, () async {
      await _saveSettingsImmediately();
    });
  }

  // Immediate save for critical operations
  Future<void> _saveSettingsImmediately() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, state.themeMode.index);
      await prefs.setBool(_notificationsKey, state.notificationsEnabled);
    } catch (e) {
      // Handle save error silently
    }
  }

  // Update theme mode with optimized performance
  void setThemeMode(ThemeMode themeMode) {
    // Update state immediately for instant UI response
    state = state.copyWith(themeMode: themeMode);
    // Save to disk with debouncing to avoid blocking UI
    _debouncedSaveSettings();
  }

  // Toggle dark mode
  void toggleDarkMode(bool isDarkMode) {
    final themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(themeMode);
  }

  // Update notifications setting
  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
    _debouncedSaveSettings();
  }

  // Reset all settings to defaults
  Future<void> resetSettings() async {
    state = const SettingsState();
    await _saveSettingsImmediately(); // Use immediate save for reset
  }

  // Dispose method to clean up timer
  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);