import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opencloud/services/auth_client.dart';

/// Options of a base project whose API key is [kTestApiKey].
const FirebaseOptions kTestOptions = FirebaseOptions(
  apiKey: kTestApiKey,
  appId: "1:12345:android:abcdef",
  messagingSenderId: "12345",
  projectId: "test-project-id",
);

/// Mixed-case, like real API keys (`AIza...`).
const String kTestApiKey = "AIzaTestApiKey";

/// The legacy derived-credential account of [kTestOptions].
const String kLegacyEmail = "$kTestApiKey@opencloud.org";
const String kLegacyPassword = kTestApiKey;

class FakeUser extends Fake implements User {
  FakeUser({required this.uid, required this.email});

  @override
  final String uid;

  @override
  final String? email;
}

class FakeUserCredential extends Fake implements UserCredential {
  FakeUserCredential(this.user);

  @override
  final User? user;
}

class _Account {
  _Account(this.uid, this.email, this.password);

  final String uid;
  String email;
  String password;
  String? pendingEmail;
  bool tokensRevoked = false;
}

/// In-memory [AuthClient] that behaves like Firebase Auth with email
/// enumeration protection: every bad email/password pair is reported as
/// `invalid-credential`. Like Firebase, it matches emails without regard to
/// case and stores them lowercased.
class FakeAuthClient implements AuthClient {
  final List<_Account> _accounts = [];
  final StreamController<User?> _changes = StreamController.broadcast();
  _Account? _current;
  // Like Firebase, the signed-in user is a snapshot: a changed email only
  // shows up after reload().
  String? _sessionEmail;
  int _nextUid = 1;

  /// Every call made, in order, e.g. `signIn a@b.c` or `updatePassword pw`.
  final List<String> calls = [];

  /// Adds an account; signs into it when [signedIn] (a restored session).
  void addAccount(String email, String password, {bool signedIn = false}) {
    final account =
        _Account("uid-${_nextUid++}", email.toLowerCase(), password);
    _accounts.add(account);
    if (signedIn) {
      _current = account;
      _sessionEmail = account.email;
    }
  }

  String? passwordOf(String email) => _find(email)?.password;

  String? pendingEmailOf(String email) => _find(email)?.pendingEmail;

  /// What clicking the verification link does: the email changes and the
  /// account's existing sessions are revoked.
  void clickVerificationLink(String email) {
    final account = _find(email)!;
    account.email = account.pendingEmail!.toLowerCase();
    account.pendingEmail = null;
    account.tokensRevoked = true;
  }

  _Account? _find(String email) {
    for (final account in _accounts) {
      if (account.email == email.toLowerCase()) return account;
    }
    return null;
  }

  _Account _requireCurrent() {
    final account = _current;
    if (account == null) {
      throw FirebaseAuthException(code: "no-current-user");
    }
    return account;
  }

  void _signInAs(_Account? account) {
    final changed = _current?.uid != account?.uid;
    _current = account;
    _sessionEmail = account?.email;
    if (changed) _changes.add(currentUser);
  }

  @override
  User? get currentUser {
    final account = _current;
    return account == null
        ? null
        : FakeUser(uid: account.uid, email: _sessionEmail);
  }

  @override
  Stream<User?> get authStateChanges async* {
    yield currentUser;
    yield* _changes.stream;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    calls.add("signIn $email");
    final account = _find(email);
    if (account == null || account.password != password) {
      throw FirebaseAuthException(code: "invalid-credential");
    }
    account.tokensRevoked = false;
    _signInAs(account);
    return FakeUserCredential(currentUser);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    calls.add("createUser $email");
    if (_find(email) != null) {
      throw FirebaseAuthException(code: "email-already-in-use");
    }
    if (password.length < 6) {
      throw FirebaseAuthException(code: "weak-password");
    }
    addAccount(email, password);
    _signInAs(_accounts.last);
    return FakeUserCredential(currentUser);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    calls.add("updatePassword $newPassword");
    _requireCurrent().password = newPassword;
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail) async {
    calls.add("verifyBeforeUpdateEmail $newEmail");
    _requireCurrent().pendingEmail = newEmail;
  }

  @override
  Future<void> reload() async {
    calls.add("reload");
    final account = _requireCurrent();
    if (account.tokensRevoked) {
      throw FirebaseAuthException(code: "user-token-expired");
    }
    _sessionEmail = account.email;
  }

  @override
  Future<void> signOut() async {
    calls.add("signOut");
    _signInAs(null);
  }
}
