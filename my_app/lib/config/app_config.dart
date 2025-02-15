// This file defines the AppConfig class, which contains a static
// constant for the base URL of the API. The base URL is read from
// an environment variable called API_BASE_URL, with a default value
// of 'http://10.0.2.2:8080' for Android emulators, which allows the
// app to connect to the backend server running on the host machine.
// This setup enables flexibility in configuring the API endpoint for
// different environments (e.g., development, staging, production)
// without changing the codebase, by simply setting the environment
// variable when running the app.
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
}
