import 'package:firebase_auth/firebase_auth.dart';

/// Convierte los cÃ³digos tÃ©cnicos de Firebase en mensajes visibles.
String firebaseAuthErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Ocurrio un error inesperado. Intente nuevamente.';
  }

  switch (error.code) {
    case 'invalid-email':
      return 'El correo electronico no tiene un formato valido.';

    case 'user-disabled':
      return 'La cuenta se encuentra deshabilitada.';

    case 'user-not-found':
      return 'No existe una cuenta asociada a ese correo.';

    case 'wrong-password':
    case 'invalid-credential':
      return 'El correo o la contraseÃ±a son incorrectos.';

    case 'email-already-in-use':
      return 'El correo electronico ya se encuentra registrado.';

    case 'weak-password':
      return 'La contraseÃ±a debe tener al menos 6 caracteres.';

    case 'too-many-requests':
      return 'Se realizaron demasiados intentos. Intente mas tarde.';

    case 'network-request-failed':
      return 'No se pudo establecer conexion con Firebase.';

    default:
      return error.message ?? 'No se pudo completar la operacion solicitada.';
  }
}
