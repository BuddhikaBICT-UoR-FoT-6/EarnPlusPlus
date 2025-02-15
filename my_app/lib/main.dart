import 'package:flutter/material.dart'; // importing the Flutter material package
// such as Scaffold, AppBar, and Buttons to use Material Design components and
// widgets for building the user interface of the application
import 'dart:convert'; // for encoding and decoding JSON data when communicating
//  with APIs or parsing data from web services with the backend server
import 'core/constants/app_strings.dart'; // importing application-wide string
//constants for consistent text usage across the app, such as the app name and
//  other static strings that may be used in the UI
import 'core/theme/app_theme.dart'; // importing the AppTheme class that defines
// the visual styling for the application, including colors, typography, and input
// decoration themes to maintain a consistent look and feel throughout the app
import 'services/auth_service.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart'; // importing the main screens of the application,
//  specifically LoginPage for authentication and DashboardPage for the main application
// content, to be displayed based on the user's authentication status

void main() => runApp(const MyApp()); // the main function is the entry point of
//  the application, telling the Flutter engine to run the MyApp widget as the root
//  widget of the app's widget tree the Flutter application, which calls runApp
// with an instance of MyApp to start the app and display the user interface defined
// in My App.

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  }); // the MyApp class is a StatelessWidget that represents
  //the top-level widget for the entire Flutter application. the root of the application.
  // It defines the overall structure and theme of the app, and it determines which screen to show
  // based on the user's authentication status. The MyApp widget builds a MaterialApp
  // with a title, theme, and a home that uses a FutureBuilder to check if the user is
  // logged in and display either the DashboardPage or the LoginPage accordingly.

  Future<bool> _isLoggedIn() async {
    final token = await AuthService().getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light(),
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return (snapshot.data ?? false)
              ? const DashboardPage()
              : const LoginPage();
        },
      ),
    );
  }
}
