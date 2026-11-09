import 'package:flutter/material.dart';

import '../../../reservations/presentation/pages/availability_page.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../venues/data/models/venue.dart';
import '../../data/models/sports_space.dart';
import '../../data/repositories/space_repository.dart';
import '../widgets/sports_space_card.dart';

/// Muestra los espacios deportivos de una sede.
class SpacesPage extends StatefulWidget {
  const SpacesPage({super.key, required this.authService, required this.venue});

  final AuthService authService;
  final Venue venue;

  @override
  State<SpacesPage> createState() => _SpacesPageState();
}

class _SpacesPageState extends State<SpacesPage> {
  late final ApiClient _apiClient;
  late final SportsSpaceRepository _repository;

  List<SportsSpace> _spaces = const [];
  SportType? _selectedSport;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient(authService: widget.authService);

    _repository = SportsSpaceRepository(_apiClient);

    _loadSpaces();
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }

  /// Carga espacios de la sede y aplica el filtro seleccionado.
  Future<void> _loadSpaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final spaces = await _repository.getSpaces(
        venueId: widget.venue.id,
        sportType: _selectedSport,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _spaces = spaces;
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
        _errorMessage =
            ('No se pudieron cargar '
            'los espacios deportivos.');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Cambia el filtro y vuelve a consultar FastAPI.
  Future<void> _selectFilter(SportType? sportType) async {
    setState(() {
      _selectedSport = sportType;
    });

    await _loadSpaces();
  }

  /// En el prÃƒÂ³ximo paso abrirÃƒÂ¡ la disponibilidad del espacio.
  /// Abre la disponibilidad del espacio seleccionado.
  void _selectSpace(SportsSpace sportsSpace) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AvailabilityPage(
          authService: widget.authService,
          sportsSpace: sportsSpace,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.venue.name)),
      body: RefreshIndicator(
        onRefresh: _loadSpaces,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Espacios deportivos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(widget.venue.address),
            const SizedBox(height: 20),

            // Los chips permiten filtrar por deporte.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _selectedSport == null,
                    onSelected: (_) {
                      _selectFilter(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final sportType in SportType.values) ...[
                    ChoiceChip(
                      label: Text(sportType.displayName),
                      selected: (_selectedSport == sportType),
                      onSelected: (_) {
                        _selectFilter(sportType);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _ErrorState(message: _errorMessage!, onRetry: _loadSpaces)
            else if (_spaces.isEmpty)
              const _EmptyState()
            else
              for (final sportsSpace in _spaces)
                SportsSpaceCard(
                  sportsSpace: sportsSpace,
                  onTap: () {
                    _selectSpace(sportsSpace);
                  },
                ),
          ],
        ),
      ),
    );
  }
}

/// Estado mostrado cuando FastAPI devuelve un error.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Estado mostrado cuando no existen espacios para el filtro.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Icons.sports_outlined, size: 64),
          SizedBox(height: 16),
          Text(
            'No hay espacios disponibles '
            'para el filtro seleccionado.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
