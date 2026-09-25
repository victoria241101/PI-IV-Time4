import 'package:flutter/material.dart';

import 'package:pet_care/core/cores_app.dart';

/// Tokens de espaçamento, raio de borda e sombras do aplicativo.
abstract final class EspacamentosApp {
  // Espaçamentos
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margem lateral padrão das páginas.
  static const double pagePadding = 20;

  // Raios de borda
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 100;

  // Sombras

  /// Sombra discreta padrão para cartões.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: CoresApp.shadow,
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  /// Sombra mais acentuada para elementos destacados.
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: CoresApp.shadow.withAlpha(30),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
}
