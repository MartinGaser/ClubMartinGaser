import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Estilos tipográficos compartidos por toda la aplicación.
abstract final class AppTextStyles {
  /// Título principal condensado, por ejemplo CLUB NOEMI ACOSTA.
  static TextStyle display({
    Color color = AppColors.ink,
    double fontSize = 44,
  }) {
    return GoogleFonts.anton(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1,
      letterSpacing: 0.2,
    );
  }

  /// Título de sección condensado.
  static TextStyle sectionTitle({
    Color color = AppColors.ink,
    double fontSize = 28,
  }) {
    return GoogleFonts.anton(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.05,
    );
  }

  /// Etiquetas en mayúsculas con separación entre letras.
  static TextStyle overline({
    Color color = AppColors.grey,
    double fontSize = 12,
  }) {
    return GoogleFonts.inter(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 4,
    );
  }

  /// Texto de botones principales.
  static TextStyle button({Color color = AppColors.ink, double fontSize = 16}) {
    return GoogleFonts.anton(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.2,
    );
  }

  /// Texto general.
  static TextStyle body({
    Color color = AppColors.ink,
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.inter(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.35,
    );
  }

  /// Texto pequeño y secundario.
  static TextStyle caption({
    Color color = AppColors.grey,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.inter(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.25,
    );
  }
}
