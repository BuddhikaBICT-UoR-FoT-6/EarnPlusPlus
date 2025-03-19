import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mysql1/mysql1.dart';
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

String _signRefreshToken({
  required ServerConfig config,
  required int userId,
  required String email,
  required String role,
  required int tokenVersion,
}) {
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

Router authRoutes(MySqlConnection conn, ServerConfig config) {
  final router = Router();

  router.post('/auth/register', (Request req) async {
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

      final userCountRows = await conn.query('SELECT COUNT(*) AS total FROM users');
      final totalUsers = (userCountRows.first['total'] as num).toInt();
      final role = totalUsers == 0 ? 'superadmin' : 'user';

      final hash = BCrypt.hashpw(password, BCrypt.gensalt());

      await conn.query(
        'INSERT INTO users (email, role, password_hash) VALUES (?, ?, ?)',
        [email, role, hash],
      );

      return _json(201, {
        'message': 'User registered successfully',
        'role': role,
      });
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

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

      return _json(200, {
        'token': token,
        'refresh_token': refreshToken,
        'role': role,
      });
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

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
