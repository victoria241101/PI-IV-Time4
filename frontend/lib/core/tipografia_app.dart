import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pet_care/core/cores_app.dart';

/// Tipografia centralizada do app

abstract final class TipografiaApp {
  /// Título grande – 24px, bold.
  static TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: CoresApp.textPrimary,
    height: 1.3,
  );

  /// Título médio – 20px, semibold
  static TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: CoresApp.textPrimary,
    height: 1.3,
  );

  /// Título pequeno – 18px, semibold
  static TextStyle heading3 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: CoresApp.textPrimary,
    height: 1.3,
  );

  /// Corpo principal – 16px, regular.
  static TextStyle body = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: CoresApp.textPrimary,
    height: 1.5,
  );

  /// Corpo médio – 14px, medium.
  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: CoresApp.textPrimary,
    height: 1.4,
  );

  /// Corpo pequeno – 14px, regular.
  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: CoresApp.textSecondary,
    height: 1.4,
  );

  /// Legenda – 12px, regular.
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: CoresApp.textSecondary,
    height: 1.4,
  );

  /// Legenda em destaque – 12px, semibold.
  static TextStyle captionBold = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: CoresApp.textPrimary,
    height: 1.4,
  );

  /// Texto de botão – 16px, semibold.
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CoresApp.textOnPrimary,
    height: 1.4,
  );

  /// Texto de botão pequeno – 14px, semibold.
  static TextStyle buttonSmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: CoresApp.primary,
    height: 1.4,
  );
}
