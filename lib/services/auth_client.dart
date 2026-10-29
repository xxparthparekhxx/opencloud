import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Minimal seam over `FirebaseAuth` so the auth flow can be unit tested
/// with a fake implementation (no platform channels required).
abstract class AuthClient {
  /// The currently signed-in user, or null.
  User? get currentUser;

  /// Emits the current user on listen, then again whenever the signed-in
  /// user changes (sign-in, sign-out, session restored).
  Stream<User?> get authStateChanges;

  /// Signs in with an existing email/password account.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Creates a new email/password account and signs into it.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Replaces the current user's password. Firebase requires a recent
  /// sign-in for this.
  Future<void> updatePassword(String newPassword);

  /// Emails a verification link to [newEmail]. The account's email address
  /// only changes once the user clicks that link.
  Future<void> verifyBeforeUpdateEmail(String newEmail);

  /// Refreshes the current user's profile (e.g. a changed email address)
  /// from the server.
  Future<void> reload();

  /// Signs the current user out.
  Future<void> signOut();
}

/// [AuthClient] backed by the real `FirebaseAuth` of [app].
class FirebaseAuthClient implements AuthClient {
  FirebaseAuthClient({required FirebaseApp app})
      : _auth = FirebaseAuth.instanceFor(app: app);

  final FirebaseAuth _auth;

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: "no-current-user",
        message: "No user is signed in.",
      );
    }
    return user;
  }

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  @override
  Future<void> updatePassword(String newPassword) =>
      _requireUser().updatePassword(newPassword);

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail) =>
      _requireUser().verifyBeforeUpdateEmail(newEmail);

  @override
  Future<void> reload() => _requireUser().reload();

  @override
  Future<void> signOut() => _auth.signOut();
}
