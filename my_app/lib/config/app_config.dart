// This file defines the AppConfig class, which provides configuration values for
// the application. It uses Dart's compile-time environment variables to determine
// the app's environment (e.g., development, staging, production) and the API base URL.
// The AppConfig class has a static getter for the base URL, which checks if an API
// base URL is provided through environment variables and returns it if available.
class AppConfig {
  // appEnv captures the high-level environment profile used by the app
  // to switch behavior between development, staging, and production.
  static const String appEnv = String.fromEnvironment(
    // the 'APP_ENV' environment variable is used to specify the current environment
    // the app is running in, such as 'dev', 'staging', or 'prod'. This allows the
    // app to adjust its behavior based on the environment, such as using different
    // API endpoints or enabling/disabling certain features. The default value is
    // set to 'dev' for development purposes.
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String _apiBaseUrl = String.fromEnvironment(
    // the 'API_BASE_URL' environment variable allows for overriding the default API
    // base URL. This is useful for testing or when deploying the app to different
    // environments. If not specified, it defaults to an empty string, indicating that
    // the app should use a default URL based on the environment.
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    // if the _apiBaseUrl is not empty, then it means that the API base URL has been
    // overridden through environment variables, so we return that value directly.
    if (_apiBaseUrl.isNotEmpty) {
      return _apiBaseUrl;
    }

    // otherwise, we determine the base URL based on the app environment. If the
    // app is running in production ('prod'), we return the production API URL.
    if (appEnv == 'prod') {
      return 'https://api.earnplusplus.com';
    }

    // if the app is running in staging ('staging'), we return the staging API URL.
    if (appEnv == 'staging') {
      return 'https://staging-api.earnplusplus.com';
    }

    // for development and any other environments, we return the local API URL,
    // which is typically used for local development and testing. Note that when
    // running on an Android emulator, 'localhost' refers to the emulator itself,
    // so we use 'http://10.0.2.2:8080' to access the host machine's localhost
    // where the API server is running.
    return 'http://10.0.2.2:8080';
  }
}
