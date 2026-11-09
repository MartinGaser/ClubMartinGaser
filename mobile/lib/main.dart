import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/theme_controller.dart';
import 'src/features/auth/data/services/auth_service.dart';
import 'src/features/auth/presentation/pages/auth_gate.dart';

/// Punto de entrada de ClubMartinGaser.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ClubMartinGaserApp());
}

/// Widget raíz de la aplicación.
class ClubMartinGaserApp extends StatefulWidget {
  const ClubMartinGaserApp({super.key});

  @override
  State<ClubMartinGaserApp> createState() => _ClubMartinGaserAppState();
}

class _ClubMartinGaserAppState extends State<ClubMartinGaserApp> {
  late final AuthService _authService;
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();

    _authService = AuthService();
    _themeController = ThemeController();

    // Reconstruye MaterialApp cuando cambia el tema.
    _themeController.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);

    _themeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClubMartinGaser',
      debugShowCheckedModeBanner: false,

      // Temas basados en el diseño de Figma.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      // El controlador decide qué tema mostrar.
      themeMode: _themeController.themeMode,

      home: AuthGate(
        authService: _authService,
        themeController: _themeController,
      ),
    );
  }
}
