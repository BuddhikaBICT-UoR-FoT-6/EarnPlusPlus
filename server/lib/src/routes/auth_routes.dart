import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mysql1/mysql1.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';

Response _json(int statusCode, Object body) => Response(
      statusCode,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

Future<Map<String, dynamic>> _readJson(Request request) async {
  final body = await request.readAsString();
  final decoded = jsonDecode(body);

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Body must be a JSON object');
  }
  return decoded;
}

String _signAccessToken({
  required ServerConfig config,
  required int userId,
  required String email,
  required String role,
  required int tokenVersion,
}) {
  // access tokens are short-lived and used for normal API authorization.
  final jwt = JWT(
    {
      'sub': userId,
      'email': email,
      'role': role,
      'typ': 'access',
      'tv': tokenVersion,
    },
    issuer: 'EarnPlusPlus',
  );

  return jwt.sign(
    SecretKey(config.jwtSecret),
    expiresIn: Duration(hours: 1),
  );
}

// the _signRefreshToken helper function creates a long-lived JWT that is used
// only to mint new access tokens. Refresh tokens have a 14-day expiration and
// are stored securely on the client, allowing users to remain logged in for
// extended periods without re-entering credentials. The refresh token includes
// the token_version claim, enabling server-side session invalidation by incrementing
// the version when the user logs out from all sessions.
String _signRefreshToken({
  required ServerConfig config,
  required int userId,
  required String email,
  required String role,
  required int tokenVersion,
}) {
  // refresh tokens are longer-lived and only used to mint new access tokens.
  final jwt = JWT(
    {
      'sub': userId,
      'email': email,
      'role': role,
      'typ': 'refresh',
      'tv': tokenVersion,
    },
    issuer: 'EarnPlusPlus',
  );

  return jwt.sign(
    SecretKey(config.jwtSecret),
    expiresIn: Duration(days: 14),
  );
}

Map<String, dynamic>? _verifyBearerClaims(Request req, String secret) {
  final auth = req.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) {
    return null;
  }

  final token = auth.substring('Bearer '.length).trim();
  if (token.isEmpty) {
    return null;
  }

  try {
    final verified = JWT.verify(token, SecretKey(secret));
    final payload = verified.payload;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return null;
  } catch (_) {
    return null;
  }
}

int? _userIdFromClaims(Map<String, dynamic> claims) {
  final sub = claims['sub'];
  if (sub is int) return sub;
  if (sub is String) return int.tryParse(sub);
  return null;
}

String _generateOtp({int length = 6}) {
  final r = Random.secure();
  final min = pow(10, length - 1).toInt();
  final max = pow(10, length).toInt() - 1;
  return (min + r.nextInt(max - min)).toString();
}

Future<void> _sendEmail(
  ServerConfig config, {
  required String to,
  required String subject,
  required String text,
}) async {
  // If SMTP is not configured, fall back to console output for development.
  if (config.smtpHost.isEmpty ||
      config.smtpUser.isEmpty ||
      config.smtpPassword.isEmpty ||
      config.smtpFrom.isEmpty) {
    print('[EMAIL-DEV] to=$to subject=$subject body=$text');
    return;
  }

  final smtp = SmtpServer(
    config.smtpHost,
    port: config.smtpPort,
    username: config.smtpUser,
    password: config.smtpPassword,
    allowInsecure: false,
  );

  final message = Message()
    ..from = Address(config.smtpFrom, 'EarnPlusPlus')
    ..recipients.add(to)
    ..subject = subject
    ..text = text;

  await send(message, smtp);
}

