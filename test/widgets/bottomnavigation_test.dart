import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opencloud/pages/project_control/widgets/bottomnavigation.dart';

void main() {
  testWidgets('BottomNav renders navigation items and reports taps', (
    WidgetTester tester,
  ) async {
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNav(
            currentIndex: 0,
            onTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // The current file defines 3 items: Files, uploads, Settings.
    expect(find.byIcon(Icons.folder_copy), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Tapping an item invokes onTap with the item's index.
    await tester.tap(find.byIcon(Icons.cloud_upload));
    expect(tappedIndex, 1);

    await tester.tap(find.byIcon(Icons.settings));
    expect(tappedIndex, 2);
  });
}
