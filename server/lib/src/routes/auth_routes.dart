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
        'SELECT id, role, password_hash FROM users WHERE email = ? LIMIT 1',
        [email],
      );

      if (rows.isEmpty) {
        return _json(401, {'message': 'Invalid email or password'});
      }

      final userId = rows.first['id'] as int;
  final role = (rows.first['role'] ?? 'user').toString();
      final passwordHash = rows.first['password_hash'] as String;

      if (!BCrypt.checkpw(password, passwordHash)) {
        return _json(401, {'message': 'Invalid email or password'});
      }

      final jwt = JWT(
        {'sub': userId, 'email': email, 'role': role},
        issuer: 'EarnPlusPlus',
      );

      final token = jwt.sign(
        SecretKey(config.jwtSecret),
        expiresIn: Duration(hours: 1),
      );

      return _json(200, {'token': token, 'role': role});
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

  return router;
}
