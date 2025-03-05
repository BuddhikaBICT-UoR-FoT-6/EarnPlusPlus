import 'package:flutter/foundation.dart'; // imports the foundation library,
// which provides basic classes and functions for Flutter applications, including
// ChangeNotifier for state management

import '../../../services/auth_service.dart';

// The LoginController class is a Change Notifier that manages the state of the
// login process, including the submission state and any error messages. It
// interacts with the AuthService to perform the login operation and notifies
// listeners of state changes, allowing the UI to react accordingly, such as
// showing a loading indicator while the login is in progress and displaying
// error messages if the login fails.
class LoginController extends ChangeNotifier {
  final AuthService _authService;

  LoginController({AuthService? authService})
    : _authService = authService ?? AuthService(); // the constructor allows for
  // dependency injection of the AuthService, which enables easier testing and
  // flexibility in swapping out the authentication service if needed. If no
  // AuthService is provided, it creates a default instance.

  bool isSubmitting = false;
  String? error;

  // the login method takes an email and password, sets the submitting state to
  // true, and attempts to log in using the AuthService. It handles any exceptions
  // that may occur during the login process, setting an error message if the
  // login fails, and ensures the submitting state is set back to false in the
  // finally block to always update the UI, regardless of success or failure.
  Future<bool> login({required String email, required String password}) async {
    isSubmitting = true;
    error = null;
    notifyListeners();

    try {
      await _authService.login(email: email, password: password);
      return true;
    } catch (e) {
      error = 'Login failed: $e';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
