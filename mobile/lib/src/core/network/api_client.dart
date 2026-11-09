// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/data/services/auth_service.dart';
import '../config/api_config.dart';
import '../errors/api_exception.dart';

/// Cliente HTTP central de ClubMartinGaser.
///
/// Obtiene el token actualizado de Firebase y lo envía
/// automáticamente a FastAPI en cada petición autenticada.
class ApiClient {
  // Se utiliza un parámetro nombrado para que la creación
  // del cliente resulte más clara en las pantallas.

  ApiClient({required AuthService authService, http.Client? httpClient})
    : _authService = authService,
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Construye una dirección completa hacia FastAPI.
  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: queryParameters);
  }

  /// Construye los encabezados utilizados por la API.
  ///
  /// Cuando la petición es autenticada, obtiene un ID token
  /// actualizado de Firebase y lo envía como Bearer token.
  Future<Map<String, String>> _buildHeaders({bool authenticated = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (!authenticated) {
      return headers;
    }

    final token = await _authService.getIdToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        message:
            ('La sesión no es válida. '
            'Iniciá sesión nuevamente.'),
        statusCode: 401,
      );
    }

    // FastAPI espera exactamente:
    // Authorization: Bearer TOKEN
    headers['Authorization'] = 'Bearer $token';

    return headers;
  }

  /// Ejecuta una petición GET.
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async {
    try {
      final response = await _httpClient
          .get(
            _buildUri(path, queryParameters),
            headers: await _buildHeaders(authenticated: authenticated),
          )
          .timeout(ApiConfig.timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'El servidor tardó demasiado en responder.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        message: 'No se pudo conectar con el servidor.',
        details: error,
      );
    }
  }

  /// Ejecuta una petición POST con un cuerpo JSON.
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      final response = await _httpClient
          .post(
            _buildUri(path),
            headers: await _buildHeaders(authenticated: authenticated),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(ApiConfig.timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'El servidor tardó demasiado en responder.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        message: 'No se pudo conectar con el servidor.',
        details: error,
      );
    }
  }

  /// Ejecuta una petición PUT con un cuerpo JSON.
  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      final response = await _httpClient
          .put(
            _buildUri(path),
            headers: await _buildHeaders(authenticated: authenticated),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(ApiConfig.timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'El servidor tardó demasiado en responder.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        message: 'No se pudo conectar con el servidor.',
        details: error,
      );
    }
  }

  /// Ejecuta una petición PATCH con un cuerpo JSON.
  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    try {
      final response = await _httpClient
          .patch(
            _buildUri(path),
            headers: await _buildHeaders(authenticated: authenticated),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(ApiConfig.timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'El servidor tardó demasiado en responder.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        message: 'No se pudo conectar con el servidor.',
        details: error,
      );
    }
  }

  /// Ejecuta una petición DELETE.
  Future<dynamic> delete(String path, {bool authenticated = true}) async {
    try {
      final response = await _httpClient
          .delete(
            _buildUri(path),
            headers: await _buildHeaders(authenticated: authenticated),
          )
          .timeout(ApiConfig.timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'El servidor tardó demasiado en responder.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        message: 'No se pudo conectar con el servidor.',
        details: error,
      );
    }
  }

  /// Procesa el código HTTP y decodifica el cuerpo recibido.
  dynamic _processResponse(http.Response response) {
    dynamic data;

    if (response.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        data = utf8.decode(response.bodyBytes);
      }
    }

    // Los códigos entre 200 y 299 representan éxito.
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final backendMessage = _extractErrorMessage(data);

    throw ApiException(
      message: backendMessage ?? _defaultMessageForStatus(response.statusCode),
      statusCode: response.statusCode,
      details: data,
    );
  }

  /// Extrae el mensaje enviado por FastAPI en el campo detail.
  String? _extractErrorMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final detail = data['detail'];

    if (detail is String) {
      return detail;
    }

    // Los errores 422 de Pydantic suelen contener una lista.
    if (detail is List && detail.isNotEmpty) {
      final firstError = detail.first;

      if (firstError is Map<String, dynamic>) {
        final message = firstError['msg'];

        if (message is String) {
          return message;
        }
      }
    }

    return null;
  }

  /// Proporciona un mensaje para cada código HTTP frecuente.
  String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'La solicitud enviada no es válida.';

      case 401:
        return 'La sesión venció. Iniciá sesión nuevamente.';

      case 403:
        return 'No tenés permisos para realizar esta operación.';

      case 404:
        return 'El recurso solicitado no existe.';

      case 409:
        return ('La operación entra en conflicto '
            'con datos existentes.');

      case 422:
        return 'Revisá los datos ingresados.';

      case 500:
        return 'El servidor encontró un error inesperado.';

      default:
        return 'No se pudo completar la operación.';
    }
  }

  /// Libera los recursos del cliente HTTP.
  void close() {
    _httpClient.close();
  }
}
