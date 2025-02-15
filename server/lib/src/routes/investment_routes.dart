import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart'; // for verifying JWT tokens in the request headers
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart'; // for handling HTTP requests and responses
import 'package:shelf_router/shelf_router.dart'; // for defining routes and handling route parameters

import '../config.dart';

/// Helper function to create a JSON response with the specified status code and body
Response _json(int statusCode, Object body) => Response(
      // the _json function takes a status code and a body object, encodes the body
      // as a JSON string, and returns a Response object with the appropriate headers
      // for JSON content and the specified status code
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

// the _extractUserId function extracts the user ID from the Authorization header
// of the incoming request, verifies the JWT token using the provided secret,
// and returns the user ID if the token is valid, or null if the token is missing,
// invalid, or does not contain a valid user ID in the "sub" claim
int? _extractUserId(Request req, String jwtSecret) {
  final auth = req.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) {
    return null;
  }

  final token = auth.substring('Bearer '.length).trim(); // trims the "Bearer "
  // and trims any leading/trailing whitespace to remove the "Bearer "
  // prefix from the Authorization header to get the raw token string
  if (token.isEmpty) {
    return null;
  }

  try {
    final verified = JWT.verify(token, SecretKey(jwtSecret));
    final payload =
        verified.payload; // the payload variable contains the decoded
    // JWT payload, which is expected to be a map with a "sub" field representing
    // the user ID. The function checks if the "sub" field is an integer
    // or a string that can be parsed as an integer, and returns the user ID as
    // an integer if valid, or null if the "sub" field is missing or invalid.
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
  final router =
      Router(); // the investmentRoutes function takes a MySqlConnection
  // and returns a Router object that handles investment-related routes
  // the Router object is used to define routes for the investment API endpoints
  // and a ServerConfig as parameters,

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
