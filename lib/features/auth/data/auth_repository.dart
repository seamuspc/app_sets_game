import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth. Screens and providers talk to this,
/// never to FirebaseAuth.instance directly — that keeps Firebase-specific
/// code in one place, so swapping backends later only means editing here.
class AuthRepository {
  AuthRepository(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  /// Emits the current user whenever sign-in state changes (including on
  /// app start, once Firebase has restored any existing session).
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}
