import 'package:flutter/material.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/telemetry_service.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  TelemetryService.instance.initialize();
  TelemetryService.instance.logEvent('app_start');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isLoggedIn() async {
    // Check for valid access token to determine auth state on startup
    await Future.delayed(
      const Duration(milliseconds: 1800),
    ); // Let splash animate
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
          // Show animated splash screen while checking authentication
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }
          // Route to appropriate screen based on auth state
          return (snapshot.data ?? false)
              ? const DashboardPage()
              : const LoginPage();
        },
      ),
    );
  }
}
