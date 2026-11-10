import 'package:flutter/material.dart';

import '../../data/services/auth_service.dart';
import '../widgets/auth_error_message.dart';
import 'register_page.dart';
import 'reset_password_page.dart';

/// Pantalla para iniciar sesiÃ³n con correo y contraseÃ±a.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Libera los controladores cuando se cierra la pantalla.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Intenta iniciar sesiÃ³n mediante Firebase Authentication.
  Future<void> _signIn() async {
    // No continÃºa si algÃºn campo del formulario es invÃ¡lido.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // EnvÃ­a las credenciales al servicio de Firebase.
      await widget.authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // No necesitamos navegar manualmente.
      // AuthGate detectarÃ¡ automÃ¡ticamente la sesiÃ³n iniciada.
    } catch (error) {
      if (!mounted) {
        return;
      }

      // Muestra un mensaje entendible para el usuario.
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

  /// Abre la pantalla de registro.
  void _openRegisterPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterPage(authService: widget.authService),
      ),
    );
  }

  /// Abre la pantalla de recuperaciÃ³n de contraseÃ±a.
  void _openResetPasswordPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResetPasswordPage(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.sports_soccer, size: 72),
                    const SizedBox(height: 16),
                    Text(
                      'ClubMartinGaser',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Inicia sesion para reservar espacios deportivos.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Campo de correo electrÃ³nico.
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo electronico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Ingresa tu correo electronico.';
                        }

                        if (!email.contains('@')) {
                          return 'Ingresa un correo valido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo de contraseÃ±a.
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contrasena',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: 'Mostrar u ocultar contrasena',
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
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu contrasena.';
                        }

                        return null;
                      },
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _openResetPasswordPage,
                        child: const Text('Olvidaste tu contrasena?'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // BotÃ³n de inicio de sesiÃ³n.
                    FilledButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Iniciar sesion'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // BotÃ³n para crear una cuenta.
                    OutlinedButton(
                      onPressed: _isLoading ? null : _openRegisterPage,
                      child: const Text('Crear una cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
