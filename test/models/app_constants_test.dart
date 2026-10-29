import 'package:flutter_test/flutter_test.dart';

import 'package:opencloud/models/app_constants.dart';

void main() {
  group('shared constants', () {
    test('kBaseConfigPrefKey', () {
      expect(kBaseConfigPrefKey, 'BaseConfig');
    });

    test('kProjectsCollection', () {
      expect(kProjectsCollection, 'projects');
    });

    test('kFolderPlaceholderFileName', () {
      expect(kFolderPlaceholderFileName, 'NEWFILEPLACEHOLDER.txt');
    });

    test('kDefaultMessagingSenderId', () {
      expect(kDefaultMessagingSenderId, '0');
    });
  });
}
