import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opencloud/providers/openprovider.dart';
import 'package:opencloud/services/auth_service.dart';

import '../support/fake_auth_client.dart';

void main() {
  late FakeAuthClient client;

  OpenDrive openDrive() => OpenDrive.forTesting(
        authService: AuthService(options: kTestOptions, client: client),
      );

  setUp(() {
    client = FakeAuthClient();
  });

  test('starts signed out without a session', () async {
    final drive = openDrive();
    await pumpEventQueue();

    expect(drive.accountStatus, AccountStatus.signedOut);
    expect(drive.user, isNull);
  });

  test('signUp signs into the new account', () async {
    final drive = openDrive();
    await pumpEventQueue();

    await drive.signUp(email: 'me@example.com', password: 'hunter22');

    expect(drive.accountStatus, AccountStatus.ready);
    expect(drive.user!.email, 'me@example.com');
  });

  test('signIn with a wrong password rethrows and stays signed out',
      () async {
    client.addAccount('me@example.com', 'hunter22');
    final drive = openDrive();
    await pumpEventQueue();

    await expectLater(
      drive.signIn(email: 'me@example.com', password: 'wrong-pass'),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(drive.accountStatus, AccountStatus.signedOut);
    expect(drive.user, isNull);
  });

  test('a restored own-email session is ready', () async {
    client.addAccount('me@example.com', 'hunter22', signedIn: true);
    final drive = openDrive();
    await pumpEventQueue();

    expect(drive.accountStatus, AccountStatus.ready);
  });

  test(
      'a restored legacy session must be secured, then waits for the '
      'verification link', () async {
    client.addAccount(kLegacyEmail, kLegacyPassword, signedIn: true);
    final drive = openDrive();
    await pumpEventQueue();
    expect(drive.accountStatus, AccountStatus.needsSecuring);

    client.calls.clear();
    await drive.secureLegacyAccount(
      newEmail: 'me@example.com',
      newPassword: 'new-secret',
    );

    expect(client.calls, [
      'signIn $kLegacyEmail',
      'updatePassword new-secret',
      'verifyBeforeUpdateEmail me@example.com',
    ]);
    expect(drive.accountStatus, AccountStatus.emailChangeSent);
    expect(drive.pendingEmail, 'me@example.com');

    await drive.acknowledgeEmailChangeSent();
    expect(drive.accountStatus, AccountStatus.awaitingEmailChange);
  });

  test('the secured legacy account is not asked to be secured again',
      () async {
    client.addAccount(kLegacyEmail, 'chosen-before', signedIn: true);
    final drive = openDrive();
    await pumpEventQueue();

    expect(drive.accountStatus, AccountStatus.awaitingEmailChange);
  });

  test('logout signs out', () async {
    client.addAccount('me@example.com', 'hunter22', signedIn: true);
    final drive = openDrive();
    await pumpEventQueue();

    await drive.logout();

    expect(drive.accountStatus, AccountStatus.signedOut);
    expect(drive.user, isNull);
    expect(client.currentUser, isNull);
  });
}
