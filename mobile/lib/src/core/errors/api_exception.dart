/// Excepción utilizada para representar errores de FastAPI.
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.details});

  /// Mensaje entendible para mostrar en Flutter.
  final String message;

  /// Código HTTP recibido, por ejemplo 401, 404 o 422.
  final int? statusCode;

  /// Información adicional devuelta por FastAPI.
  final Object? details;

  @override
  String toString() {
    return message;
  }
}
