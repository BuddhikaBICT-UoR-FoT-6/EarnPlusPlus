import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../config.dart';
import '../services/smart_insight_service.dart';

Response _json(int statusCode, Object body) => Response(
      statusCode,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

int? _extractUserId(Request req, String jwtSecret) {
  final auth = req.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  final token = auth.substring(7).trim();
  if (token.isEmpty) return null;
  try {
    final verified = JWT.verify(token, SecretKey(jwtSecret));
    final payload = verified.payload;
    if (payload is Map<String, dynamic>) {
      if ((payload['typ'] ?? 'access').toString() != 'access') return null;
      final sub = payload['sub'];
      if (sub is int) return sub;
      if (sub is String) return int.tryParse(sub);
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<Map<String, dynamic>> _readJson(Request request) async {
  final body = await request.readAsString();
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Body must be a JSON object');
  }
  return decoded;
}

Router insightRoutes(MySqlConnection conn, ServerConfig config, SmartInsightService insightService) {
  final router = Router();

  router.post('/insights/ask', (Request req) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    try {
      final payload = await _readJson(req);
      final query = payload['query']?.toString() ?? '';
      if (query.isEmpty) {
         return _json(400, {'message': 'Query cannot be empty'});
      }
      
      // Use the SmartInsightService to generate insights
      // We need the user's portfolio data. We'll fetch it from DB using the connection
      await conn.query('USE ${config.dbName}');
      final results = await conn.query('SELECT id, date, asset, amount FROM investments WHERE user_id = ?', [userId]);
      final portfolio = results.map((row) => {
        'id': row['id'],
        'date': row['date'].toString(),
        'asset': row['asset'].toString(),
        'amount': (row['amount'] as num).toDouble(),
      }).toList();

      final generatedInsights = insightService.analyzePortfolio(portfolio);

      return _json(200, {
        'insights': generatedInsights
      });
    } on FormatException catch (e) {
      return _json(400, {'message': e.message});
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

  return router;
}
