import 'package:flutter/material.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../spaces/data/models/sports_space.dart';
import '../../data/models/availability.dart';
import '../../data/repositories/reservation_repository.dart';

/// Opción de reserva construida a partir de uno o más turnos
/// consecutivos devueltos por FastAPI.
class _ReservationOption {
  const _ReservationOption({
    required this.startDateTime,
    required this.endDateTime,
  });

  final DateTime startDateTime;
  final DateTime endDateTime;

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String get label {
    return '${_formatTime(startDateTime)} '
        'a ${_formatTime(endDateTime)}';
  }
}

/// Permite elegir fecha, duración y horario antes de reservar.
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
  _ReservationOption? _selectedOption;

  // Puede tomar los valores 1 o 2.
  int _durationHours = 1;

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

  /// Abre el selector de fecha.
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
      _selectedOption = null;
    });

    await _loadAvailability();
  }

  /// Consulta la disponibilidad real en FastAPI.
  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedOption = null;
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

  /// Cambia entre reservas de una y dos horas.
  void _changeDuration(int durationHours) {
    setState(() {
      _durationHours = durationHours;
      _selectedOption = null;
    });
  }

  /// Construye las opciones disponibles para la duración elegida.
  ///
  /// Para una reserva de dos horas exige dos intervalos de una hora
  /// completamente consecutivos.
  List<_ReservationOption> _buildReservationOptions() {
    final slots =
        List<AvailabilitySlot>.from(
          _availability?.availableSlots ?? const <AvailabilitySlot>[],
        )..sort(
          (first, second) =>
              first.startDateTime.compareTo(second.startDateTime),
        );

    final options = <_ReservationOption>[];

    for (final startingSlot in slots) {
      var currentEnd = startingSlot.endDateTime;
      var valid = true;

      // El primer intervalo ya está incluido. Para dos horas,
      // buscamos exactamente un intervalo adicional consecutivo.
      for (var offset = 1; offset < _durationHours; offset++) {
        AvailabilitySlot? nextSlot;

        for (final candidate in slots) {
          if (candidate.startDateTime.isAtSameMomentAs(currentEnd)) {
            nextSlot = candidate;
            break;
          }
        }

        if (nextSlot == null) {
          valid = false;
          break;
        }

        currentEnd = nextSlot.endDateTime;
      }

      if (valid) {
        options.add(
          _ReservationOption(
            startDateTime: startingSlot.startDateTime,
            endDateTime: currentEnd,
          ),
        );
      }
    }

    return options;
  }

  /// Solicita confirmación antes de enviar la reserva.
  Future<void> _confirmReservation() async {
    final option = _selectedOption;

    if (option == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar reserva'),
          content: Text(
            'Cancha: ${widget.sportsSpace.name}\n'
            'Duración: $_durationHours '
            '${_durationHours == 1 ? 'hora' : 'horas'}\n'
            'Horario: ${option.label}',
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
              child: const Text('CONFIRMAR'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _createReservation(option);
    }
  }

  /// Envía el comienzo y el final completos a FastAPI.
  Future<void> _createReservation(_ReservationOption option) async {
    setState(() {
      _isCreatingReservation = true;
      _errorMessage = null;
    });

    try {
      final reservation = await _repository.createReservation(
        sportsSpaceId: widget.sportsSpace.id,
        startDateTime: option.startDateTime,
        endDateTime: option.endDateTime,
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
              'La reserva #${reservation.id} fue creada '
              'por $_durationHours '
              '${_durationHours == 1 ? 'hora' : 'horas'}.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('ACEPTAR'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      // Quita de la pantalla los intervalos recién ocupados.
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
    final options = _buildReservationOptions();

    return Scaffold(
      appBar: AppBar(title: const Text('DISPONIBILIDAD')),
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(widget.sportsSpace.sportType.displayName),
                    const SizedBox(height: 22),

                    OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('FECHA: ${_formatDate(_selectedDate)}'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'DURACIÓN',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const SizedBox(
                              width: double.infinity,
                              child: Text(
                                '1 HORA',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            selected: _durationHours == 1,
                            onSelected: (_) {
                              _changeDuration(1);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const SizedBox(
                              width: double.infinity,
                              child: Text(
                                '2 HORAS',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            selected: _durationHours == 2,
                            onSelected: (_) {
                              _changeDuration(2);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage != null) ...[
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 14),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _loadAvailability,
                        icon: const Icon(Icons.refresh),
                        label: const Text('REINTENTAR'),
                      ),
                    ] else if (options.isEmpty) ...[
                      const Icon(Icons.event_busy, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _durationHours == 2
                            ? 'No hay dos horas consecutivas '
                                  'disponibles para esta fecha.'
                            : 'No hay horarios disponibles '
                                  'para esta fecha.',
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Text(
                        'HORARIOS DISPONIBLES',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final option in options)
                            ChoiceChip(
                              label: Text(option.label),
                              selected: _selectedOption == option,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedOption = selected ? option : null;
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

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedOption == null || _isCreatingReservation
                        ? null
                        : _confirmReservation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: _isCreatingReservation
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _selectedOption == null
                                  ? 'SELECCIONÁ UN HORARIO'
                                  : 'RESERVAR '
                                        '$_durationHours '
                                        '${_durationHours == 1 ? 'HORA' : 'HORAS'}',
                            ),
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
