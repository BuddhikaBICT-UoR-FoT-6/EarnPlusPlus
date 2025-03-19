import 'dart:convert';

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

Map<String, dynamic>? _claims(Request req, String jwtSecret) {
  final auth = req.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) {
    return null;
  }

  final token = auth.substring('Bearer '.length).trim();
  if (token.isEmpty) {
    return null;
  }

  try {
    final verified = JWT.verify(token, SecretKey(jwtSecret));
    final payload = verified.payload;
    if (payload is Map<String, dynamic>) {
      final tokenType = (payload['typ'] ?? 'access').toString();
      if (tokenType != 'access') {
        return null;
      }
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

String _roleFromClaims(Map<String, dynamic> claims) {
  final role = (claims['role'] ?? 'user').toString();
  if (role == 'admin' || role == 'superadmin') {
    return role;
  }
  return 'user';
}

bool _isAdminOrSuperadmin(String role) => role == 'admin' || role == 'superadmin';

Router userRoutes(MySqlConnection conn, ServerConfig config) {
  final router = Router();

  router.get('/users/me', (Request req) async {
    final claims = _claims(req, config.jwtSecret);
    if (claims == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final userId = _userIdFromClaims(claims);
    if (userId == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    await conn.query('USE ${config.dbName}');
    final rows = await conn.query(
      'SELECT id, email, role, created_at FROM users WHERE id = ? LIMIT 1',
      [userId],
    );

    if (rows.isEmpty) {
      return _json(404, {'message': 'User not found'});
    }

    final row = rows.first;
    return _json(200, {
      'id': row['id'] as int,
      'email': row['email'] as String,
      'role': (row['role'] ?? 'user').toString(),
      'created_at': (row['created_at'] as DateTime).toIso8601String(),
    });
  });

  router.get('/admin/users', (Request req) async {
    final claims = _claims(req, config.jwtSecret);
    if (claims == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final role = _roleFromClaims(claims);
    if (!_isAdminOrSuperadmin(role)) {
      return _json(403, {'message': 'Forbidden'});
    }

    await conn.query('USE ${config.dbName}');
    final rows = await conn.query(
      'SELECT id, email, role, created_at FROM users ORDER BY created_at DESC',
    );

    final users = rows
        .map(
          (row) => {
            'id': row['id'] as int,
            'email': row['email'] as String,
            'role': (row['role'] ?? 'user').toString(),
            'created_at': (row['created_at'] as DateTime).toIso8601String(),
          },
        )
        .toList();

    return _json(200, users);
  });

  router.get('/admin/dashboard', (Request req) async {
    final claims = _claims(req, config.jwtSecret);
    if (claims == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final role = _roleFromClaims(claims);
    if (!_isAdminOrSuperadmin(role)) {
      return _json(403, {'message': 'Forbidden'});
    }

    await conn.query('USE ${config.dbName}');
    final userCountRows = await conn.query('SELECT COUNT(*) AS total FROM users');
    final investmentCountRows = await conn.query('SELECT COUNT(*) AS total FROM investments');
    final totalAmountRows = await conn.query('SELECT COALESCE(SUM(amount), 0) AS total FROM investments');

    return _json(200, {
      'users': (userCountRows.first['total'] as num).toInt(),
      'investments': (investmentCountRows.first['total'] as num).toInt(),
      'total_amount': (totalAmountRows.first['total'] as num).toDouble(),
    });
  });

  router.get('/superadmin/dashboard', (Request req) async {
    final claims = _claims(req, config.jwtSecret);
    if (claims == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final role = _roleFromClaims(claims);
    if (role != 'superadmin') {
      return _json(403, {'message': 'Forbidden'});
    }

    await conn.query('USE ${config.dbName}');
    final usersByRoleRows = await conn.query(
      'SELECT role, COUNT(*) AS total FROM users GROUP BY role',
    );

    final roles = <String, int>{
      'user': 0,
      'admin': 0,
      'superadmin': 0,
    };

    for (final row in usersByRoleRows) {
      roles[(row['role'] ?? 'user').toString()] = (row['total'] as num).toInt();
    }

    final userCountRows = await conn.query('SELECT COUNT(*) AS total FROM users');
    final investmentCountRows = await conn.query('SELECT COUNT(*) AS total FROM investments');

    return _json(200, {
      'users': (userCountRows.first['total'] as num).toInt(),
      'investments': (investmentCountRows.first['total'] as num).toInt(),
      'roles': roles,
    });
  });

  router.patch('/superadmin/users/<id>/role', (Request req, String id) async {
    final claims = _claims(req, config.jwtSecret);
    if (claims == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final callerRole = _roleFromClaims(claims);
    if (callerRole != 'superadmin') {
      return _json(403, {'message': 'Forbidden'});
    }

    final userId = int.tryParse(id);
    if (userId == null) {
      return _json(400, {'message': 'Invalid user id'});
    }

    final body = await req.readAsString();
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return _json(400, {'message': 'Body must be a JSON object'});
    }

    final role = (decoded['role'] ?? '').toString().trim();
    if (role != 'user' && role != 'admin' && role != 'superadmin') {
      return _json(400, {'message': 'Invalid role'});
    }

    await conn.query('USE ${config.dbName}');
    final result = await conn.query(
      'UPDATE users SET role = ? WHERE id = ?',
      [role, userId],
    );

    if (result.affectedRows == 0) {
      return _json(404, {'message': 'User not found'});
    }

    return _json(200, {'message': 'Role updated', 'role': role});
  });

  return router;
}
