import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Primary colors (same for both themes)
  static const primary = Color(0xFF6366F1); // indigo
  static const primaryDark = Color(0xFF7C3AED); // purple
  static const primaryLight = Color(0xFFEEF2FF); // indigo light
  static const primaryMid = Color(0xFFC7D2FE); // indigo mid

  // Status colors (same for both themes)
  static const success = Color(0xFF10B981); // green
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B); // orange
  static const warningLight = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444); // red
  static const dangerLight = Color(0xFFFEE2E2);

  // Light Mode
  static const bgScaffold = Color(0xFFF1F5F9); // slate-100
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A); // slate-900
  static const textSecondary = Color(0xFF475569); // slate-600
  static const textMuted = Color(0xFF94A3B8); // slate-400
  static const border = Color(0xFFE2E8F0); // slate-200
  static const borderLight = Color(0xFFF1F5F9); // slate-100

  // Dark Mode
  static const bgScaffoldDark = Color(0xFF3C3C57);
  static const surfaceDark = Color(0xFF686984);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFE5E7EB);
  static const textMutedDark = Color(0xFFD1D5DB);
  static const borderDark = Color(0xFF4B5563);

  // Space colors (for sidebar dots)
  static const spaceColors = [
    Color(0xFF6366F1), // indigo
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // orange
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // purple
    Color(0xFFEC4899), // pink
    Color(0xFF06B6D4), // cyan
    Color(0xFF64748B), // slate
  ];
}
