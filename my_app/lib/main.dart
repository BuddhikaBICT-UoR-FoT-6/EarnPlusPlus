import 'package:flutter/material.dart'; // importing the Flutter material package
// such as Scaffold, AppBar, and Buttons to use Material Design components and
// widgets for building the user interface of the application
import 'core/constants/app_strings.dart'; // importing application-wide string
//constants for consistent text usage across the app, such as the app name and
//  other static strings that may be used in the UI
import 'core/theme/app_theme.dart'; // importing the AppTheme class that defines
// the visual styling for the application, including colors, typography, and input
// decoration themes to maintain a consistent look and feel throughout the app
import 'services/auth_service.dart';
import 'services/telemetry_service.dart'; // importing services for authentication
// and telemetry to manage user authentication and to log events and track user
// interactions for analytics and debugging purposes
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart'; // importing the main screens of the application,
//  specifically LoginPage for authentication and DashboardPage for the main application
// content, to be displayed based on the user's authentication status

void main() {
  // the main function is the entry point of the application, where we initialize
  // the Flutter engine, set up telemetry for logging events, and run the MyApp widget
  // ensuring that the Flutter engine is initialized before running the app is crucial
  // because it allows us to perform any necessary setup, such as initializing services
  // or loading resources, before the app's UI is built and displayed to the user.

  WidgetsFlutterBinding.ensureInitialized(); // ensures that the Flutter engine is
  // initialized before running the app this is important for performing any necessary
  // setup or initialization before the app's UI is built and displayed to the user,
  // such as initializing services, loading resources, or checking for permissions
  TelemetryService.instance.initialize(); // initializes the telemetry service,
  // which is responsible for logging events and tracking user interactions for
  //analytics and debugging purposes
  TelemetryService.instance.logEvent(
    'app_start',
  ); // logs an event indicating that
  // the app has started, which can be useful for analytics and understanding user
  // behavior
  runApp(const MyApp());
} // the main function is the entry point of
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
    // this helper checks whether a valid access token is available before
    // deciding which initial screen to render when the app starts.
    final token = await AuthService().getValidToken();
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
          // while authentication state is still being resolved, show a minimal
          // loading scaffold so users do not see a blank or flickering screen.
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // once auth check completes, route users directly to the dashboard
          // if logged in, otherwise send them to the login screen.
          return (snapshot.data ?? false)
              ? const DashboardPage()
              : const LoginPage();
        },
      ),
    );
  }
}
