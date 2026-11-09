import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../../data/services/auth_service.dart';
import 'login_page.dart';

/// Decide quÃ© pantalla mostrar segÃºn la sesiÃ³n de Firebase.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Escucha continuamente los cambios de autenticaciÃ³n.
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Espera mientras Firebase comprueba si existe una sesiÃ³n.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si Firebase devuelve un usuario, muestra Home.
        if (snapshot.hasData) {
          return HomePage(authService: authService);
        }

        // Si no existe una sesiÃ³n, muestra el login.
        return LoginPage(authService: authService);
      },
    );
  }
}
