import 'package:flutter/material.dart';

/// Paleta de cores centralizada do app
abstract final class CoresApp {
  // ============================================================
  // CORES PRINCIPAIS
  // ============================================================

  static const Color primary = Color(0xFF2A9D8F);
  static const Color primaryLight = Color(0xFF5FC4B8);
  static const Color primaryDark = Color(0xFF1B7A6E);

  // Azul escuro usado nos cards e elementos de destaque
  static const Color cardHighlight = Color(0xFF1A3C5E);
  static const Color cardHighlightText = Color(0xFFFFFFFF);

  // Azul escuro para elementos estruturais do wireframe
  static const Color darkBlue = Color(0xFF1A3C5E);
  static const Color darkBlueLight = Color(0xFF315878);

  // ============================================================
  // CORES DE DESTAQUE
  // ============================================================

  // Laranja usado nas ações e destaques das campanhas
  static const Color accentOrange = Color(0xFFF28C28);
  static const Color accentOrangeLight = Color(0xFFFFB45C);
  static const Color accentOrangeDark = Color(0xFFD96F12);

  // ============================================================
  // FUNDOS E SUPERFÍCIES
  // ============================================================

  static const Color background = Color(0xFFFFF8EC);
  static const Color surface = Color(0xFFFFFFFF);

  // Fundo suave para áreas secundárias e placeholders
  static const Color surfaceSoft = Color(0xFFF5F7F7);

  // ============================================================
  // TEXTOS
  // ============================================================

  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Texto sobre azul escuro
  static const Color textOnDarkBlue = Color(0xFFFFFFFF);

  // ============================================================
  // STATUS
  // ============================================================

  static const Color statusConfirmed = Color(0xFF34D399);
  static const Color statusPending = Color(0xFFFBBF24);
  static const Color statusCancelled = Color(0xFFEF4444);

  // ============================================================
  // ELEMENTOS AUXILIARES
  // ============================================================

  static const Color divider = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x0D000000);
  static const Color iconDefault = Color(0xFF6B7280);
  static const Color danger = Color(0xFFEF4444);

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  static const Color navBarBackground = Color(0xFFFFFFFF);
  static const Color navBarSelected = primary;
  static const Color navBarUnselected = Color(0xFF9CA3AF);
}