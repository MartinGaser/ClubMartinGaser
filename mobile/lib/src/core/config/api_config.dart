/// Configuración central de la API.
///
/// El emulador Android utiliza 10.0.2.2 para acceder
/// al localhost de la computadora anfitriona.
class ApiConfig {
  ApiConfig._();

  /// Dirección local de FastAPI cuando Flutter se ejecuta
  /// dentro del emulador oficial de Android.
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// Tiempo máximo de espera para una petición.
  static const Duration timeout = Duration(seconds: 15);
}
