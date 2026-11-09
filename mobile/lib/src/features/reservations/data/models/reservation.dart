/// Estados posibles de una reserva.
enum ReservationStatus {
  confirmed,
  cancelled;

  factory ReservationStatus.fromApi(String value) {
    return value.toUpperCase() == 'CANCELLED'
        ? ReservationStatus.cancelled
        : ReservationStatus.confirmed;
  }

  String get displayName {
    return switch (this) {
      ReservationStatus.confirmed => 'Confirmada',
      ReservationStatus.cancelled => 'Cancelada',
    };
  }
}

/// Modelo de una reserva recibida desde FastAPI.
class Reservation {
  const Reservation({
    required this.id,
    required this.userId,
    required this.sportsSpaceId,
    required this.startDateTime,
    required this.endDateTime,
    required this.status,
    required this.createdAt,
    required this.cancelledAt,
  });

  final int id;
  final int userId;
  final int sportsSpaceId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      sportsSpaceId: json['sports_space_id'] as int,
      startDateTime: DateTime.parse(json['start_datetime'] as String),
      endDateTime: DateTime.parse(json['end_datetime'] as String),
      status: ReservationStatus.fromApi(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
    );
  }
}
