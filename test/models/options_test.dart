import 'package:flutter_test/flutter_test.dart';

import 'package:opencloud/models/options.dart';

void main() {
  const validJson = '''{
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

  test('fbOpsFromJson parses a valid google-services-style config', () {
    final options = fbOpsFromJson(validJson);

    expect(options.apiKey, 'test-api-key');
    expect(options.appId, '1:12345:android:abcdef');
    expect(options.projectId, 'test-project-id');
    expect(options.storageBucket, 'test-project-id.appspot.com');
    // project_info.messaging_sender_id takes precedence over client messaging.
    expect(options.messagingSenderId, '12345');
  });

  test('fbOpsFromJson falls back to client messaging sender id', () {
    const json = '''{
      "client": [
        {
          "api_key": [{"current_key": "key"}],
          "client_info": {"mobilesdk_app_id": "app"},
          "messaging": {"messaging_sender_id": "client-sender"}
        }
      ],
      "project_info": {
        "project_id": "proj",
        "storage_bucket": "proj.appspot.com"
      }
    }''';
    final options = fbOpsFromJson(json);

    expect(options.messagingSenderId, 'client-sender');
  });

  test('fbOpsFromJson uses the default sender id when none is present', () {
    const json = '''{
      "client": [
        {
          "api_key": [{"current_key": "key"}],
          "client_info": {"mobilesdk_app_id": "app"}
        }
      ],
      "project_info": {
        "project_id": "proj",
        "storage_bucket": "proj.appspot.com"
      }
    }''';
    final options = fbOpsFromJson(json);

    expect(options.messagingSenderId, '0');
  });

  test('fbOpsFromJson throws FormatException for invalid JSON', () {
    expect(
      () => fbOpsFromJson('{ not valid json'),
      throwsA(isA<FormatException>()),
    );
  });

  test('fbOpsFromJson throws FormatException when client array is missing', () {
    expect(
      () => fbOpsFromJson(
          '{"project_info": {"project_id": "p", "storage_bucket": "b"}}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('fbOpsFromJson throws FormatException when client array is empty', () {
    expect(
      () => fbOpsFromJson(
          '{"client": [], "project_info": {"project_id": "p", "storage_bucket": "b"}}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('fbOpsFromJson throws FormatException when api_key is missing', () {
    const json = '''{
      "client": [{"client_info": {"mobilesdk_app_id": "app"}}],
      "project_info": {"project_id": "p", "storage_bucket": "b"}
    }''';
    expect(
      () => fbOpsFromJson(json),
      throwsA(isA<FormatException>()),
    );
  });

  test('fbOpsFromJson throws FormatException when project_info is missing', () {
    const json = '''{
      "client": [{"api_key": [{"current_key": "key"}], "client_info": {"mobilesdk_app_id": "app"}}]
    }''';
    expect(
      () => fbOpsFromJson(json),
      throwsA(isA<FormatException>()),
    );
  });
}
