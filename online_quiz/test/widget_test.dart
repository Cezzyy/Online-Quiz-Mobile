// This is a basic Flutter widget test for the ACLC Online Quiz app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:online_quiz/main.dart';

void main() {
  testWidgets('ACLC Quiz App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ACLCQuizApp(),
      ),
    );

    // Wait for any animations to complete
    await tester.pumpAndSettle();

    // Verify that the app loads and shows onboarding content
    // This is a simple test to ensure the app doesn't crash on startup
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // The app should have some text content (from onboarding screen)
    expect(find.byType(Text), findsAtLeastNWidgets(1));
  });
}
