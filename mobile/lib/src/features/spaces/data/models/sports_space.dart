/// Tipos de deporte admitidos por FastAPI.
enum SportType {
  football,
  tennis,
  padel,
  basketball,
  volleyball,
  swimming,
  other;

  /// Convierte el valor recibido desde FastAPI.
  factory SportType.fromApi(String value) {
    return switch (value.toUpperCase()) {
      'FOOTBALL' => SportType.football,
      'TENNIS' => SportType.tennis,
      'PADEL' => SportType.padel,
      'BASKETBALL' => SportType.basketball,
      'VOLLEYBALL' => SportType.volleyball,
      'SWIMMING' => SportType.swimming,
      _ => SportType.other,
    };
  }

  /// Valor utilizado al enviar filtros a FastAPI.
  String get apiValue {
    return name.toUpperCase();
  }

  /// Nombre visible en la aplicacion.
  String get displayName {
    return switch (this) {
      SportType.football => 'Futbol',
      SportType.tennis => 'Tenis',
      SportType.padel => 'Padel',
      SportType.basketball => 'Basquet',
      SportType.volleyball => 'Voley',
      SportType.swimming => 'Natacion',
      SportType.other => 'Otro',
    };
  }
}

/// Modelo que representa un espacio deportivo.
class SportsSpace {
  const SportsSpace({
    required this.id,
    required this.venueId,
    required this.name,
    required this.sportType,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int venueId;
  final String name;
  final SportType sportType;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Convierte la respuesta JSON de FastAPI.
  factory SportsSpace.fromJson(Map<String, dynamic> json) {
    return SportsSpace(
      id: json['id'] as int,
      venueId: json['venue_id'] as int,
      name: json['name'] as String,
      sportType: SportType.fromApi(json['sport_type'] as String),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
