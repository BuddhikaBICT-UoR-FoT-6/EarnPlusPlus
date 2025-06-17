import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../domain/notification_dto.dart';
import '../domain/notification_repository.dart';

class NotificationException implements Exception {
  final String message;
  const NotificationException(this.message);
  @override
  String toString() => message;
}

class NotificationUnauthorizedException extends NotificationException {
  const NotificationUnauthorizedException() : super('Unauthorized access.');
}

class ApiNotificationRepository implements NotificationRepository {
  final AuthService _authService;

  ApiNotificationRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  @override
  Future<List<NotificationDto>> fetchNotifications() async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const NotificationUnauthorizedException();
    }

    try {
      final resp = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/notifications'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 401) {
        await _authService.logout();
        throw const NotificationUnauthorizedException();
      }

      if (resp.statusCode == 200) {
        final List<dynamic> body = jsonDecode(resp.body);
        return body.map((e) => NotificationDto.fromJson(e)).toList();
      } else {
        throw const NotificationException('Failed to load notifications');
      }
    } on SocketException {
      throw const NotificationException('No Internet connection');
    } on TimeoutException {
      throw const NotificationException('Connection timed out');
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const NotificationUnauthorizedException();
    }

    try {
      final resp = await http
          .put(
            Uri.parse('${AppConfig.baseUrl}/notifications/$id/read'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 401) {
        await _authService.logout();
        throw const NotificationUnauthorizedException();
      }

      if (resp.statusCode != 200) {
        throw const NotificationException('Failed to mark as read');
      }
    } on SocketException {
      throw const NotificationException('No Internet connection');
    } on TimeoutException {
      throw const NotificationException('Connection timed out');
    }
  }
}
