// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: Espaçamentos e margens reutilizáveis.
import 'package:flutter/material.dart';

import 'package:pet_care/core/tema/cores_app.dart';

/// Tokens de espaçamento, raio de borda e sombras do app
abstract final class EspacamentosApp {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margem lateral padrão das páginas
  // A margem lateral padrão mantém páginas e rodapés alinhados.
  static const double pagePadding = 20;

  // Os raios seguem uma escala compartilhada entre cartões e controles.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusFull = 100;

  /// Sombra discreta padrão para cartões
  // A sombra de cartão diferencia superfícies comuns de elementos elevados.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: CoresApp.shadow,
      blurRadius: 12,
      offset: const Offset(0, 4),
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
