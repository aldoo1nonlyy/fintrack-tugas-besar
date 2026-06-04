import 'package:flutter/material.dart';

class AppSpacing {
  static const double screenPadding = 20;
  static const double sectionGap = 24;
  static const double itemGap = 16;
  static const double cardRadius = 24;
  static const double elementRadius = 18;
}

class AppColors {
  // Vibrant Character Font Palette (Fintech Premium)
  static const Color primary = Color(0xFF6366F1); // Vibrant Indigo
  static const Color primaryDark = Color(0xFF3730A3); 
  static const Color primaryLight = Color(0xFFE0E7FF);
  
  static const Color accent = Color(0xFF14B8A6); // Teal for modern money accent
  static const Color secondary = Color(0xFFF59E0B); // Amber for warnings
  
  static const Color surface = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceContainer = Colors.white;
  static const Color surfaceDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceContainerDark = Color(0xFF1E293B); // Slate 800
  
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textLight = Color(0xFFF1F5F9); // Slate 100
  static const Color mutedText = Color(0xFF64748B); // Slate 500
  static const Color mutedTextDark = Color(0xFF94A3B8); // Slate 400
  
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderDark = Color(0xFF334155); // Slate 700
  
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
}

class AppShadows {
  static List<BoxShadow> get softFloat => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08), // Primary tinted shadow for character
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.03), // Slate 900 tint
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ];
      
  static List<BoxShadow> get heavyFloat => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.20),
          offset: const Offset(0, 12),
          blurRadius: 32,
          spreadRadius: -4,
        ),
      ];
}
