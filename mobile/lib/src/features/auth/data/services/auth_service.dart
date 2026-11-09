import 'package:firebase_auth/firebase_auth.dart';

/// Servicio encargado de comunicarse con Firebase Authentication.
///
/// Las pantallas no acceden directamente a Firebase. En su lugar,
/// utilizan esta clase para registrar, iniciar o cerrar sesiÃ³n.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  /// Devuelve el usuario que tiene una sesiÃ³n activa.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Informa los cambios de autenticaciÃ³n.
  ///
  /// Emite un usuario cuando se inicia sesiÃ³n y null cuando se cierra.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Registra una cuenta mediante correo electrÃ³nico y contraseÃ±a.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Inicia sesiÃ³n con una cuenta existente.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// EnvÃ­a un correo para restablecer la contraseÃ±a.
  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Cierra la sesiÃ³n activa.
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  /// Obtiene el token que posteriormente enviaremos a FastAPI.
  Future<String?> getIdToken() async {
    // Guarda el usuario autenticado actualmente.
    final user = _firebaseAuth.currentUser;

    // Si no existe una sesiÃ³n, no hay token para enviar.
    if (user == null) {
      return null;
    }

    // Espera a que Firebase genere o recupere el ID token.
    return await user.getIdToken(true);
  }
}
