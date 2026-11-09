import 'package:flutter/material.dart';

/// Controla el modo visual utilizado por toda la aplicación.
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  /// Indica si actualmente está seleccionado el modo oscuro.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Cambia entre el tema claro y el tema oscuro.
  void setDarkMode(bool enabled) {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;

    // Informa a MaterialApp que debe reconstruirse.
    notifyListeners();
  }

  /// Alterna manualmente entre los dos modos.
  void toggleTheme() {
    setDarkMode(!isDarkMode);
  }
}
