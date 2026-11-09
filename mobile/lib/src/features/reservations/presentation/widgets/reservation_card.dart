import 'package:flutter/material.dart';

import '../../data/models/reservation.dart';

/// Tarjeta que representa una reserva.
class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.reservation, this.onCancel});

  final Reservation reservation;
  final VoidCallback? onCancel;

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = reservation.status == ReservationStatus.cancelled;

    final statusColor = isCancelled
        ? Theme.of(context).colorScheme.error
        : Colors.green;

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
                        ?.copyWith(fontWeight: FontWeight.w800),
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
                  child: Text(
                    reservation.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Espacio deportivo #${reservation.sportsSpaceId}'),
            const SizedBox(height: 8),
            Text('Fecha: ${_formatDate(reservation.startDateTime)}'),
            const SizedBox(height: 8),
            Text(
              'Horario: '
              '${_formatTime(reservation.startDateTime)} '
              'a ${_formatTime(reservation.endDateTime)}',
            ),
            if (onCancel != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('CANCELAR RESERVA'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
