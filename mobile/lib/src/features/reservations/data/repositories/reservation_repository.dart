import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/availability.dart';
import '../models/reservation.dart';

/// Repositorio que comunica Flutter con los endpoints de reservas.
class ReservationRepository {
  const ReservationRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Consulta los turnos disponibles para una fecha.
  Future<SpaceAvailability> getAvailability({
    required int sportsSpaceId,
    required DateTime requestedDate,
  }) async {
    final formattedDate = _formatDate(requestedDate);

    final result = await _apiClient.get(
      '/api/spaces/$sportsSpaceId/availability',
      queryParameters: {'requested_date': formattedDate},
      authenticated: false,
    );

    if (result is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'El servidor devolvió una disponibilidad inválida.',
      );
    }

    return SpaceAvailability.fromJson(result);
  }

  /// Crea una reserva para el usuario autenticado.
  Future<Reservation> createReservation({
    required int sportsSpaceId,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) async {
    final result = await _apiClient.post(
      '/api/reservations',
      body: {
        'sports_space_id': sportsSpaceId,
        'start_datetime': startDateTime.toIso8601String(),
        'end_datetime': endDateTime.toIso8601String(),
      },
    );

    if (result is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'El servidor devolvió una reserva inválida.',
      );
    }

    return Reservation.fromJson(result);
  }

  /// Convierte una fecha a YYYY-MM-DD.
  String _formatDate(DateTime date) {
    final year = date.year.toString();

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
