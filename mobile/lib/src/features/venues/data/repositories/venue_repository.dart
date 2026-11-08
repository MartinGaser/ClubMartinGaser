import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/venue.dart';

/// Repositorio encargado de obtener sedes desde FastAPI.
class VenueRepository {
  const VenueRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Obtiene únicamente las sedes activas.
  Future<List<Venue>> getActiveVenues() async {
    final result = await _apiClient.get(
      '/api/venues',
      queryParameters: const {'active_only': 'true'},

      // El listado de sedes es público en el backend actual.
      authenticated: false,
    );

    if (result is! List) {
      throw const ApiException(
        message: 'El servidor devolvió una lista de sedes inválida.',
      );
    }

    return result
        .map((item) => Venue.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene una sede determinada.
  Future<Venue> getVenueById(int venueId) async {
    final result = await _apiClient.get(
      '/api/venues/$venueId',
      authenticated: false,
    );

    if (result is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'El servidor devolvió una sede inválida.',
      );
    }

    return Venue.fromJson(result);
  }
}
