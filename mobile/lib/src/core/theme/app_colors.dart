import 'package:flutter/material.dart';

/// Paleta de colores basada en el prototipo de Figma.
abstract final class AppColors {
  /// Verde lima utilizado en acciones, filtros y elementos activos.
  static const Color lime = Color(0xFFC7FF00);

  /// Verde oliva utilizado en títulos sobre fondos claros.
  static const Color olive = Color(0xFF5E7800);

  /// Fondo oscuro principal de las pantallas deportivas.
  static const Color darkBackground = Color(0xFF030409);

  /// Superficie oscura utilizada en tarjetas y controles.
  static const Color darkSurface = Color(0xFF17171F);

  /// Superficie oscura secundaria.
  static const Color darkSurfaceAlt = Color(0xFF202029);

  /// Bordes utilizados sobre superficies oscuras.
  static const Color darkBorder = Color(0xFF373741);

  /// Fondo claro de Home, Perfil y Mis reservas.
  static const Color lightBackground = Color(0xFFF7F8FA);

  /// Superficie blanca.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Campo deshabilitado o de solo lectura.
  static const Color disabledSurface = Color(0xFFE9ECF0);

  /// Negro azulado de títulos en superficies claras.
  static const Color ink = Color(0xFF080A14);

  /// Texto principal sobre fondos oscuros.
  static const Color white = Color(0xFFF8F8FA);

  /// Texto secundario.
  static const Color grey = Color(0xFF8A8B91);

  /// Texto muy claro o deshabilitado.
  static const Color lightGrey = Color(0xFFB8BAC0);

  /// Color de errores y acciones destructivas.
  static const Color error = Color(0xFFFF2638);

  /// Fondo suave para errores.
  static const Color errorContainer = Color(0xFFFFE9EC);

  /// Etiqueta verde suave.
  static const Color activeContainer = Color(0xFFF2FFD0);
}
