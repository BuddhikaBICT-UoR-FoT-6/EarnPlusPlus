import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/login_page.dart';

void main() {
  testWidgets('LoginPage has email and password fields and a login button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Verify that the email and password text fields are present.
    expect(find.byType(TextField), findsNWidgets(2));
    
    // Verify that the Login button is present.
    expect(find.text('Login'), findsWidgets);
    
    // Verify that the Register text is present.
    expect(find.text("No account yet? "), findsOneWidget);
  });
}
