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

int? _extractUserId(Request req, String jwtSecret) {
  final auth = req.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  final token = auth.substring('Bearer '.length).trim();
  if (token.isEmpty) return null;

  try {
    final verified = JWT.verify(token, SecretKey(jwtSecret));
    final payload = verified.payload;
    if (payload is Map<String, dynamic>) {
      final tokenType = (payload['typ'] ?? 'access').toString();
      if (tokenType != 'access') return null;
      final sub = payload['sub'];
      if (sub is int) return sub;
      if (sub is String) return int.tryParse(sub);
    }
    return null;
  } catch (_) {
    return null;
  }
}

String _obfuscateEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) return email;
  final name = parts[0];
  if (name.length <= 2) return '${name.substring(0, 1)}***@${parts[1]}';
  return '${name.substring(0, 2)}***@${parts[1]}';
}

Router leaderboardRoutes(MySqlConnection conn, ServerConfig config) {
  final router = Router();

  router.get('/leaderboard', (Request req) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) return _json(401, {'message': 'Unauthorized'});

    // Fetch top 10 users by total invested amount
    final results = await conn.query('''
      SELECT u.id, u.email, SUM(i.amount) as total_invested
      FROM `${config.dbName}`.users u
      JOIN `${config.dbName}`.investments i ON u.id = i.user_id
      GROUP BY u.id, u.email
      ORDER BY total_invested DESC
      LIMIT 10
    ''');

    final leaderboard = results.map((row) {
      return {
        'id': row['id'],
        'displayName': _obfuscateEmail(row['email'] as String),
        'score': (row['total_invested'] as num).toDouble(),
      };
    }).toList();

    return _json(200, leaderboard);
  });

  return router;
}
