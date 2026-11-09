import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../data/services/auth_service.dart';
import 'login_page.dart';

/// Decide qué pantalla mostrar según la sesión de Firebase.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.themeController,
  });

  final AuthService authService;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomePage(
            authService: authService,
            themeController: themeController,
          );
        }

        return LoginPage(authService: authService);
      },
    );
  }
}
