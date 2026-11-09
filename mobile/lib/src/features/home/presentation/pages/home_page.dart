import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/data/services/auth_service.dart';
import '../../../../core/theme/theme_controller.dart';

/// Pantalla temporal para comprobar la autenticación completa.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.authService});

  final AuthService authService;

  /// Obtiene el ID token de Firebase y lo copia al portapapeles.
  ///
  /// Este botón es temporal y se eliminará cuando Flutter esté
  /// conectado automáticamente con FastAPI.
  Future<void> _copyFirebaseToken(BuildContext context) async {
    final token = await authService.getIdToken();

    if (!context.mounted) {
      return;
    }

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No existe una sesión activa.')),
      );
      return;
    }

    // Copia el token sin mostrarlo completamente en pantalla.
    await Clipboard.setData(ClipboardData(text: token));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Token de Firebase copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClubMartinGaser'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
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
              const SizedBox(height: 24),

              // Botón temporal para probar el token en Swagger.
              FilledButton.icon(
                onPressed: () {
                  _copyFirebaseToken(context);
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar token para Swagger'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
