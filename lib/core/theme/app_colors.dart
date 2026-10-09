import 'package:flutter/material.dart';

/// AppColors defines the global visual palette for MB-engkelQQ Mobile.
/// Follows modern dark-mode aesthetics:
/// - Dark/black premium backgrounds (#0B0E14 / #0F1117)
/// - Primary orange accent (#FF6B00)
/// - Secondary cyan/teal accent (#00D2D3)
/// - Status colors (Green, Orange/Amber, Red, Cyan)
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces
  static const Color background = Color(0xFF0F1117);
  static const Color backgroundDarker = Color(0xFF0A0C10);
  static const Color surface = Color(0xFF161922);
  static const Color surfaceCard = Color(0xFF1A1E29);
  static const Color surfaceCardElevated = Color(0xFF222736);
  static const Color surfaceGlass = Color(0xCC1A1E29);

  // Borders & Dividers
  static const Color border = Color(0xFF262C3D);
  static const Color borderSubtle = Color(0xFF1E2330);
  static const Color borderLight = Color(0xFF333B50);

  // Primary: Orange
  static const Color primary = Color(0xFFFF6B00);
  static const Color primaryLight = Color(0xFFFF8533);
  static const Color primaryDark = Color(0xFFE05D00);
  static const Color primaryContainer = Color(0x2BFF6B00); // 17% opacity
  static const Color primaryGlow = Color(0x40FF6B00);

  // Secondary: Cyan / Teal
  static const Color secondary = Color(0xFF00D2D3);
  static const Color secondaryLight = Color(0xFF48DBFB);
  static const Color secondaryDark = Color(0xFF00A8A8);
  static const Color secondaryContainer = Color(0x2600D2D3);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0x2610B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0x26F59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0x26EF4444);
  static const Color info = Color(0xFF06B6D4);
  static const Color infoContainer = Color(0x2606B6D4);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // Inputs
  static const Color inputBackground = Color(0xFF12151D);
  static const Color inputBorder = Color(0xFF262C3D);
  static const Color inputBorderFocus = Color(0xFFFF6B00);
}
