import 'package:flutter/material.dart';
import '../models/theme_colors.dart';

/// InheritedWidget untuk provide current theme colors ke seluruh widget tree
/// Ini memungkinkan widget mengakses warna dynamic tanpa harus pakai Theme.of(context)
class AppColors extends InheritedWidget {
  final ColorPair colors;

  const AppColors({
    super.key,
    required this.colors,
    required super.child,
  });

  /// Access current theme colors dari context
  static ColorPair of(BuildContext context) {
    final appColors = context.dependOnInheritedWidgetOfExactType<AppColors>();
    return appColors?.colors ?? ThemeColors.teal.colors;
  }

  /// Shortcut untuk get primary color
  static Color primaryOf(BuildContext context) {
    return of(context).primary;
  }

  /// Shortcut untuk get dark color
  static Color darkOf(BuildContext context) {
    return of(context).dark;
  }

  @override
  bool updateShouldNotify(AppColors oldWidget) {
    return colors != oldWidget.colors;
  }
}
