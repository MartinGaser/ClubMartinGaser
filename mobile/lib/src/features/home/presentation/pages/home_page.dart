import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/data/services/auth_service.dart';

/// Pantalla temporal para comprobar la autenticaciÃ³n completa.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.authService});

  final AuthService authService;

  /// Obtiene el ID token de Firebase y lo copia al portapapeles.
  ///
  /// Este botÃ³n es temporal y se eliminarÃ¡ cuando Flutter estÃ©
  /// conectado automÃ¡ticamente con FastAPI.
  Future<void> _copyFirebaseToken(BuildContext context) async {
    final token = await authService.getIdToken();

    if (!context.mounted) {
      return;
    }

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No existe una sesiÃ³n activa.')),
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
            tooltip: 'Cerrar sesiÃ³n',
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
                'SesiÃ³n iniciada correctamente',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'Usuario sin correo',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // BotÃ³n temporal para probar el token en Swagger.
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
