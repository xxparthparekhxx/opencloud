import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opencloud/pages/project_control/widgets/file_type.dart';

void main() {
  group('FileTypeIcon.getIconByExtension', () {
    late FileTypeIcon icon;

    setUp(() {
      icon = const FileTypeIcon(extension: '');
    });

    test('maps video extensions to Icons.movie', () {
      expect(icon.getIconByExtension('mp4'), Icons.movie);
      expect(icon.getIconByExtension('mov'), Icons.movie);
      expect(icon.getIconByExtension('avi'), Icons.movie);
      expect(icon.getIconByExtension('mkv'), Icons.movie);
      expect(icon.getIconByExtension('webm'), Icons.movie);
    });

    test('maps audio extensions to Icons.music_note (case-insensitive)', () {
      expect(icon.getIconByExtension('mp3'), Icons.music_note);
      expect(icon.getIconByExtension('MP3'), Icons.music_note);
      expect(icon.getIconByExtension('wav'), Icons.music_note);
      expect(icon.getIconByExtension('flac'), Icons.music_note);
      expect(icon.getIconByExtension('M4A'), Icons.music_note);
    });

    test('maps image extensions to Icons.image', () {
      expect(icon.getIconByExtension('jpg'), Icons.image);
      expect(icon.getIconByExtension('jpeg'), Icons.image);
      expect(icon.getIconByExtension('png'), Icons.image);
      expect(icon.getIconByExtension('svg'), Icons.image);
      expect(icon.getIconByExtension('pdf'), Icons.image);
    });

    test('maps document extensions to Icons.description', () {
      expect(icon.getIconByExtension('doc'), Icons.description);
      expect(icon.getIconByExtension('docx'), Icons.description);
      expect(icon.getIconByExtension('txt'), Icons.description);
    });

    test('maps presentation extensions to Icons.slideshow', () {
      expect(icon.getIconByExtension('ppt'), Icons.slideshow);
      expect(icon.getIconByExtension('pptx'), Icons.slideshow);
    });

    test('maps spreadsheet extensions to Icons.table_chart', () {
      expect(icon.getIconByExtension('xls'), Icons.table_chart);
      expect(icon.getIconByExtension('xlsx'), Icons.table_chart);
      expect(icon.getIconByExtension('csv'), Icons.table_chart);
    });

    test('maps code extensions to Icons.code', () {
      // Note: the source mapping does not list "dart", so it falls through to
      // the default icon; "ts"/"js"/"java" are mapped to Icons.code.
      expect(icon.getIconByExtension('ts'), Icons.code);
      expect(icon.getIconByExtension('js'), Icons.code);
      expect(icon.getIconByExtension('java'), Icons.code);
      expect(icon.getIconByExtension('dart'), Icons.insert_drive_file);
    });

    test('maps archive extensions to Icons.archive', () {
      expect(icon.getIconByExtension('zip'), Icons.archive);
      expect(icon.getIconByExtension('rar'), Icons.archive);
      expect(icon.getIconByExtension('7z'), Icons.archive);
    });

    test('maps unknown extensions to Icons.insert_drive_file', () {
      expect(icon.getIconByExtension('xyz'), Icons.insert_drive_file);
      expect(icon.getIconByExtension(''), Icons.insert_drive_file);
    });
  });

  testWidgets('renders an Icon matching the extension mapping', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FileTypeIcon(extension: 'mp4'))),
    );

    expect(find.byIcon(Icons.movie), findsOneWidget);
  });
}
