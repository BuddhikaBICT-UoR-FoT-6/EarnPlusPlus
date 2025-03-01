// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart';

void main() {
  // the testWidgets function defines a widget test that verifies the initial
  // loading state of the app when it boots up. It pumps the MyApp widget and
  // checks that a CircularProgressIndicator is displayed, indicating that the
  // app is in the process of checking the user's authentication status and
  // loading the appropriate screen.
  testWidgets('App boots and shows auth loading state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
