import 'package:flutter/foundation.dart'; // imports the foundation library,
// including ChangeNotifier used for state managementwhich provides basic classes
// and functions for Flutter applications, including ChangeNotifier for state
// management and other foundational utilities.

import '../../../services/auth_service.dart';
import '../../../services/registration_queue.dart';

class RegisterController extends ChangeNotifier {
  final AuthService _authService;
  final RegistrationQueueService _queueService;

  RegisterController({
    AuthService? authService,
    RegistrationQueueService? queueService,
  }) : _authService = authService ?? AuthService(),
       _queueService =
           queueService ??
           RegistrationQueueService('http://10.0.2.2:8080'); // the
  // constructor allows for dependency injection of the AuthService and
  // RegistrationQueueService, which enables easier testing and flexibility
  // in swapping out the services if needed.

  bool isSubmitting = false;
  String? error;
  bool awaitingOtp = false;
  String? pendingEmail;
  bool isOffline = false; // Track if registration was queued offline

  /// Initialize the queue service (call this when the controller is created or the register screen is shown).
  Future<void> initQueueService() async {
    await _queueService.init();
  }

  /// Dispose of resources when done.
  Future<void> disposeQueue() async {
    await _queueService.dispose();
  }

  @override
  void dispose() {
    disposeQueue();
    super.dispose();
  }

  Future<bool> register({
    // the register method takes an email and password, sets the submitting state
    // to true, and attempts to register using the AuthService. If the server is
    // unreachable or a network error occurs, it enqueues the registration locally
    // for later retry. If registration fails for other reasons, it sets an error
    // message; otherwise, it returns true indicating success.
    required String email,
    required String password,
  }) async {
    isSubmitting = true;
    error = null;
    isOffline = false;
    notifyListeners();

    try {
      await _authService.startRegisterOtp(email: email, password: password);
      awaitingOtp = true;
      pendingEmail = email;
      return true;
    } catch (e) {
      // Check if error is network-related (SocketException, timeout, etc.)
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socket') ||
          errorStr.contains('connection') ||
          errorStr.contains('timeout') ||
          errorStr.contains('timedout') ||
          errorStr.contains('network')) {
        // Network error — enqueue for later retry
        await _queueService.enqueue(email, password);
        isOffline = true;
        error =
            'Offline: Registration queued. Will sync when network is available.';
        notifyListeners();
        return true; // Treat as success (queued)
      } else {
        error = 'Register failed: $e';
        return false;
      }
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
