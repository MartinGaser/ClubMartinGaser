import 'package:flutter/material.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/data/services/auth_service.dart';

/// Perfil editable del usuario autenticado.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.authService,
    required this.themeController,
  });

  final AuthService authService;
  final ThemeController themeController;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ApiClient _apiClient;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  Map<String, dynamic>? _profile;
  DateTime? _birthDate;

  String? _errorMessage;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient(authService: widget.authService);

    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _apiClient.close();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiClient.get('/api/users/me');

      final profile = result as Map<String, dynamic>;

      if (!mounted) {
        return;
      }

      _firstNameController.text = profile['first_name'] as String? ?? '';

      _lastNameController.text = profile['last_name'] as String? ?? '';

      final birthDate = profile['birth_date'] as String?;

      setState(() {
        _profile = profile;
        _birthDate = birthDate == null ? null : DateTime.parse(birthDate);
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'No se pudo cargar el perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate != null) {
      setState(() {
        _birthDate = selectedDate;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiClient.put(
        '/api/users/me',
        body: {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'birth_date': _birthDate == null ? null : _formatApiDate(_birthDate!),
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = result as Map<String, dynamic>;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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

  String _initials() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    final first = firstName.isEmpty
        ? ''
        : firstName.substring(0, 1).toUpperCase();

    final last = lastName.isEmpty ? '' : lastName.substring(0, 1).toUpperCase();

    return '$first$last'.isEmpty ? 'U' : '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage ?? 'No se pudo cargar el perfil.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loadProfile,
                  child: const Text('REINTENTAR'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final email = _profile!['email'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('MI PERFIL'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            child: Text(_isEditing ? 'Cancelar' : 'Editar'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    _initials(),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_firstNameController.text} '
                        '${_lastNameController.text}',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(email),
                      const SizedBox(height: 7),
                      const Text(
                        'MIEMBRO ACTIVO',
                        style: TextStyle(
                          color: AppColors.olive,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Card(
              child: SwitchListTile(
                title: const Text('Modo nocturno'),
                value: widget.themeController.isDarkMode,
                onChanged: widget.themeController.setDarkMode,
                secondary: Icon(
                  widget.themeController.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
              ),
            ),
            const SizedBox(height: 18),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'DATOS PERSONALES',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _firstNameController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Ingresá un nombre válido.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Ingresá un apellido válido.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _isEditing ? _selectBirthDate : null,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            suffixIcon: Icon(Icons.calendar_month),
                          ),
                          child: Text(_formatVisibleDate(_birthDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: email,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          suffixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const CircularProgressIndicator()
                              : const Text('GUARDAR CAMBIOS'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ],

            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: widget.authService.signOut,
              icon: const Icon(Icons.logout),
              label: const Text('CERRAR SESIÓN'),
            ),
          ],
        ),
      ),
    );
  }
}
