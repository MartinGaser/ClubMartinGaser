import 'package:flutter/material.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../data/services/auth_service.dart';
import '../widgets/auth_error_message.dart';

/// Pantalla de creación de cuenta.
///
/// Primero registra la cuenta en Firebase Authentication y luego
/// guarda los datos personales en PostgreSQL mediante FastAPI.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.authService});

  final AuthService authService;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  DateTime? _birthDate;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  /// Abre el selector de fecha de nacimiento.
  Future<void> _selectBirthDate() async {
    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selectedDate != null) {
      setState(() {
        _birthDate = selectedDate;
      });
    }
  }

  /// Crea la cuenta Firebase y sincroniza el perfil con FastAPI.
  Future<void> _register() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Seleccioná tu fecha de nacimiento.',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    ApiClient? apiClient;

    try {
      // Firebase crea la cuenta e inicia la sesión automáticamente.
      await widget.authService.register(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // El token de la nueva cuenta se utiliza para crear
      // y actualizar el perfil correspondiente en PostgreSQL.
      apiClient = ApiClient(authService: widget.authService);

      // GET crea automáticamente el perfil local si todavía no existe.
      await apiClient.get('/api/users/me');

      // PUT reemplaza los nombres provisionales por los datos reales.
      await apiClient.put(
        '/api/users/me',
        body: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'birth_date': _formatApiDate(_birthDate!),
        },
      );

      if (!mounted) {
        return;
      }

      // La sesión queda activa. AuthGate mostrará Home.
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            error.message,
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            firebaseAuthErrorMessage(error),
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      );
    } finally {
      apiClient?.close();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatApiDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  String _formatVisibleDate(DateTime? value) {
    if (value == null) {
      return 'Seleccionar fecha';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        body: AuthBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('VOLVER'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'NUEVA CUENTA',
                      style: AppTextStyles.overline(
                        color: AppColors.lime,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'CREAR CUENTA',
                      style: AppTextStyles.display(
                        color: AppColors.white,
                        fontSize: 50,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Completá tus datos para comenzar a reservar.',
                      style: AppTextStyles.body(color: AppColors.lightGrey),
                    ),
                    const SizedBox(height: 28),

                    const _FieldLabel(text: 'NOMBRE'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Tu nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Ingresá un nombre válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    const _FieldLabel(text: 'APELLIDO'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Tu apellido',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Ingresá un apellido válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    const _FieldLabel(text: 'FECHA DE NACIMIENTO'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isLoading ? null : _selectBirthDate,
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                          suffixIcon: Icon(Icons.chevron_right),
                        ),
                        child: Text(
                          _formatVisibleDate(_birthDate),
                          style: AppTextStyles.body(
                            color: _birthDate == null
                                ? AppColors.grey
                                : AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    const _FieldLabel(text: 'EMAIL'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'usuario@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty || !email.contains('@')) {
                          return 'Ingresá un correo válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    const _FieldLabel(text: 'CONTRASEÑA'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Mínimo 6 caracteres',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Debe tener al menos 6 caracteres.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    const _FieldLabel(text: 'REPETIR CONTRASEÑA'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmationController,
                      obscureText: _obscureConfirmation,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _register();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Repetí tu contraseña',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmation = !_obscureConfirmation;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Repetí tu contraseña.';
                        }

                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    FilledButton(
                      onPressed: _isLoading ? null : _register,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.ink,
                                ),
                              )
                            : Text(
                                'CREAR CUENTA',
                                style: AppTextStyles.button(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.overline(color: AppColors.lightGrey, fontSize: 11),
    );
  }
}
