import 'package:bcrypt/bcrypt.dart';
import 'package:mysql1/mysql1.dart';

import '../config.dart';

String _esc(String value) {
  return value.replaceAll(r'\\', r'\\\\').replaceAll("'", "''");
}

Future<void> seedDevData(MySqlConnection conn, ServerConfig config) async {
  if (!config.devSeedEnabled) {
    return;
  }

  await conn.query('USE ${config.dbName}');

  // Upsert secret dev user with known credentials.
  final devEmail = config.devSeedEmail;
  final passwordHash = BCrypt.hashpw(config.devSeedPassword, BCrypt.gensalt());
  final escapedDevEmail = _esc(devEmail);
  final escapedPasswordHash = _esc(passwordHash);
  print('[DEV-SEED] Creating dev user: $devEmail');
  await conn.query(
    "INSERT INTO users (email, role, password_hash) VALUES ('$escapedDevEmail', 'user', '$escapedPasswordHash') "
    "ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), role = VALUES(role), password_hash = VALUES(password_hash)",
  );

  // Seed deterministic dummy investments for the secret dev user.
  await conn.query(
    "DELETE FROM investments WHERE user_id IN (SELECT id FROM users WHERE email = '$escapedDevEmail')",
  );
  await conn.query(
    "INSERT INTO investments (user_id, date, asset, amount) SELECT id, '2025-01-05', 'BTC', 1200.0 FROM users WHERE email = '$escapedDevEmail'",
  );
  await conn.query(
    "INSERT INTO investments (user_id, date, asset, amount) SELECT id, '2025-01-22', 'ETH', 800.0 FROM users WHERE email = '$escapedDevEmail'",
  );
  await conn.query(
    "INSERT INTO investments (user_id, date, asset, amount) SELECT id, '2025-02-10', 'AAPL', 1500.0 FROM users WHERE email = '$escapedDevEmail'",
  );
  await conn.query(
    "INSERT INTO investments (user_id, date, asset, amount) SELECT id, '2025-02-27', 'TSLA', 600.0 FROM users WHERE email = '$escapedDevEmail'",
  );
  await conn.query(
    "INSERT INTO investments (user_id, date, asset, amount) SELECT id, '2025-03-08', 'GOOGL', 950.0 FROM users WHERE email = '$escapedDevEmail'",
  );

  // Additional dummy users and investments for richer demo data.
  final demoUsers = [
    {
      'email': 'alice@earn.local',
      'password': 'Alice@123',
      'investments': [
        {'date': '2025-01-11', 'asset': 'MSFT', 'amount': 700.0},
        {'date': '2025-02-02', 'asset': 'NVDA', 'amount': 980.0},
      ],
    },
    {
      'email': 'bob@earn.local',
      'password': 'Bob@123',
      'investments': [
        {'date': '2025-01-19', 'asset': 'AMZN', 'amount': 640.0},
        {'date': '2025-03-01', 'asset': 'NFLX', 'amount': 520.0},
      ],
    },
  ];

  print('[DEV-SEED] Starting demo users seeding...');
  for (final demo in demoUsers) {
    final emailRaw = demo['email'] as String;
    final password = demo['password'] as String;
    final pHash = BCrypt.hashpw(password, BCrypt.gensalt());
    final escapedEmailRaw = _esc(emailRaw);
    final escapedPHash = _esc(pHash);
    print('[DEV-SEED] Processing demo user: $emailRaw');

    await conn.query(
      "INSERT INTO users (email, role, password_hash) VALUES ('$escapedEmailRaw', 'user', '$escapedPHash') "
      "ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), role = VALUES(role), password_hash = VALUES(password_hash)",
    );
    await conn.query(
      "DELETE FROM investments WHERE user_id IN (SELECT id FROM users WHERE email = '$escapedEmailRaw')",
    );
    final investments = demo['investments'] as List<dynamic>;
    for (final inv in investments) {
      final invMap = inv as Map<String, dynamic>;
      final date = invMap['date'] as String;
      final asset = invMap['asset'] as String;
      final amount = invMap['amount'] as double;
      final escapedDate = _esc(date);
      final escapedAsset = _esc(asset);
      await conn.query(
        "INSERT INTO investments (user_id, date, asset, amount) SELECT id, '$escapedDate', '$escapedAsset', $amount FROM users WHERE email = '$escapedEmailRaw'",
      );
    }
    print('[DEV-SEED] Seeded ${investments.length} investments for $emailRaw');
  }

  // Seed OTP table with a controlled pending registration row.
  final otpPasswordHash = BCrypt.hashpw('OtpSeed@123', BCrypt.gensalt());
  final escapedOtpPasswordHash = _esc(otpPasswordHash);
  final escapedOtpEmail = _esc(config.devSeedOtpEmail);
  final escapedOtpCode = _esc(config.devSeedOtpCode);
  final otpExpiry = DateTime.now().add(const Duration(days: 365));
  final otpExpirySql = otpExpiry
      .toUtc()
      .toIso8601String()
      .replaceFirst('T', ' ')
      .split('.')
      .first;
  await conn.query(
    "DELETE FROM registration_otps WHERE email = '$escapedOtpEmail'",
  );
  await conn.query(
    "INSERT INTO registration_otps (email, password_hash, otp_code, expires_at) VALUES ('$escapedOtpEmail', '$escapedOtpPasswordHash', '$escapedOtpCode', '$otpExpirySql')",
  );

  print('[DEV-SEED] Seeded secret login user and dummy data.');
  print('[DEV-SEED] Email: ${config.devSeedEmail}');
  print('[DEV-SEED] Password: ${config.devSeedPassword}');
  print(
      '[DEV-SEED] Demo users: alice@earn.local / Alice@123, bob@earn.local / Bob@123');
  print('[DEV-SEED] OTP email: ${config.devSeedOtpEmail}');
  print('[DEV-SEED] OTP code: ${config.devSeedOtpCode}');
}
