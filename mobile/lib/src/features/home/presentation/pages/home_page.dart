import 'package:flutter/material.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../venues/presentation/pages/venues_page.dart';

/// Pantalla principal provisional de ClubMartinGaser.
///
/// Permite comprobar la conexiÃ³n autenticada con FastAPI
/// y acceder al listado de sedes deportivas.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.authService});

  final AuthService authService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiClient _apiClient;

  Map<String, dynamic>? _profile;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Crea el cliente HTTP utilizando la sesiÃ³n actual de Firebase.
    _apiClient = ApiClient(authService: widget.authService);
  }

  @override
  void dispose() {
    // Cierra el cliente HTTP cuando la pantalla deja de utilizarse.
    _apiClient.close();
    super.dispose();
  }

  /// Consulta el perfil autenticado desde FastAPI.
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
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
          _isLoading = false;
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

  /// Cierra la sesiÃ³n actual de Firebase.
  Future<void> _signOut() async {
    await widget.authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = widget.authService.currentUser;

    final email = _profile?['email'] as String? ?? firebaseUser?.email;

    final firstName = _profile?['first_name'] as String?;

    final lastName = _profile?['last_name'] as String?;

    final fullName = [firstName, lastName].whereType<String>().join(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClubMartinGaser'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesiÃ³n',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.sports_soccer, size: 72),
                const SizedBox(height: 16),
                const Text(
                  'SesiÃ³n iniciada correctamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                if (fullName.isNotEmpty)
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                Text(
                  email ?? 'Usuario sin correo',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Abre las sedes obtenidas desde FastAPI.
                FilledButton.icon(
                  onPressed: _openVenues,
                  icon: const Icon(Icons.location_city),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Ver sedes deportivas'),
                  ),
                ),
                const SizedBox(height: 12),

                // Consulta el perfil autenticado en FastAPI.
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loadProfile,
                  icon: const Icon(Icons.person_outline),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Consultar mi perfil'),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],

                if (_profile != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Flutter, Firebase y FastAPI '
                    'estÃ¡n conectados correctamente.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
