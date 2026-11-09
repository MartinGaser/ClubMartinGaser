import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import '../widgets/auth_error_message.dart';

/// Pantalla para solicitar la recuperaciÃ³n de contraseÃ±a.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Solicita a Firebase el envÃ­o del correo de recuperaciÃ³n.
  Future<void> _sendEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IngresÃ¡ un correo electrÃ³nico vÃ¡lido.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authService.sendPasswordResetEmail(email: email);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se enviÃ³ el correo de recuperaciÃ³n.')),
      );

      // Regresa al inicio de sesiÃ³n.
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(firebaseAuthErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseÃ±a')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 64),
              const SizedBox(height: 16),
              const Text(
                'IngresÃ¡ tu correo y Firebase enviarÃ¡ un enlace '
                'para cambiar tu contraseÃ±a.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Correo asociado a la cuenta.
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Correo electrÃ³nico',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Solicita el correo de recuperaciÃ³n.
              FilledButton(
                onPressed: _isLoading ? null : _sendEmail,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar correo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
