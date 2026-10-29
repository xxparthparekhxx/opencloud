import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:opencloud/services/auth_client.dart';

/// The email an install from before real accounts signed in with, derived
/// from the base project's API key.
///
/// Firebase API keys are not secret (they ship in every app config), so
/// anyone holding the config could sign into that account. Such accounts are
/// moved to the user's own credentials by [AuthService.secureLegacyAccount].
String legacyAccountEmail(FirebaseOptions options) =>
    "${options.apiKey}@opencloud.org";

/// The password that went with [legacyAccountEmail]: the API key itself.
String legacyAccountPassword(FirebaseOptions options) => options.apiKey;

/// Where the signed-in account stands, as far as the app's screens go.
enum AccountStatus {
  /// Nobody is signed in.
  signedOut,

  /// A restored session is being checked (see [AuthService.checkAccount]).
  checking,

  /// Signed into a legacy account that still accepts the derived password:
  /// the user has to choose their own email and password.
  needsSecuring,

  /// The legacy account was just secured: the user should be told that the
  /// email change completes when they click the verification link.
  emailChangeSent,

  /// Secured earlier, but the verification link has not been clicked yet, so
  /// the account still has the legacy email. The new password is in effect.
  awaitingEmailChange,

  /// Signed into an account with the user's own credentials.
  ready,
}

/// Error codes Firebase uses for a wrong email/password pair. With email
/// enumeration protection (the default for newer projects) every bad
/// credential is reported as `invalid-credential`.
const Set<String> kBadCredentialCodes = {
  "invalid-credential",
  "wrong-password",
  "user-not-found",
  "INVALID_LOGIN_CREDENTIALS",
};

bool isBadCredential(Object error) =>
    error is FirebaseAuthException && kBadCredentialCodes.contains(error.code);

/// Error codes meaning the restored session is no longer valid, e.g. because
/// the email change was confirmed and Firebase revoked the old tokens.
const Set<String> _sessionEndedCodes = {
  "user-token-expired",
  "invalid-user-token",
  "user-not-found",
  "user-disabled",
};

/// Firebase Authentication for the base project.
///
/// Users sign in with their own email/password. Firebase Auth persists the
/// session on the device; this class stores nothing itself.
class AuthService {
  AuthService({required FirebaseOptions options, required AuthClient client})
      : _client = client,
        legacyEmail = legacyAccountEmail(options),
        _legacyPassword = legacyAccountPassword(options);

  /// Auth for the base project [app].
  factory AuthService.forApp(FirebaseApp app) => AuthService(
        options: app.options,
        client: FirebaseAuthClient(app: app),
      );

  final AuthClient _client;

  /// Email of this project's legacy derived-credential account.
  final String legacyEmail;
  final String _legacyPassword;

  /// Firebase Auth stores emails lowercased, while API keys (`AIza...`) are
  /// mixed-case, so compare without regard to case.
  bool _isLegacyEmail(String? email) =>
      email != null && email.toLowerCase() == legacyEmail.toLowerCase();

  User? get user => _client.currentUser;

  Stream<User?> get authStateChanges => _client.authStateChanges;

  /// Signs in with an existing account. Failures (wrong password, unknown
  /// account, ...) are rethrown as `FirebaseAuthException`.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _client.signInWithEmailAndPassword(email: email, password: password);

  /// Creates an account with the user's own email/password and signs into
  /// it. Failures (email in use, weak password, ...) are rethrown as
  /// `FirebaseAuthException`.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) =>
      _client.createUserWithEmailAndPassword(email: email, password: password);

  /// Works out the [AccountStatus] of the current session.
  ///
  /// Accounts with the user's own email are [AccountStatus.ready] without a
  /// network call. A session on the legacy email is refreshed first (the
  /// verification link may have been clicked since), and then probed with
  /// the derived password: if Firebase still accepts it the account
  /// [AccountStatus.needsSecuring], otherwise it was already secured and is
  /// [AccountStatus.awaitingEmailChange].
  Future<AccountStatus> checkAccount() async {
    final user = _client.currentUser;
    if (user == null) return AccountStatus.signedOut;
    if (!_isLegacyEmail(user.email)) return AccountStatus.ready;

    try {
      await _client.reload();
    } on FirebaseAuthException catch (e) {
      if (!_sessionEndedCodes.contains(e.code)) rethrow;
      await _client.signOut();
      return AccountStatus.signedOut;
    }
    final refreshed = _client.currentUser;
    if (refreshed == null) return AccountStatus.signedOut;
    if (!_isLegacyEmail(refreshed.email)) return AccountStatus.ready;

    try {
      await _client.signInWithEmailAndPassword(
        email: legacyEmail,
        password: _legacyPassword,
      );
      return AccountStatus.needsSecuring;
    } on FirebaseAuthException catch (e) {
      if (isBadCredential(e)) return AccountStatus.awaitingEmailChange;
      rethrow;
    }
  }

  /// The one-time "secure your account" step for legacy accounts: signs in
  /// with the derived credentials, replaces the password with [newPassword],
  /// then asks Firebase to move the account to [newEmail].
  ///
  /// The email change only completes when the user clicks the verification
  /// link Firebase sends to [newEmail]; until then the account keeps the
  /// legacy email, with [newPassword] already in effect.
  ///
  /// If the derived password is no longer accepted, the account was secured
  /// before (and the link never clicked, or the email request failed). Then
  /// [newPassword] must be the password chosen back then: the link is sent
  /// again, to [newEmail], without changing the password.
  Future<void> secureLegacyAccount({
    required String newEmail,
    required String newPassword,
  }) async {
    try {
      await _client.signInWithEmailAndPassword(
        email: legacyEmail,
        password: _legacyPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (!isBadCredential(e)) rethrow;
      await _client.signInWithEmailAndPassword(
        email: legacyEmail,
        password: newPassword,
      );
      await _client.verifyBeforeUpdateEmail(newEmail);
      return;
    }
    await _client.updatePassword(newPassword);
    await _client.verifyBeforeUpdateEmail(newEmail);
  }

  Future<void> signOut() => _client.signOut();
}
