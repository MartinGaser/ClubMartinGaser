import 'package:flutter/material.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../venues/presentation/pages/venues_page.dart';

/// Pantalla principal del usuario autenticado.
///
/// Permite consultar el perfil almacenado en FastAPI,
/// acceder a las sedes y cambiar el tema de la aplicación.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.authService,
    required this.themeController,
  });

  final AuthService authService;
  final ThemeController themeController;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiClient _apiClient;

  Map<String, dynamic>? _profile;
  String? _errorMessage;

  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();

    // Crea el cliente HTTP con la sesión de Firebase actual.
    _apiClient = ApiClient(authService: widget.authService);

    // Carga los datos del usuario al entrar en Home.
    _loadProfile();
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }

  /// Consulta el perfil autenticado desde FastAPI.
  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiClient.get('/api/users/me');

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = result as Map<String, dynamic>;
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
        _errorMessage = 'No se pudo consultar el perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  /// Abre el listado de sedes deportivas.
  void _openVenues() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VenuesPage(authService: widget.authService),
      ),
    );
  }

  /// Cierra la sesión de Firebase.
  Future<void> _signOut() async {
    await widget.authService.signOut();
  }

  String _initials({required String? firstName, required String? lastName}) {
    final firstInitial = firstName == null || firstName.isEmpty
        ? ''
        : firstName.substring(0, 1).toUpperCase();

    final lastInitial = lastName == null || lastName.isEmpty
        ? ''
        : lastName.substring(0, 1).toUpperCase();

    final initials = '$firstInitial$lastInitial';

    return initials.isEmpty ? 'U' : initials;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = widget.authService.currentUser;

    final email = _profile?['email'] as String? ?? firebaseUser?.email;

    final firstName = _profile?['first_name'] as String?;
    final lastName = _profile?['last_name'] as String?;

    final fullName = [
      firstName,
      lastName,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');

    final initials = _initials(firstName: firstName, lastName: lastName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClubMartinGaser'),
        actions: [
          // Alterna entre modo claro y oscuro.
          IconButton(
            tooltip: widget.themeController.isDarkMode
                ? 'Usar modo claro'
                : 'Usar modo oscuro',
            onPressed: widget.themeController.toggleTheme,
            icon: Icon(
              widget.themeController.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),

          // Cierra la sesión actual.
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),

            // Encabezado del usuario.
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF080A14),
                      fontSize: 22,
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
                        fullName.isEmpty ? 'Usuario' : fullName,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email ?? 'Usuario sin correo',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            Text(
              'ZONA DEPORTIVA',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consultá sedes, espacios deportivos '
              'y horarios disponibles.',
            ),
            const SizedBox(height: 28),

            // Acceso principal a las sedes.
            FilledButton.icon(
              onPressed: _openVenues,
              icon: const Icon(Icons.location_city),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('VER SEDES DEPORTIVAS'),
              ),
            ),
            const SizedBox(height: 14),

            // Actualiza el perfil almacenado en FastAPI.
            OutlinedButton.icon(
              onPressed: _isLoadingProfile ? null : _loadProfile,
              icon: const Icon(Icons.person_outline),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _isLoadingProfile
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ACTUALIZAR MI PERFIL'),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!)),
                  ],
                ),
              ),
            ],

            if (_profile != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_done_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Flutter, Firebase y FastAPI '
                          'están conectados correctamente.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
