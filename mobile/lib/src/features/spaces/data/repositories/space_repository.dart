import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/sports_space.dart';

/// Repositorio encargado de consultar espacios deportivos.
class SportsSpaceRepository {
  // ignore: prefer_initializing_formals
  const SportsSpaceRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Obtiene los espacios activos de una sede.
  ///
  /// sportType es opcional y permite filtrar por deporte.
  Future<List<SportsSpace>> getSpaces({
    required int venueId,
    SportType? sportType,
  }) async {
    final parameters = <String, String>{
      'venue_id': venueId.toString(),
      'active_only': 'true',
    };

    if (sportType != null) {
      parameters['sport_type'] = sportType.apiValue;
    }

    final result = await _apiClient.get(
      '/api/spaces',
      queryParameters: parameters,
      authenticated: false,
    );

    if (result is! List) {
      throw const ApiException(
        message:
            ('El servidor devolviÃ³ una lista '
            'de espacios invÃ¡lida.'),
      );
    }

    return result
        .map((item) => SportsSpace.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene un espacio mediante su identificador.
  Future<SportsSpace> getSpaceById(int spaceId) async {
    final result = await _apiClient.get(
      '/api/spaces/$spaceId',
      authenticated: false,
    );

    if (result is! Map<String, dynamic>) {
      throw const ApiException(
        message:
            ('El servidor devolviÃ³ '
            'un espacio invÃ¡lido.'),
      );
    }

    return SportsSpace.fromJson(result);
  }
}
