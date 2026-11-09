/// Representa un turno disponible de una hora.
class AvailabilitySlot {
  const AvailabilitySlot({
    required this.startDateTime,
    required this.endDateTime,
  });

  final DateTime startDateTime;
  final DateTime endDateTime;

  /// Convierte el JSON recibido desde FastAPI.
  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      startDateTime: DateTime.parse(json['start_datetime'] as String),
      endDateTime: DateTime.parse(json['end_datetime'] as String),
    );
  }

  /// Devuelve una hora con formato HH:mm.
  String _formatTime(DateTime value) {
    final localValue = value.toLocal();

    final hour = localValue.hour.toString().padLeft(2, '0');

    final minute = localValue.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String get startTimeText => _formatTime(startDateTime);

  String get endTimeText => _formatTime(endDateTime);

  String get label => '$startTimeText a $endTimeText';
}

/// Representa la disponibilidad completa de un espacio.
class SpaceAvailability {
  const SpaceAvailability({
    required this.sportsSpaceId,
    required this.requestedDate,
    required this.openingTime,
    required this.closingTime,
    required this.availableSlots,
  });

  final int sportsSpaceId;
  final DateTime requestedDate;
  final String openingTime;
  final String closingTime;
  final List<AvailabilitySlot> availableSlots;

  factory SpaceAvailability.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['available_slots'] as List<dynamic>;

    return SpaceAvailability(
      sportsSpaceId: json['sports_space_id'] as int,
      requestedDate: DateTime.parse(json['requested_date'] as String),
      openingTime: json['opening_time'] as String,
      closingTime: json['closing_time'] as String,
      availableSlots: rawSlots
          .map(
            (item) => AvailabilitySlot.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
