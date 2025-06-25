import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/telemetry_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/onboarding_page.dart';
import 'package:local_auth/local_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Phase 17: Global Error Handling Boundary
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    TelemetryService.instance.logEvent('flutter_error', data: {
      'error': details.exceptionAsString(),
      'stack': details.stack.toString(),
    });
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    TelemetryService.instance.logEvent('platform_error', data: {
      'error': error.toString(),
      'stack': stack.toString(),
    });
    return true;
  };

  TelemetryService.instance.initialize();
  TelemetryService.instance.logEvent('app_start');
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const MyApp(),
    ),
  );
}

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isLoggedIn() async {
    // Check for valid access token to determine auth state on startup
    await Future.delayed(
      const Duration(milliseconds: 1800),
    ); // Let splash animate
    final token = await AuthService().getValidToken();
    if (token == null || token.isEmpty) return false;

    try {
      final localAuth = LocalAuthentication();
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      
      if (canCheckBiometrics && isDeviceSupported) {
        final authenticated = await localAuth.authenticate(
          localizedReason: 'Please authenticate to access your portfolio',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
        if (!authenticated) {
          // If they cancel or fail, they can't log in automatically.
          return false;
        }
      }
    } catch (_) {
      // Fallback to normal login if biometrics fail entirely
    }

    return true;
  }

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_seen_onboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeController.themeMode,
      home: FutureBuilder<List<bool>>(
        future: Future.wait([_isLoggedIn(), _hasSeenOnboarding()]),
        builder: (context, snapshot) {
          // Show animated splash screen while checking authentication
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }
          final isLoggedIn = snapshot.data?[0] ?? false;
          final hasSeenOnboarding = snapshot.data?[1] ?? false;

          // Route to appropriate screen based on auth state
          if (isLoggedIn) return const DashboardPage();
          if (!hasSeenOnboarding) return const OnboardingPage();
          return const LoginPage();
        },
      ),
    );
  }
}
