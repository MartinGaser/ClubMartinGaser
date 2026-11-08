import 'package:flutter/material.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/services/auth_service.dart';

/// Pantalla temporal para comprobar Flutter con FastAPI.
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

    // El cliente utilizará la sesión Firebase existente.
    _apiClient = ApiClient(authService: widget.authService);
  }

  @override
  void dispose() {
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
    final email = _profile?['email'] as String?;
    final firstName = _profile?['first_name'] as String?;
    final lastName = _profile?['last_name'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClubMartinGaser'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.authService.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_done_outlined, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Probar conexión con FastAPI',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              if (_isLoading) const CircularProgressIndicator(),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],

              if (_profile != null) ...[
                Text(
                  '$firstName $lastName',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(email ?? ''),
                const SizedBox(height: 16),
                const Text(
                  'Flutter, Firebase y FastAPI están conectados.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],

              FilledButton.icon(
                onPressed: _isLoading ? null : _loadProfile,
                icon: const Icon(Icons.sync),
                label: const Text('Consultar mi perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
