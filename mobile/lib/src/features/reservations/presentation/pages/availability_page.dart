import 'package:flutter/material.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../spaces/data/models/sports_space.dart';
import '../../data/models/availability.dart';
import '../../data/repositories/reservation_repository.dart';

/// Permite elegir una fecha, consultar turnos y crear una reserva.
class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({
    super.key,
    required this.authService,
    required this.sportsSpace,
  });

  final AuthService authService;
  final SportsSpace sportsSpace;

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  late final ApiClient _apiClient;
  late final ReservationRepository _repository;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  SpaceAvailability? _availability;
  AvailabilitySlot? _selectedSlot;

  String? _errorMessage;
  bool _isLoading = false;
  bool _isCreatingReservation = false;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient(authService: widget.authService);

    _repository = ReservationRepository(_apiClient);

    _loadAvailability();
  }

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }

  /// Abre el selector de fecha de Flutter.
  Future<void> _selectDate() async {
    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 90)),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
      _selectedSlot = null;
    });

    await _loadAvailability();
  }

  /// Consulta los turnos disponibles en FastAPI.
  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedSlot = null;
    });

    try {
      final availability = await _repository.getAvailability(
        sportsSpaceId: widget.sportsSpace.id,
        requestedDate: _selectedDate,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _availability = availability;
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
        _errorMessage = 'No se pudo consultar la disponibilidad.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Solicita confirmación antes de crear la reserva.
  Future<void> _confirmReservation() async {
    final slot = _selectedSlot;

    if (slot == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar reserva'),
          content: Text(
            '¿Querés reservar ${widget.sportsSpace.name} '
            'de ${slot.label}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _createReservation(slot);
  }

  /// Envía la reserva a FastAPI con el token Firebase.
  Future<void> _createReservation(AvailabilitySlot slot) async {
    setState(() {
      _isCreatingReservation = true;
      _errorMessage = null;
    });

    try {
      final reservation = await _repository.createReservation(
        sportsSpaceId: widget.sportsSpace.id,
        startDateTime: slot.startDateTime,
        endDateTime: slot.endDateTime,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Reserva confirmada'),
            content: Text(
              'La reserva número ${reservation.id} '
              'fue creada correctamente.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      // Vuelve a consultar para quitar el turno reservado.
      await _loadAvailability();
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
        _errorMessage = 'No se pudo crear la reserva.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingReservation = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final slots = _availability?.availableSlots ?? const <AvailabilitySlot>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Disponibilidad')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAvailability,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      widget.sportsSpace.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(widget.sportsSpace.sportType.displayName),
                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('Fecha: ${_formatDate(_selectedDate)}'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage != null)
                      _ErrorState(
                        message: _errorMessage!,
                        onRetry: _loadAvailability,
                      )
                    else if (slots.isEmpty)
                      const _EmptyState()
                    else ...[
                      Text(
                        'Horarios disponibles',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final slot in slots)
                            ChoiceChip(
                              label: Text(slot.label),
                              selected: _selectedSlot == slot,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSlot = selected ? slot : null;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Botón inferior para confirmar el turno elegido.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_selectedSlot == null || _isCreatingReservation)
                        ? null
                        : _confirmReservation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _isCreatingReservation
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reservar horario'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            Icons.error_outline,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 64),
          SizedBox(height: 16),
          Text(
            'No hay horarios disponibles para esta fecha.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
