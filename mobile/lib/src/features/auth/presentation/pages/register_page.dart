import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import '../widgets/auth_error_message.dart';

/// Pantalla para registrar una cuenta nueva.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.authService});

  final AuthService authService;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    // Libera los controladores al cerrar la pantalla.
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  /// Crea una cuenta nueva en Firebase Authentication.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase registra al usuario y deja iniciada la sesiÃ³n.
      await widget.authService.register(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      // Regresa a la pantalla anterior.
      // AuthGate detectarÃ¡ la nueva sesiÃ³n.
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
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add_alt_1, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Registrate para comenzar a reservar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Correo electrÃ³nico.
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrÃ³nico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'IngresÃ¡ tu correo electrÃ³nico.';
                    }

                    if (!email.contains('@')) {
                      return 'IngresÃ¡ un correo vÃ¡lido.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ContraseÃ±a.
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'ContraseÃ±a',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Debe contener al menos 6 caracteres.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ConfirmaciÃ³n de contraseÃ±a.
                TextFormField(
                  controller: _confirmationController,
                  obscureText: _obscureConfirmation,
                  decoration: InputDecoration(
                    labelText: 'Repetir contraseÃ±a',
                    prefixIcon: const Icon(Icons.lock_reset),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmation = !_obscureConfirmation;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmation
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'RepetÃ­ la contraseÃ±a.';
                    }

                    if (value != _passwordController.text) {
                      return 'Las contraseÃ±as no coinciden.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // BotÃ³n de registro.
                FilledButton(
                  onPressed: _isLoading ? null : _register,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrarme'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
