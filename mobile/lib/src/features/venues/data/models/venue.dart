/// Modelo que representa una sede deportiva recibida desde FastAPI.
class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.openingTime,
    required this.closingTime,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String address;
  final String openingTime;
  final String closingTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Convierte el JSON devuelto por FastAPI en un objeto Venue.
  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      openingTime: json['opening_time'] as String,
      closingTime: json['closing_time'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Devuelve un horario corto, por ejemplo 09:00.
  String _shortTime(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5);
    }

    return time;
  }

  String get formattedOpeningTime => _shortTime(openingTime);

  String get formattedClosingTime => _shortTime(closingTime);

  /// Texto listo para mostrar el horario completo.
  String get scheduleText {
    return '$formattedOpeningTime a $formattedClosingTime';
  }
}
