import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../domain/notification_repository.dart';
import '../domain/notification_dtos.dart';

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

Router notificationRoutes(NotificationRepository repository, ServerConfig config) {
  final router = Router();

  router.get('/notifications', (Request req) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) return _json(401, {'message': 'Unauthorized'});

    final list = await repository.fetchNotifications(userId);
    final dtos = list.map((item) => NotificationDto(
          id: item['id'] as int,
          title: item['title'] as String,
          body: item['body'] as String,
          isRead: (item['is_read'] as int) == 1,
          createdAt: item['created_at'].toString(),
        ).toJson()).toList();
    return _json(200, dtos);
  });

  router.put('/notifications/<id>/read', (Request req, String id) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) return _json(401, {'message': 'Unauthorized'});

    final notificationId = int.tryParse(id);
    if (notificationId == null) return _json(400, {'message': 'Invalid id'});

    final affected = await repository.markAsRead(notificationId, userId);
    if (affected == 0) return _json(404, {'message': 'Notification not found'});

    return _json(200, {'message': 'Marked as read'});
  });

  return router;
}
