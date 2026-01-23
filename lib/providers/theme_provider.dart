import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/theme_colors.dart';

/// Provider untuk theme colors
final themeProvider = NotifierProvider<ThemeNotifier, ThemeColors>(() {
  return ThemeNotifier();
});

/// Notifier untuk manage theme colors
class ThemeNotifier extends Notifier<ThemeColors> {
  @override
  ThemeColors build() {
    // Random theme on every app load/refresh
    final random = Random();
    final randomIndex = random.nextInt(ThemeColors.values.length);
    return ThemeColors.values[randomIndex];
  }

  /// Randomize theme to a different color
  void randomizeTheme() {
    // Get available colors (exclude current color)
    final availableColors =
        ThemeColors.values.where((c) => c != state).toList();

    // Pick random color
    final random = Random();
    final randomIndex = random.nextInt(availableColors.length);
    final newTheme = availableColors[randomIndex];

    // Update state
    state = newTheme;
  }

  /// Set specific theme color
  void setTheme(ThemeColors theme) {
    state = theme;
  }

  /// Randomize theme with animation callback
  /// Returns both old and new theme for animation overlay
  (ThemeColors oldTheme, ThemeColors newTheme) randomizeThemeWithAnimation() {
    final oldTheme = state;

    // Get available colors (exclude current color)
    final availableColors =
        ThemeColors.values.where((c) => c != state).toList();

    // Pick random color
    final random = Random();
    final randomIndex = random.nextInt(availableColors.length);
    final newTheme = availableColors[randomIndex];

    // Update state (will trigger rebuild with new theme)
    state = newTheme;

    return (oldTheme, newTheme);
  }
}
