import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/availability.dart';
import '../models/reservation.dart';

/// Comunica Flutter con los endpoints de reservas de FastAPI.
class ReservationRepository {
  const ReservationRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Consulta los turnos disponibles de un espacio para una fecha.
  Future<SpaceAvailability> getAvailability({
    required int sportsSpaceId,
    required DateTime requestedDate,
  }) async {
    final formattedDate = _formatDate(requestedDate);

    final result = await _apiClient.get(
      '/api/spaces/$sportsSpaceId/availability',
      queryParameters: {'requested_date': formattedDate},

      // La disponibilidad puede consultarse sin autenticación.
      authenticated: false,
    );

    if (result is! Map<String, dynamic>) {
      throw const ApiException(
        message:
            ('El servidor devolvió '
            'una disponibilidad inválida.'),
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
        message:
            ('El servidor devolvió '
            'una reserva inválida.'),
      );
    }

    return Reservation.fromJson(result);
  }

  /// Obtiene las reservas futuras y confirmadas.
  Future<List<Reservation>> getFutureReservations() async {
    final result = await _apiClient.get('/api/reservations/me');

    return _parseReservationList(result);
  }

  /// Obtiene las reservas canceladas o finalizadas.
  Future<List<Reservation>> getReservationHistory() async {
    final result = await _apiClient.get('/api/reservations/me/history');

    return _parseReservationList(result);
  }

  /// Cancela una reserva futura del usuario autenticado.
  Future<Reservation> cancelReservation(int reservationId) async {
    final result = await _apiClient.delete('/api/reservations/$reservationId');

    if (result is! Map<String, dynamic>) {
      throw const ApiException(
        message:
            ('El servidor devolvió '
            'una reserva cancelada inválida.'),
      );
    }

    return Reservation.fromJson(result);
  }

  /// Convierte una lista JSON en objetos Reservation.
  List<Reservation> _parseReservationList(dynamic result) {
    if (result is! List) {
      throw const ApiException(
        message:
            ('El servidor devolvió '
            'una lista de reservas inválida.'),
      );
    }

    return result
        .map((item) => Reservation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Convierte una fecha a YYYY-MM-DD.
  String _formatDate(DateTime date) {
    final year = date.year.toString();

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
