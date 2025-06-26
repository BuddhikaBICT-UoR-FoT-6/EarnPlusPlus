import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../domain/goal_repository.dart';
import '../domain/goal_dtos.dart';

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

Router goalRoutes(GoalRepository repository, ServerConfig config) {
  final router = Router();

  router.get('/goals', (Request req) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) return _json(401, {'message': 'Unauthorized'});

    final list = await repository.fetchGoals(userId);
    final dtos = list.map((item) => GoalDto(
          id: item['id'] as int,
          title: item['title'] as String,
          targetAmount: (item['target_amount'] as num).toDouble(),
          currentAmount: (item['current_amount'] as num).toDouble(),
          createdAt: item['created_at'].toString(),
        ).toJson()).toList();
    return _json(200, dtos);
  });

  router.post('/goals', (Request req) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) return _json(401, {'message': 'Unauthorized'});

    try {
      final payload = await _readJson(req);
      final title = (payload['title'] ?? '').toString().trim();
      if (title.isEmpty) throw const FormatException('title is required');

      final targetAmount = (payload['targetAmount'] as num?)?.toDouble();
      if (targetAmount == null || targetAmount <= 0) {
        throw const FormatException('targetAmount must be a positive number');
      }

      final currentAmount = (payload['currentAmount'] as num?)?.toDouble() ?? 0.0;

      await repository.createGoal(userId, title, targetAmount, currentAmount);

      final list = await repository.fetchGoals(userId);
      final lastItem = list.first; // ordered by created_at DESC, so the newest is first
      final dto = GoalDto(
        id: lastItem['id'] as int,
        title: lastItem['title'] as String,
        targetAmount: (lastItem['target_amount'] as num).toDouble(),
        currentAmount: (lastItem['current_amount'] as num).toDouble(),
        createdAt: lastItem['created_at'].toString(),
      );
      return _json(201, dto.toJson());
    } on FormatException catch (e) {
      return _json(400, {'message': e.message});
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

  router.put('/goals/<id>', (Request req, String id) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) return _json(401, {'message': 'Unauthorized'});

    final goalId = int.tryParse(id);
    if (goalId == null) return _json(400, {'message': 'Invalid goal id'});

    try {
      final payload = await _readJson(req);
      final title = (payload['title'] ?? '').toString().trim();
      if (title.isEmpty) throw const FormatException('title is required');

      final targetAmount = (payload['targetAmount'] as num?)?.toDouble();
      if (targetAmount == null || targetAmount <= 0) {
        throw const FormatException('targetAmount must be a positive number');
      }

      final currentAmount = (payload['currentAmount'] as num?)?.toDouble() ?? 0.0;

      final affectedRows = await repository.updateGoal(goalId, userId, title, targetAmount, currentAmount);
      if (affectedRows == 0) return _json(404, {'message': 'Goal not found'});

      final row = await repository.getGoalById(goalId, userId);
      if (row == null) return _json(404, {'message': 'Goal not found'});

      final dto = GoalDto(
        id: row['id'] as int,
        title: row['title'] as String,
        targetAmount: (row['target_amount'] as num).toDouble(),
        currentAmount: (row['current_amount'] as num).toDouble(),
        createdAt: row['created_at'].toString(),
      );
      return _json(200, dto.toJson());
    } on FormatException catch (e) {
      return _json(400, {'message': e.message});
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

  router.delete('/goals/<id>', (Request req, String id) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) return _json(401, {'message': 'Unauthorized'});

    final goalId = int.tryParse(id);
    if (goalId == null) return _json(400, {'message': 'Invalid goal id'});

    final affectedRows = await repository.deleteGoal(goalId, userId);
    if (affectedRows == 0) return _json(404, {'message': 'Goal not found'});

    return _json(200, {'message': 'Goal deleted'});
  });

  return router;
}
