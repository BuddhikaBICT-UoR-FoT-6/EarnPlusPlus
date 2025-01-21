import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';

/// Helper function to create a JSON response with the specified status code and body
Response _json(int statusCode, Object body) => Response(
      statusCode,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

/// Fetches all investments from the database and returns them as a list of maps
/// with date, asset, and amount fields
Future<List<Map<String, dynamic>>> _fetchInvestments(
  MySqlConnection conn,
  String dbName,
  int userId,
) async {
  // Select the database to query
  await conn.query('USE $dbName');

  // Query all investments ordered by date and id
  final results = await conn.query(
    'SELECT date, asset, amount FROM investments WHERE user_id = ? ORDER BY date ASC, id ASC',
    [userId],
  );

  // Transform database rows into a list of maps with formatted data
  return results
      .map((row) => {
            // Convert DateTime to ISO8601 string and extract only the date part
            'date':
                (row['date'] as DateTime).toIso8601String().split('T').first,
            'asset': row['asset'] as String,
            // Ensure amount is stored as a double
            'amount': (row['amount'] as num).toDouble(),
          })
      .toList();
}

int? _extractUserId(Request req, String jwtSecret) {
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
      final sub = payload['sub'];
      if (sub is int) {
        return sub;
      }
      if (sub is String) {
        return int.tryParse(sub);
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Creates and configures the investment routes router
Router investmentRoutes(MySqlConnection conn, ServerConfig config) {
  final router = Router();

  /// GET /investments - Retrieves all investments from the database
  router.get('/investments', (Request req) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final list = await _fetchInvestments(conn, config.dbName, userId);
    return _json(200, list);
  });

  return router;
}