// The authRoutes function defines authentication endpoints for user registration,
// login, token refresh, and logout operations. It implements a two-token system
// with short-lived access tokens for API requests and longer-lived refresh tokens
// for silent renewal. Role-based access control is enforced at the route level,
// and token_version tracking enables immediate invalidation of all sessions when
// a user logs out from all devices.
Router authRoutes(MySqlConnection conn, ServerConfig config) {
  final router = Router();

  // Step 1: request OTP for registration.
  router.post('/auth/register/send-otp', (Request req) async {
    try {
      final data = await _readJson(req);
      final email = (data['email'] ?? '').toString().trim().toLowerCase();
      final password = (data['password'] ?? '').toString();

      if (email.isEmpty || !email.contains('@')) {
        return _json(400, {'message': 'Invalid email'});
      }

      if (password.length < 6) {
        return _json(
            400, {'message': 'Password must be at least 6 characters'});
      }

      await conn.query('USE ${config.dbName}');

      final existing = await conn.query(
        'SELECT id FROM users WHERE email = ? LIMIT 1',
        [email],
      );

      if (existing.isNotEmpty) {
        return _json(400, {'message': 'Email already registered'});
      }

      final hash = BCrypt.hashpw(password, BCrypt.gensalt());
      final otp = _generateOtp();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await conn
          .query('DELETE FROM registration_otps WHERE email = ?', [email]);
      await conn.query(
        'INSERT INTO registration_otps (email, password_hash, otp_code, expires_at) VALUES (?, ?, ?, ?)',
        [email, hash, otp, expiresAt],
      );

      await _sendEmail(
        config,
        to: email,
        subject: 'Your EarnPlusPlus registration OTP',
        text:
            'Your OTP is: $otp. It expires in 10 minutes. If you did not request this, ignore this email.',
      );

      return _json(202, {
        'message': 'OTP sent to email. Please verify to complete registration.',
      });
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

  // Step 2: verify OTP and create the account.
  router.post('/auth/register/verify', (Request req) async {
    try {
      final data = await _readJson(req);
      final email = (data['email'] ?? '').toString().trim().toLowerCase();
      final otp = (data['otp'] ?? '').toString().trim();

      if (email.isEmpty || !email.contains('@')) {
        return _json(400, {'message': 'Invalid email'});
      }
      if (otp.length < 4) {
        return _json(400, {'message': 'Invalid OTP'});
      }

      await conn.query('USE ${config.dbName}');

      final otpRows = await conn.query(
        'SELECT password_hash, otp_code, expires_at FROM registration_otps WHERE email = ? LIMIT 1',
        [email],
      );
      if (otpRows.isEmpty) {
        return _json(
            400, {'message': 'OTP not found. Please request a new one.'});
      }

      final row = otpRows.first;
      final storedOtp = (row['otp_code'] ?? '').toString();
      final expiresAt = row['expires_at'] as DateTime;
      if (DateTime.now().isAfter(expiresAt)) {
        await conn
            .query('DELETE FROM registration_otps WHERE email = ?', [email]);
        return _json(
            400, {'message': 'OTP expired. Please request a new one.'});
      }
      if (storedOtp != otp) {
        return _json(400, {'message': 'Incorrect OTP'});
      }

      final existing = await conn.query(
        'SELECT id FROM users WHERE email = ? LIMIT 1',
        [email],
      );
      if (existing.isNotEmpty) {
        await conn
            .query('DELETE FROM registration_otps WHERE email = ?', [email]);
        return _json(400, {'message': 'Email already registered'});
      }

      final userCountRows =
          await conn.query('SELECT COUNT(*) AS total FROM users');
      final totalUsers = (userCountRows.first['total'] as num).toInt();
      final role = totalUsers == 0 ? 'superadmin' : 'user';

      final hash = (row['password_hash'] ?? '').toString();
      await conn.query(
        'INSERT INTO users (email, role, password_hash) VALUES (?, ?, ?)',
        [email, role, hash],
      );
      await conn
          .query('DELETE FROM registration_otps WHERE email = ?', [email]);

      return _json(201, {
        'message': 'User registered successfully',
        'role': role,
      });
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

  // Backward compatibility alias: old register route now triggers OTP send.
  router.post('/auth/register', (Request req) async {
    return await router.call(Request(
      req.method,
      req.requestedUri.replace(path: '/auth/register/send-otp'),
      headers: req.headers,
      body: await req.readAsString(),
      context: req.context,
    ));
  });

  // the POST /auth/login endpoint verifies the user's email and password credentials
  // against the stored bcrypt hash. On successful authentication, it returns both
  // an access token (1-hour expiration for API calls) and a refresh token (14-day
  // expiration for silent renewal). The response also includes the user's role so
  // the client can immediately render role-appropriate UI without an extra profile fetch.
  router.post('/auth/login', (Request req) async {
    try {
      final data = await _readJson(req);
      final email = (data['email'] ?? '').toString().trim().toLowerCase();
      final password = (data['password'] ?? '').toString();

      await conn.query('USE ${config.dbName}');

      final rows = await conn.query(
        'SELECT id, role, token_version, password_hash FROM users WHERE email = ? LIMIT 1',
        [email],
      );

      if (rows.isEmpty) {
        return _json(401, {'message': 'Invalid email or password'});
      }

      final userId = rows.first['id'] as int;
      final role = (rows.first['role'] ?? 'user').toString();
      final tokenVersion = (rows.first['token_version'] as num?)?.toInt() ?? 0;
      final passwordHash = rows.first['password_hash'] as String;

      if (!BCrypt.checkpw(password, passwordHash)) {
        return _json(401, {'message': 'Invalid email or password'});
      }

      final token = _signAccessToken(
        config: config,
        userId: userId,
        email: email,
        role: role,
        tokenVersion: tokenVersion,
      );
      final refreshToken = _signRefreshToken(
        config: config,
        userId: userId,
        email: email,
        role: role,
        tokenVersion: tokenVersion,
      );

      // Non-blocking login alert email.
      try {
        await _sendEmail(
          config,
          to: email,
          subject: 'New login to your EarnPlusPlus account',
          text:
              'A new login was detected for your account at ${DateTime.now().toIso8601String()}. If this was not you, reset your password immediately.',
        );
      } catch (_) {
        // Do not block login if email delivery fails.
      }

      return _json(200, {
        'token': token,
        'refresh_token': refreshToken,
        'role': role,
      });
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

  // the POST /auth/refresh endpoint accepts a refresh token and returns a new
  // access token without requiring the user to log in again. This enables silent
  // token renewal for a seamless user experience. The endpoint validates that the
  // refresh token is properly signed, has the correct token type, and that the
  // token_version matches the current server version (enabling logout-all revocation).
  // If the token_version is out of sync, the token is treated as revoked.
  router.post('/auth/refresh', (Request req) async {
    try {
      final data = await _readJson(req);
      final refreshToken = (data['refresh_token'] ?? '').toString().trim();
      if (refreshToken.isEmpty) {
        return _json(400, {'message': 'refresh_token is required'});
      }

      final verified = JWT.verify(refreshToken, SecretKey(config.jwtSecret));
      final payload = verified.payload;
      if (payload is! Map<String, dynamic>) {
        return _json(401, {'message': 'Invalid token'});
      }

      if ((payload['typ'] ?? '').toString() != 'refresh') {
        return _json(401, {'message': 'Invalid token type'});
      }

      final userId = _userIdFromClaims(payload);
      if (userId == null) {
        return _json(401, {'message': 'Invalid token'});
      }

      await conn.query('USE ${config.dbName}');
      final rows = await conn.query(
        'SELECT email, role, token_version FROM users WHERE id = ? LIMIT 1',
        [userId],
      );
      if (rows.isEmpty) {
        return _json(401, {'message': 'Invalid token'});
      }

      final row = rows.first;
      final dbVersion = (row['token_version'] as num?)?.toInt() ?? 0;
      final tokenVersion = (payload['tv'] as num?)?.toInt() ?? -1;
      if (tokenVersion != dbVersion) {
        return _json(401, {'message': 'Token revoked'});
      }

      final email = row['email'] as String;
      final role = (row['role'] ?? 'user').toString();
      final accessToken = _signAccessToken(
        config: config,
        userId: userId,
        email: email,
        role: role,
        tokenVersion: dbVersion,
      );

      return _json(200, {'token': accessToken, 'role': role});
    } catch (e) {
      return _json(401, {'message': 'Invalid token'});
    }
  });

  // the POST /auth/logout-all endpoint invalidates all of the user's active
  // sessions across all devices. It works by incrementing the token_version in
  // the database, causing all existing refresh and access tokens to become invalid
  // on next use. This is useful when a user suspects their credentials are
  // compromised or wants to force re-authentication across all their sessions.
  // The endpoint requires a valid access token and immediately logs out the
  // current session as well.
  router.post('/auth/logout-all', (Request req) async {
    final claims = _verifyBearerClaims(req, config.jwtSecret);
    if (claims == null || (claims['typ'] ?? 'access').toString() != 'access') {
      return _json(401, {'message': 'Unauthorized'});
    }

    final userId = _userIdFromClaims(claims);
    if (userId == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    await conn.query('USE ${config.dbName}');
    await conn.query(
      'UPDATE users SET token_version = token_version + 1 WHERE id = ?',
      [userId],
    );

    return _json(200, {'message': 'Logged out from all sessions'});
  });

  return router;
}
