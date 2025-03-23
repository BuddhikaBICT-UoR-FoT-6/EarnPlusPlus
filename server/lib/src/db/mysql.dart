import 'dart:io';
import 'package:mysql1/mysql1.dart';
import '../config.dart';

// Helper function to merge environment variables with default config values
ServerConfig _configWithEnv(ServerConfig config) {
  // Get all environment variables from the system
  final env = Platform.environment;
  // Create a new ServerConfig by merging env vars (with fallback to config defaults)
  return ServerConfig.fromEnv({
    // Spread existing environment variables
    ...env,
    // Use env HOST or fallback to config.host
    'HOST': env['HOST'] ?? config.host,
    'PORT': env['PORT'] ?? config.port.toString(),
    'DB_HOST': env['DB_HOST'] ?? config.dbHost,
    'DB_PORT': env['DB_PORT'] ?? config.dbPort.toString(),
    'DB_USER': env['DB_USER'] ?? config.dbUser,
    'DB_PASSWORD': env['DB_PASSWORD'] ?? config.dbPassword,
    'DB_NAME': env['DB_NAME'] ?? config.dbName,
    'JWT_SECRET': env['JWT_SECRET'] ?? config.jwtSecret,
  });
}

/// Opens a MySQL database connection using the provided base configuration.
///
/// This function merges the base configuration with environment variables,
/// then establishes a connection to the MySQL database server.
///
/// Parameters:
///   - baseConfig: The base server configuration with default values
///
Future<MySqlConnection> openMySqlConnection(ServerConfig baseConfig) async {
  // Merge environment variables with the base configuration to get final config
  final config = _configWithEnv(baseConfig);

  // A Future that resolves to an active MySqlConnection
  return MySqlConnection.connect(
    ConnectionSettings(
      host: config.dbHost,
      port: config.dbPort,
      user: config.dbUser,
      password: config.dbPassword,
    ),
  );
}
