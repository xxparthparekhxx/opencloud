import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opencloud/services/auth_service.dart';

import '../support/fake_auth_client.dart';

Matcher get _throwsBadCredential => throwsA(
      isA<FirebaseAuthException>()
          .having(isBadCredential, 'is a bad credential', isTrue),
    );

void main() {
  late FakeAuthClient client;
  late AuthService auth;

  setUp(() {
    client = FakeAuthClient();
    auth = AuthService(options: kTestOptions, client: client);
  });

  test('derives the legacy account from the API key', () {
    expect(legacyAccountEmail(kTestOptions), kLegacyEmail);
    expect(legacyAccountPassword(kTestOptions), kLegacyPassword);
    expect(auth.legacyEmail, kLegacyEmail);
  });

  group('signUp', () {
    test('creates an account with the email and password the user chose',
        () async {
      await auth.signUp(email: 'me@example.com', password: 'hunter22');

      expect(client.calls, ['createUser me@example.com']);
      expect(auth.user!.email, 'me@example.com');
      expect(client.passwordOf('me@example.com'), 'hunter22');
    });

    test('rethrows when the email is already taken', () async {
      client.addAccount('me@example.com', 'hunter22');

      await expectLater(
        auth.signUp(email: 'me@example.com', password: 'other-pass'),
        throwsA(isA<FirebaseAuthException>()
            .having((e) => e.code, 'code', 'email-already-in-use')),
      );
      expect(auth.user, isNull);
    });
  });

  group('signIn', () {
    test('signs into an existing account', () async {
      client.addAccount('me@example.com', 'hunter22');

      await auth.signIn(email: 'me@example.com', password: 'hunter22');

      expect(client.calls, ['signIn me@example.com']);
      expect(auth.user!.email, 'me@example.com');
    });

    test('rethrows a bad-credential error on a wrong password', () async {
      client.addAccount('me@example.com', 'hunter22');

      await expectLater(
        auth.signIn(email: 'me@example.com', password: 'wrong-pass'),
        _throwsBadCredential,
      );
      expect(auth.user, isNull);
    });
  });

  group('secureLegacyAccount', () {
    test(
        'signs in with the derived credentials, then calls updatePassword '
        'and verifyBeforeUpdateEmail', () async {
      client.addAccount(kLegacyEmail, kLegacyPassword, signedIn: true);

      await auth.secureLegacyAccount(
        newEmail: 'me@example.com',
        newPassword: 'new-secret',
      );

      expect(client.calls, [
        'signIn $kLegacyEmail',
        'updatePassword new-secret',
        'verifyBeforeUpdateEmail me@example.com',
      ]);
      // The derived password stops working right away; the email only
      // changes once the verification link is clicked.
      expect(client.passwordOf(kLegacyEmail), 'new-secret');
      expect(client.pendingEmailOf(kLegacyEmail), 'me@example.com');
      expect(auth.user!.email, kLegacyEmail.toLowerCase());
    });

    test('works without a restored session', () async {
      client.addAccount(kLegacyEmail, kLegacyPassword);

      await auth.secureLegacyAccount(
        newEmail: 'me@example.com',
        newPassword: 'new-secret',
      );

      expect(client.passwordOf(kLegacyEmail), 'new-secret');
      expect(client.pendingEmailOf(kLegacyEmail), 'me@example.com');
    });

    test(
        'resends the link for an account secured before, without changing '
        'its password', () async {
      client.addAccount(kLegacyEmail, 'chosen-before');

      await auth.secureLegacyAccount(
        newEmail: 'fixed@example.com',
        newPassword: 'chosen-before',
      );

      expect(client.calls, [
        'signIn $kLegacyEmail',
        'signIn $kLegacyEmail',
        'verifyBeforeUpdateEmail fixed@example.com',
      ]);
      expect(client.passwordOf(kLegacyEmail), 'chosen-before');
      expect(client.pendingEmailOf(kLegacyEmail), 'fixed@example.com');
    });

    test('rethrows a bad credential when neither password is accepted',
        () async {
      client.addAccount(kLegacyEmail, 'chosen-before');

      await expectLater(
        auth.secureLegacyAccount(
          newEmail: 'me@example.com',
          newPassword: 'not-it',
        ),
        _throwsBadCredential,
      );
      expect(client.calls, isNot(contains(startsWith('updatePassword'))));
      expect(client.calls,
          isNot(contains(startsWith('verifyBeforeUpdateEmail'))));
    });
  });

  group('checkAccount', () {
    test('is signedOut without a session', () async {
      expect(await auth.checkAccount(), AccountStatus.signedOut);
    });

    test('is ready for an own-email account, without calling Firebase',
        () async {
      client.addAccount('me@example.com', 'hunter22', signedIn: true);

      expect(await auth.checkAccount(), AccountStatus.ready);
      expect(client.calls, isEmpty);
    });

    test('needs securing while the derived password is still accepted',
        () async {
      client.addAccount(kLegacyEmail, kLegacyPassword, signedIn: true);
      // Firebase returns the email lowercased; the API key is mixed-case.
      expect(auth.user!.email, isNot(kLegacyEmail));

      expect(await auth.checkAccount(), AccountStatus.needsSecuring);
    });

    test('awaits the email change once the account was secured', () async {
      client.addAccount(kLegacyEmail, kLegacyPassword, signedIn: true);
      await auth.secureLegacyAccount(
        newEmail: 'me@example.com',
        newPassword: 'new-secret',
      );

      expect(await auth.checkAccount(), AccountStatus.awaitingEmailChange);
    });

    test('signs out once the link was clicked and the old session revoked',
        () async {
      client.addAccount(kLegacyEmail, kLegacyPassword, signedIn: true);
      await auth.secureLegacyAccount(
        newEmail: 'me@example.com',
        newPassword: 'new-secret',
      );
      client.clickVerificationLink(kLegacyEmail);

      expect(await auth.checkAccount(), AccountStatus.signedOut);
      expect(auth.user, isNull);

      // The account now signs in with the user's own credentials.
      await auth.signIn(email: 'me@example.com', password: 'new-secret');
      expect(await auth.checkAccount(), AccountStatus.ready);
    });
  });
}
