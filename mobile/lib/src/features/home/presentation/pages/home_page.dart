import 'package:flutter/material.dart';

import '../../../auth/data/services/auth_service.dart';

/// Pantalla temporal que aparece cuando existe una sesión.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    // Consulta el usuario autenticado actualmente.
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClubMartinGaser'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              // Cierra la sesión en Firebase.
              // AuthGate regresará automáticamente al login.
              await authService.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_outlined, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Sesión iniciada correctamente',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'Usuario sin correo',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
