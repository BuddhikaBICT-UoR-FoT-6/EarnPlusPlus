import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class TelemetryService {
  TelemetryService._();

  static final TelemetryService instance = TelemetryService._();

  void initialize() {
    FlutterError.onError = (details) {
      logError('flutter_error', details.exception, details.stack);
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      logError('platform_error', error, stack);
      return false;
    };
  }

  void logEvent(String name, {Map<String, Object?> data = const {}}) {
    developer.log(
      name,
      name: 'telemetry.event',
      error: data.isEmpty ? null : data,
    );
  }

  void logError(String name, Object error, StackTrace? stack) {
    developer.log(
      name,
      name: 'telemetry.error',
      error: error,
      stackTrace: stack,
    );
  }
}
