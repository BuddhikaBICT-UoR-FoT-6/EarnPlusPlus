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

bool _isAdminOrSuperadmin(String role) =>
    role == 'admin' || role == 'superadmin';

// The userRoutes function defines routes for user and admin account management,
// including endpoints for fetching the current user's profile, listing all users
// for administrative purposes, retrieving admin and superadmin dashboard metrics,
// and updating user roles. Each route enforces role-based access control to ensure
// that only authorized users can access sensitive administrative data and perform
// privileged operations like role changes.
Router userRoutes(MySqlConnection conn, ServerConfig config) {
  final router = Router();

  // the /users/me endpoint returns the currently authenticated user's profile
  // details, including their email, role, and created timestamp. This endpoint
  // allows the frontend to display the logged-in user's information and determine
  // which role-specific UI sections should be shown, ensuring that the dashboard
  // renders role-aware content without hardcoding user data locally.
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

  // the /admin/users endpoint retrieves the full list of user accounts from the
  // database, accessible only to users with admin or superadmin roles. This list
  // is used by the admin and superadmin dashboards to display user tables, allowing
  // administrators to view all registered users and their roles. The endpoint respects
  // role-based access control by returning a 403 Forbidden response if the caller
  // lacks sufficient permissions.
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

  // the /admin/dashboard endpoint aggregates key application metrics for the
  // admin dashboard, including the total number of users, total investments, and
  // the sum of all investment amounts across the system. These metrics are displayed
  // as summary cards in the admin interface, giving administrators visibility into
  // the overall health and scale of the application without needing to query raw
  // data. Access is restricted to users with admin or superadmin roles.
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
    final userCountRows =
        await conn.query('SELECT COUNT(*) AS total FROM users');
    final investmentCountRows =
        await conn.query('SELECT COUNT(*) AS total FROM investments');
    final totalAmountRows = await conn
        .query('SELECT COALESCE(SUM(amount), 0) AS total FROM investments');

    return _json(200, {
      'users': (userCountRows.first['total'] as num).toInt(),
      'investments': (investmentCountRows.first['total'] as num).toInt(),
      'total_amount': (totalAmountRows.first['total'] as num).toDouble(),
    });
  });

  // the /superadmin/dashboard endpoint provides system-level metrics exclusively
  // to superadmin users, including the count of users, investments, and a detailed
  // breakdown of users by role (user, admin, superadmin). This role distribution
  // helps superadmins monitor governance and ensure that administrative privileges
  // are appropriately distributed across the user base. Access is restricted to
  // superadmin role only, preventing lower-privilege admins from viewing this
  // sensitive governance data.
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

    final userCountRows =
        await conn.query('SELECT COUNT(*) AS total FROM users');
    final investmentCountRows =
        await conn.query('SELECT COUNT(*) AS total FROM investments');

    return _json(200, {
      'users': (userCountRows.first['total'] as num).toInt(),
      'investments': (investmentCountRows.first['total'] as num).toInt(),
      'roles': roles,
    });
  });

  // the /superadmin/users/<id>/role endpoint allows superadmin users to change
  // any user's role, supporting user promotion to admin or demotion back to regular
  // user status. This endpoint enforces strict access control—only superadmin roles
  // can call it—and validates the target role before applying the update, ensuring
  // that only valid role transitions (user, admin, superadmin) are persisted to
  // the database. Role changes are immediately effective, affecting the user's
  // access control on subsequent authentication or role checks.
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
