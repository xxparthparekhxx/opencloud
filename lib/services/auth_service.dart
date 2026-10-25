import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Handles Firebase Authentication for the currently initialized app.
///
/// The auth operations are scoped to a specific `FirebaseApp` instance so the
/// app can support multiple Firebase projects.
class AuthService extends ChangeNotifier {
  AuthService({required this.app});

  final FirebaseApp app;

  User? get user => FirebaseAuth.instanceFor(app: app).currentUser;

  Stream<User?> get authStateChanges =>
      FirebaseAuth.instanceFor(app: app).authStateChanges();

  /// Sign in with email/password. If the account does not exist
  /// (`user-not-found`) it is created. Any other auth failure is rethrown as
  /// a typed `FirebaseAuthException` so callers can surface it to the user.
  Future<UserCredential> signInOrCreate({
    required String email,
    required String password,
  }) async {
    try {
      return await FirebaseAuth.instanceFor(app: app)
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        return await FirebaseAuth.instanceFor(app: app)
            .createUserWithEmailAndPassword(email: email, password: password);
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instanceFor(app: app).signOut();
  }
}
