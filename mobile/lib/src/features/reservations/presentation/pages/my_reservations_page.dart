import 'package:flutter/material.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/models/reservation.dart';
import '../../data/repositories/reservation_repository.dart';
import '../widgets/reservation_card.dart';

/// Muestra las próximas reservas y el historial del usuario.
class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key, required this.authService});

  final AuthService authService;

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage>
    with SingleTickerProviderStateMixin {
  late final ApiClient _apiClient;
  late final ReservationRepository _repository;
  late final TabController _tabController;

  List<Reservation> _futureReservations = const [];
  List<Reservation> _history = const [];

  String? _errorMessage;
  bool _isLoading = true;
  int? _cancellingId;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient(authService: widget.authService);

    _repository = ReservationRepository(_apiClient);

    _tabController = TabController(length: 2, vsync: this);

    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiClient.close();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getFutureReservations(),
        _repository.getReservationHistory(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _futureReservations = results[0];
        _history = results[1];
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
        _errorMessage = 'No se pudieron cargar las reservas.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmCancellation(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar reserva'),
          content: Text(
            '¿Confirmás la cancelación de la '
            'reserva #${reservation.id}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('VOLVER'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('CANCELAR'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _cancelReservation(reservation.id);
    }
  }

  Future<void> _cancelReservation(int reservationId) async {
    setState(() {
      _cancellingId = reservationId;
    });

    try {
      await _repository.cancelReservation(reservationId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva cancelada correctamente.')),
      );

      await _loadReservations();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _cancellingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS RESERVAS'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.event_available), text: 'Próximas'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _ErrorState(message: _errorMessage!, onRetry: _loadReservations)
          : TabBarView(
              controller: _tabController,
              children: [
                _ReservationList(
                  reservations: _futureReservations,
                  emptyMessage: 'No tenés reservas próximas.',
                  onRefresh: _loadReservations,
                  cancellingId: _cancellingId,
                  onCancel: _confirmCancellation,
                ),
                _ReservationList(
                  reservations: _history,
                  emptyMessage: 'Todavía no hay reservas en el historial.',
                  onRefresh: _loadReservations,
                ),
              ],
            ),
    );
  }
}

class _ReservationList extends StatelessWidget {
  const _ReservationList({
    required this.reservations,
    required this.emptyMessage,
    required this.onRefresh,
    this.onCancel,
    this.cancellingId,
  });

  final List<Reservation> reservations;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Reservation)? onCancel;
  final int? cancellingId;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.event_busy, size: 72),
            const SizedBox(height: 16),
            Text(emptyMessage, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final reservation in reservations)
            Stack(
              children: [
                ReservationCard(
                  reservation: reservation,
                  onCancel: onCancel == null
                      ? null
                      : () {
                          onCancel!(reservation);
                        },
                ),
                if (cancellingId == reservation.id)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x88FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 72,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }
}
