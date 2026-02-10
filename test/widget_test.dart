// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsnap_pdf_scanner/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to wrap it in a ProviderScope because the app uses Riverpod.
    await tester.pumpWidget(const ProviderScope(child: DocSnapApp()));

    // Verify that the app starts and shows the title or a button.
    // The home screen has a title 'DocSnap Scanner' and a FAB with 'Scan'.
    expect(find.text('DocSnap Scanner'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });
}
