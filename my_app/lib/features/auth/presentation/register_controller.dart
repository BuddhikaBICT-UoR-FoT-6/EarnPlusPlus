import 'package:flutter/foundation.dart'; // imports the foundation library,
// including ChangeNotifier used for state managementwhich provides basic classes
// and functions for Flutter applications, including ChangeNotifier for state
// management and other foundational utilities.

import '../../../services/auth_service.dart';

class RegisterController extends ChangeNotifier {
  final AuthService _authService;

  RegisterController({AuthService? authService})
    : _authService = authService ?? AuthService(); // the constructor allows for
  // dependency injection of the AuthService, which enables easier testing and
  // flexibility in swapping out the authentication service if needed. If no
  // AuthService is provided, it creates a default instance.

  bool isSubmitting = false;
  String? error;
  bool awaitingOtp = false;
  String? pendingEmail;

  Future<bool> register({
    // the register method takes an email and password, sets the submitting state
    // to true, and attempts to register using the AuthService. It handles any
    // exceptions that might occur during registration. If registration fails,
    // it sets an error message; otherwise, it returns true indicating success.
    // The finally block ensures that the submitting state is set back to false
    // and listeners are notified regardless of the outcome, allowing the UI to
    // update accordingly.
    required String email,
    required String password,
  }) async {
    isSubmitting = true;
    error = null;
    notifyListeners();

    try {
      await _authService.startRegisterOtp(email: email, password: password);
      awaitingOtp = true;
      pendingEmail = email;
      return true;
    } catch (e) {
      error = 'Register failed: $e';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp({required String otp}) async {
    if (pendingEmail == null || pendingEmail!.isEmpty) {
      error = 'Missing pending email. Restart registration.';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    error = null;
    notifyListeners();

    try {
      await _authService.verifyRegisterOtp(email: pendingEmail!, otp: otp);
      awaitingOtp = false;
      pendingEmail = null;
      return true;
    } catch (e) {
      error = 'OTP verification failed: $e';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
