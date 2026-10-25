import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'UploadMeta field assertions (skipped: UploadTask construction)',
    () {
      // UploadMeta wraps a firebase_storage.UploadTask, whose constructor is
      // private and which requires a live Firebase Storage instance (plugin
      // channels / network). It cannot be constructed in a headless test
      // environment, so field assertions are skipped here.
      expect(true, isTrue,
          skip:
              'UploadTask cannot be constructed without Firebase plugin channels/network');
    },
  );
}
