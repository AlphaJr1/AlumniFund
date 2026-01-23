import 'package:flutter/material.dart';

/// Color pair untuk tema - terdiri dari primary dan dark color
class ColorPair {
  final Color primary;
  final Color dark;
  final String name;

  const ColorPair({
    required this.primary,
    required this.dark,
    required this.name,
  });
}

/// Enum untuk variasi tema warna
/// Semua warna dipilih dari Tailwind CSS color palette untuk smooth transitions
enum ThemeColors {
  teal,
  cyan,
  sky,
  emerald,
  green,
  lime,
  blue,
  indigo,
  purple,
  pink;

  /// Get color pair untuk tema ini
  ColorPair get colors {
    switch (this) {
      case ThemeColors.teal:
        return const ColorPair(
          primary: Color(0xFF14b8a6), // Teal-500
          dark: Color(0xFF0d9488), // Teal-600
          name: 'Teal',
        );

      case ThemeColors.cyan:
        return const ColorPair(
          primary: Color(0xFF06b6d4), // Cyan-500
          dark: Color(0xFF0891b2), // Cyan-600
          name: 'Cyan',
        );

      case ThemeColors.sky:
        return const ColorPair(
          primary: Color(0xFF0ea5e9), // Sky-500
          dark: Color(0xFF0284c7), // Sky-600
          name: 'Sky',
        );

      case ThemeColors.emerald:
        return const ColorPair(
          primary: Color(0xFF10b981), // Emerald-500
          dark: Color(0xFF059669), // Emerald-600
          name: 'Emerald',
        );

      case ThemeColors.green:
        return const ColorPair(
          primary: Color(0xFF22c55e), // Green-500
          dark: Color(0xFF16a34a), // Green-600
          name: 'Green',
        );

      case ThemeColors.lime:
        return const ColorPair(
          primary: Color(0xFF84cc16), // Lime-500
          dark: Color(0xFF65a30d), // Lime-600
          name: 'Lime',
        );

      case ThemeColors.blue:
        return const ColorPair(
          primary: Color(0xFF3b82f6), // Blue-500
          dark: Color(0xFF2563eb), // Blue-600
          name: 'Blue',
        );

      case ThemeColors.indigo:
        return const ColorPair(
          primary: Color(0xFF6366f1), // Indigo-500
          dark: Color(0xFF4f46e5), // Indigo-600
          name: 'Indigo',
        );

      case ThemeColors.purple:
        return const ColorPair(
          primary: Color(0xFFa855f7), // Purple-500
          dark: Color(0xFF9333ea), // Purple-600
          name: 'Purple',
        );

      case ThemeColors.pink:
        return const ColorPair(
          primary: Color(0xFFec4899), // Pink-500
          dark: Color(0xFFdb2777), // Pink-600
          name: 'Pink',
        );
    }
  }
}
