import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/network/api_client.dart';

/// Configura Firebase Cloud Messaging y registra el dispositivo.
class NotificationService {
  NotificationService(this._apiClient, {FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final ApiClient _apiClient;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _registrationSubscription;

  /// Solicita permiso y registra la instalación en FastAPI.
  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    final isAllowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!isAllowed) {
      return;
    }

    // El listener debe configurarse antes de llamar register().
    _registrationSubscription = _messaging.onRegistered.listen(
      _registerInstallation,
      onError: (Object error) {
        // La aplicación continúa funcionando si falla FCM.
      },
    );

    // Solicita el registro y provoca la emisión en onRegistered.
    await _messaging.register();
  }

  /// Envía el Firebase Installation ID a FastAPI.
  Future<void> _registerInstallation(String installationId) async {
    if (installationId.trim().isEmpty) {
      return;
    }

    await _apiClient.post(
      '/api/device-tokens',
      body: {'token': installationId.trim()},
    );
  }

  /// Libera el listener cuando Home deja de utilizarse.
  Future<void> dispose() async {
    await _registrationSubscription?.cancel();
  }
}
