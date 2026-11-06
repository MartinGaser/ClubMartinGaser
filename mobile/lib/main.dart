import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'src/features/auth/data/services/auth_service.dart';
import 'src/features/auth/presentation/pages/auth_gate.dart';

/// Punto de entrada principal de ClubMartinGaser.
Future<void> main() async {
  // Prepara Flutter antes de inicializar Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  // Conecta la aplicación con el proyecto Firebase configurado.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicia la interfaz.
  runApp(const ClubMartinGaserApp());
}

/// Widget raíz de la aplicación.
class ClubMartinGaserApp extends StatelessWidget {
  const ClubMartinGaserApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Crea el servicio encargado de administrar la sesión.
    final authService = AuthService();

    return MaterialApp(
      title: 'ClubMartinGaser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),

      // AuthGate muestra Login o Home según la sesión.
      home: AuthGate(authService: authService),
    );
  }
}
