import 'package:flutter/material.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/models/venue.dart';
import '../../data/repositories/venue_repository.dart';
import '../widgets/venue_card.dart';

/// Pantalla que muestra las sedes activas del club.
class VenuesPage extends StatefulWidget {
  const VenuesPage({super.key, required this.authService});

  final AuthService authService;

  @override
  State<VenuesPage> createState() => _VenuesPageState();
}

class _VenuesPageState extends State<VenuesPage> {
  late final ApiClient _apiClient;
  late final VenueRepository _venueRepository;

  List<Venue> _venues = const [];
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Crea el cliente HTTP y el repositorio de sedes.
    _apiClient = ApiClient(authService: widget.authService);

    _venueRepository = VenueRepository(apiClient: _apiClient);

    _loadVenues();
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }

  /// Solicita las sedes activas a FastAPI.
  Future<void> _loadVenues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final venues = await _venueRepository.getActiveVenues();

      if (!mounted) {
        return;
      }

      setState(() {
        _venues = venues;
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
        _errorMessage = 'No se pudieron cargar las sedes.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Por ahora informa la sede elegida.
  ///
  /// En el siguiente paso abrirá los espacios deportivos.
  void _selectVenue(Venue venue) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Sede seleccionada: ${venue.name}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sedes')),
      body: RefreshIndicator(onRefresh: _loadVenues, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.cloud_off,
            size: 72,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadVenues,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_venues.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.location_city_outlined, size: 72),
          SizedBox(height: 16),
          Text('No hay sedes disponibles.', textAlign: TextAlign.center),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Elegí una sede',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text('Consultá los espacios y horarios disponibles.'),
        const SizedBox(height: 20),
        for (final venue in _venues)
          VenueCard(
            venue: venue,
            onTap: () {
              _selectVenue(venue);
            },
          ),
      ],
    );
  }
}
