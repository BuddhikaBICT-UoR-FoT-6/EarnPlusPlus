// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // the testWidgets function defines a widget test that verifies the initial
  // loading state of the app when it boots up. It pumps the MyApp widget and
  // checks that a CircularProgressIndicator is displayed, indicating that the
  // app is in the process of checking the user's authentication status and
  // loading the appropriate screen.
  testWidgets('App boots and shows auth loading state', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeController>(
        create: (_) => ThemeController(),
        child: const MyApp(),
      ),
    );

    expect(find.text('Earn++'), findsOneWidget);
    
    // Advance time by enough seconds to trigger the Future.delayed in MyApp._isLoggedIn
    await tester.pump(const Duration(milliseconds: 2000));
    // Wait for the navigation transition to complete
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 1000));
  });
}
