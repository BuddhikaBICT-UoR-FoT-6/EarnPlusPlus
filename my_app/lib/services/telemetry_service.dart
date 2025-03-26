import 'dart:developer' as developer; // importing the developer library to use
// the log function for logging events and errors in the TelemetryService class.
// This allows us to log custom events and errors with specific names and data,
// which can be useful for analytics and debugging purposes.

import 'package:flutter/foundation.dart'; // importing the Flutter foundation package
// to use FlutterError and PlatformDispatcher to handle platform-level errors
// and exceptions that occur in the application.

// The TelemetryService class is a singleton that provides methods for initializing
// telemetry, logging events, and logging errors. It sets up error handling for
// both Flutter errors and platform errors, allowing us to capture and log any
// uncaught exceptions that occur in the app. The logEvent method is used to log
// custom events with a name and optional data, while the logError method is used
// to log errors with a name, error object, and stack trace. This service can be
// used throughout the app to track user interactions and capture errors for analytics
// and debugging purposes.
class TelemetryService {
  TelemetryService._(); // private constructor to prevent external instantiation,
  // ensuring that the TelemetryService can only be accessed through the singleton
  // instance provided by the static 'instance' property.

  static final TelemetryService instance =
      TelemetryService._(); // the singleton
  // instance of TelemetryService, which is created using the private constructor.
  // This allows us to access the TelemetryService from anywhere in the app without
  // needing to create multiple instances, ensuring that all telemetry logging is
  // centralized and consistent across the application.

  // the initialize method sets up error handling for both Flutter errors and platform
  // errors. It assigns a custom error handler to FlutterError.onError to log any
  // uncaught Flutter errors, and it assigns a custom error handler to
  // PlatformDispatcher.instance.onError to log any uncaught platform errors.
  // This ensures that any unexpected exceptions that occur in the app are captured
  // and logged for analysis and debugging.
  void initialize() {
    // register global handlers once during app startup so framework-level and
    // platform-level uncaught errors are consistently routed through telemetry.
    FlutterError.onError = (details) {
      // the onError handler for FlutterError captures any uncaught exceptions
      // that occur within the Flutter framework, such as widget build errors or
      // other exceptions that are not caught by the app's code. It logs the error
      // using the logError method, providing the name 'flutter_error', the exception
      // object, and the stack trace. After logging the error, it calls
      // FlutterError.presentError to display the error in the console and potentially
      // show an error message to the user, depending on the severity of the error
      // and the app's error handling policies.
      logError('flutter_error', details.exception, details.stack);
      FlutterError.presentError(details);
    };

    // the onError handler for PlatformDispatcher captures any uncaught exceptions
    // that occur at the platform level, such as native code errors or other exceptions
    // that are not caught by Flutter's error handling. It logs the error using
    // the logError method. The handler returns false to indicate that the error
    // has not been handled, allowing the platform to perform its default error
    // handling behavior, such as showing a crash dialog or terminating the app,
    // depending on the severity of the error and the platform's error handling policies.
    PlatformDispatcher.instance.onError = (error, stack) {
      logError('platform_error', error, stack);
      return false;
    };
  }

  // the logEvent method is used to log custom events with a name and optional data.
  // It uses the developer.log function to log the event, providing the event name,
  // a custom log name 'telemetry.event', and the data as the error parameter if
  // it is not empty. This allows us to track user interactions and other significant
  // events in the app for analytics purposes, helping us understand user behavior
  // and improve the app based on usage patterns.
  void logEvent(String name, {Map<String, Object?> data = const {}}) {
    // we intentionally keep event payload optional so low-friction event logging
    // can be used across simple and complex interaction points.
    developer.log(
      name,
      name: 'telemetry.event',
      error: data.isEmpty ? null : data,
    );
  }

  // the logError method is used to log errors with a name, error object, and stack trace.
  // It uses the developer.log function to log the error, providing the error name,
  // a custom log name 'telemetry.error', the error object, and the stack trace. This allows
  // us to capture and log any errors that occur in the app for analysis and debugging purposes,
  // helping us identify and fix issues in the app based on the logged error information.
  void logError(String name, Object error, StackTrace? stack) {
    // centralizes error logs under a dedicated namespace for easier filtering
    // in debug output or external log aggregation.
    developer.log(
      name,
      name: 'telemetry.error',
      error: error,
      stackTrace: stack,
    );
  }
}
