import 'package:flutter/material.dart';

import '../../data/models/reservation.dart';

/// Tarjeta utilizada para mostrar una reserva.
class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.reservation, this.onCancel});

  final Reservation reservation;

  /// Si es null, la tarjeta no muestra el botón de cancelar.
  final VoidCallback? onCancel;

  String _formatDate(DateTime value) {
    final localValue = value.toLocal();

    final day = localValue.day.toString().padLeft(2, '0');

    final month = localValue.month.toString().padLeft(2, '0');

    return '$day/$month/${localValue.year}';
  }

  String _formatTime(DateTime value) {
    final localValue = value.toLocal();

    final hour = localValue.hour.toString().padLeft(2, '0');

    final minute = localValue.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Color _statusColor(BuildContext context) {
    return switch (reservation.status) {
      ReservationStatus.confirmed => Colors.green,
      ReservationStatus.cancelled => Theme.of(context).colorScheme.error,
    };
  }

  IconData get _statusIcon {
    return switch (reservation.status) {
      ReservationStatus.confirmed => Icons.check_circle_outline,
      ReservationStatus.cancelled => Icons.cancel_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reserva #${reservation.id}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 17, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        reservation.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.sports, size: 19),
                const SizedBox(width: 8),
                Text('Espacio #${reservation.sportsSpaceId}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 19),
                const SizedBox(width: 8),
                Text(_formatDate(reservation.startDateTime)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 19),
                const SizedBox(width: 8),
                Text(
                  '${_formatTime(reservation.startDateTime)} '
                  'a ${_formatTime(reservation.endDateTime)}',
                ),
              ],
            ),
            if (onCancel != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar reserva'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
