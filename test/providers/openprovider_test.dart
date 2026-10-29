import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:opencloud/models/app_constants.dart';
import 'package:opencloud/providers/openprovider.dart';

const String _validConfig = '''{
  "client": [
    {
      "api_key": [{"current_key": "test-api-key"}],
      "client_info": {"mobilesdk_app_id": "1:12345:android:abcdef"},
      "messaging": {"messaging_sender_id": "99999"}
    }
  ],
  "project_info": {
    "project_id": "test-project-id",
    "storage_bucket": "test-project-id.appspot.com",
    "messaging_sender_id": "12345"
  }
}''';

const String _malformedConfig = '{ not valid json';

void main() {
  group('OpenDrive.createProjectFromJson', () {
    late OpenDrive openDrive;

    setUp(() {
      openDrive = OpenDrive();
    });

    test('validates the project config before creating the first project', () async {
      await expectLater(
        openDrive.createProjectFromJson(data: _malformedConfig, isInitial: true),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws Firebase not initialized instead of crashing on a null repository',
        () async {
      await expectLater(
        openDrive.createProjectFromJson(data: _validConfig),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Firebase not initialized'),
          ),
        ),
      );
    });

    test('persists BaseConfig to SharedPreferences when creating the first project',
        () async {
      SharedPreferences.setMockInitialValues({});
      await openDrive.init();
      expect(
        (await SharedPreferences.getInstance()).getString(kBaseConfigPrefKey),
        isNull,
      );

      Object? firebaseError;
      try {
        await openDrive.createProjectFromJson(
          data: _validConfig,
          isInitial: true,
        );
      } catch (e) {
        firebaseError = e;
      }
      expect(
        firebaseError,
        isNotNull,
        reason:
            'Firebase plugins cannot initialize without platform channels in a headless test',
      );

      // The base config is persisted before the base app is initialized, so a
      // restart remembers the project even though Firebase cannot start here.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kBaseConfigPrefKey), _validConfig);
    });
  });
}
