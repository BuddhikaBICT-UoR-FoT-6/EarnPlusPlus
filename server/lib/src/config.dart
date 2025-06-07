// Configuration class for server settings including database and JWT credentials
class ServerConfig {
  final String host;
  final int port;

  // Database connection parameters
  final String dbHost;
  final int dbPort;
  final String dbUser;
  final String dbPassword;
  final String dbName;

  // JWT authentication secret
  final String jwtSecret;

  // Optional SMTP settings used for OTP and login notification emails.
  final String smtpHost;
  final int smtpPort;
  final String smtpUser;
  final String smtpPassword;
  final String smtpFrom;

  // Dev seeding settings for local environments.
  final bool devSeedEnabled;
  final String devSeedEmail;
  final String devSeedPassword;
  final String devSeedOtpEmail;
  final String devSeedOtpCode;

  // Constructor requiring all configuration parameters
  ServerConfig({
    required this.host,
    required this.port,
    required this.dbHost,
    required this.dbPort,
    required this.dbUser,
    required this.dbPassword,
    required this.dbName,
    required this.jwtSecret,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUser,
    required this.smtpPassword,
    required this.smtpFrom,
    required this.devSeedEnabled,
    required this.devSeedEmail,
    required this.devSeedPassword,
    required this.devSeedOtpEmail,
    required this.devSeedOtpCode,
  });

  // Factory constructor that loads configuration from environment variables with fallback defaults
  factory ServerConfig.fromEnv(Map<String, String> env) {
    // Helper function to safely parse integer values from environment variables
    int parseInt(String key, int fallback) =>
        int.tryParse(env[key] ?? '') ?? fallback;

    bool parseBool(String key, bool fallback) {
      final raw = (env[key] ?? '').trim().toLowerCase();
      if (raw.isEmpty) return fallback;
      return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
    }

    return ServerConfig(
      host: env['HOST'] ?? '0.0.0.0',
      port: parseInt('PORT', 8080),
      dbHost: env['DB_HOST'] ?? '127.0.0.1',
      dbPort: parseInt('DB_PORT', 3306),
      dbUser: env['DB_USER'] ?? 'root',
      dbPassword: env['DB_PASSWORD'] ?? '1234',
      dbName: env['DB_NAME'] ?? 'investments_db',
      jwtSecret:
          env['JWT_SECRET'] ?? 'CHANGE_THIS_SECRET_TO_SOMETHING_LONG_RANDOM',
      smtpHost: env['SMTP_HOST'] ?? '',
      smtpPort: parseInt('SMTP_PORT', 587),
      smtpUser: env['SMTP_USER'] ?? '',
      smtpPassword: env['SMTP_PASSWORD'] ?? '',
      smtpFrom: env['SMTP_FROM'] ?? (env['SMTP_USER'] ?? ''),
      devSeedEnabled: parseBool('DEV_SEED_ENABLED', true),
      devSeedEmail: env['DEV_SEED_EMAIL'] ?? 'dev@earn.local',
      devSeedPassword: env['DEV_SEED_PASSWORD'] ?? 'DevOnly@123',
      devSeedOtpEmail: env['DEV_SEED_OTP_EMAIL'] ?? 'pending.dev@earn.local',
      devSeedOtpCode: env['DEV_SEED_OTP_CODE'] ?? '999999',
    );
  }

  // Factory constructor that creates configuration using only default values
  factory ServerConfig.fromEnvDefaults() =>
      ServerConfig.fromEnv(const <String, String>{});
}
