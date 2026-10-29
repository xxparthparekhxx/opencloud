import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:opencloud/pages/auth/login.dart';
import 'package:opencloud/pages/auth/secure_account.dart';
import 'package:opencloud/providers/openprovider.dart';
import 'package:opencloud/services/auth_service.dart';

import '../support/fake_auth_client.dart';

void main() {
  late FakeAuthClient client;
  late OpenDrive drive;

  setUp(() {
    client = FakeAuthClient();
  });

  Future<void> pumpGate(WidgetTester tester) async {
    drive = OpenDrive.forTesting(
      authService: AuthService(options: kTestOptions, client: client),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<OpenDrive>.value(
        value: drive,
        child: const MaterialApp(home: AuthDesider()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String key, String text) =>
      tester.enterText(find.byKey(Key(key)), text);

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  group('sign-in screen', () {
    testWidgets('is shown when signed out', (tester) async {
      await pumpGate(tester);

      expect(find.byType(SignInPage), findsOneWidget);
    });

    testWidgets('shows an error on a wrong password', (tester) async {
      client.addAccount('me@example.com', 'hunter22');
      await pumpGate(tester);

      await fill(tester, 'signIn.email', 'me@example.com');
      await fill(tester, 'signIn.password', 'wrong-pass');
      await tap(tester, 'signIn.submit');

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(find.byType(SignInPage), findsOneWidget);
      expect(drive.accountStatus, AccountStatus.signedOut);
    });

    testWidgets('signs in with the email and password entered',
        (tester) async {
      client.addAccount('me@example.com', 'hunter22');
      await pumpGate(tester);

      await fill(tester, 'signIn.email', ' me@example.com ');
      await fill(tester, 'signIn.password', 'hunter22');
      await tap(tester, 'signIn.submit');

      expect(client.calls, ['signIn me@example.com']);
      expect(drive.accountStatus, AccountStatus.ready);
      expect(drive.user!.email, 'me@example.com');
    });

    testWidgets('creates an account with the email and password chosen',
        (tester) async {
      await pumpGate(tester);

      await tap(tester, 'signIn.toggleMode');
      await fill(tester, 'signIn.email', 'new@example.com');
      await fill(tester, 'signIn.password', 'hunter22');
      await fill(tester, 'signIn.confirmPassword', 'hunter22');
      await tap(tester, 'signIn.submit');

      expect(client.calls, ['createUser new@example.com']);
      expect(client.passwordOf('new@example.com'), 'hunter22');
      expect(drive.accountStatus, AccountStatus.ready);
    });

    testWidgets('does not create an account when the passwords differ',
        (tester) async {
      await pumpGate(tester);

      await tap(tester, 'signIn.toggleMode');
      await fill(tester, 'signIn.email', 'new@example.com');
      await fill(tester, 'signIn.password', 'hunter22');
      await fill(tester, 'signIn.confirmPassword', 'hunter23');
      await tap(tester, 'signIn.submit');

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(client.calls, isEmpty);
    });
  });

  group('secure-your-account step', () {
    testWidgets(
        'replaces a restored legacy session\'s credentials and explains the '
        'verification link', (tester) async {
      client.addAccount(kLegacyEmail, kLegacyPassword, signedIn: true);
      await pumpGate(tester);
      expect(find.byType(SecureAccountPage), findsOneWidget);

      client.calls.clear();
      await fill(tester, 'secure.email', 'me@example.com');
      await fill(tester, 'secure.password', 'new-secret');
      await fill(tester, 'secure.confirmPassword', 'new-secret');
      await tap(tester, 'secure.submit');

      expect(client.calls, [
        'signIn $kLegacyEmail',
        'updatePassword new-secret',
        'verifyBeforeUpdateEmail me@example.com',
      ]);
      expect(find.byType(EmailChangeSentPage), findsOneWidget);
      expect(
        find.textContaining('changes to this address when you click the link'),
        findsOneWidget,
      );
      expect(find.textContaining('me@example.com'), findsOneWidget);
    });

    testWidgets('can be started from the sign-in screen', (tester) async {
      client.addAccount(kLegacyEmail, kLegacyPassword);
      await pumpGate(tester);

      await tap(tester, 'signIn.secureExisting');
      expect(find.byType(SecureAccountPage), findsOneWidget);

      await fill(tester, 'secure.email', 'me@example.com');
      await fill(tester, 'secure.password', 'new-secret');
      await fill(tester, 'secure.confirmPassword', 'new-secret');
      await tap(tester, 'secure.submit');

      expect(client.passwordOf(kLegacyEmail), 'new-secret');
      expect(client.pendingEmailOf(kLegacyEmail), 'me@example.com');
      expect(find.byType(SecureAccountPage), findsNothing);
      expect(find.byType(EmailChangeSentPage), findsOneWidget);
    });

    testWidgets('explains when the earlier account cannot be signed into',
        (tester) async {
      client.addAccount(kLegacyEmail, 'chosen-before');
      await pumpGate(tester);

      await tap(tester, 'signIn.secureExisting');
      await fill(tester, 'secure.email', 'me@example.com');
      await fill(tester, 'secure.password', 'not-it-at-all');
      await fill(tester, 'secure.confirmPassword', 'not-it-at-all');
      await tap(tester, 'secure.submit');

      expect(
        find.textContaining('enter the password you chose then'),
        findsOneWidget,
      );
      expect(find.byType(SecureAccountPage), findsOneWidget);
    });
  });
}
