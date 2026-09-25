import 'package:flutter/material.dart';

/// Paleta de cores centralizada do app
abstract final class CoresApp {
  static const Color primary = Color(0xFF2A9D8F);
  static const Color primaryLight = Color(0xFF5FC4B8);
  static const Color primaryDark = Color(0xFF1B7A6E);

  static const Color background = Color(0xFFFFF8EC);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color cardHighlight = Color(0xFF1A3C5E);
  static const Color cardHighlightText = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color statusConfirmed = Color(0xFF34D399);
  static const Color statusPending = Color(0xFFFBBF24);
  static const Color statusCancelled = Color(0xFFEF4444);

  static const Color divider = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x0D000000);
  static const Color iconDefault = Color(0xFF6B7280);
  static const Color danger = Color(0xFFEF4444);
  static const Color navBarBackground = Color(0xFFFFFFFF);
  static const Color navBarSelected = primary;
  static const Color navBarUnselected = Color(0xFF9CA3AF);
}
