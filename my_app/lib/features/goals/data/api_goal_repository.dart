import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../domain/goal_dto.dart';
import '../domain/goal_repository.dart';

class GoalException implements Exception {
  final String message;
  const GoalException(this.message);
  @override
  String toString() => message;
}

class GoalUnauthorizedException extends GoalException {
  const GoalUnauthorizedException() : super('Unauthorized access. Please log in again.');
}

class ApiGoalRepository implements GoalRepository {
  final AuthService _authService;

  ApiGoalRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  @override
  Future<List<GoalDto>> fetchGoals() async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const GoalUnauthorizedException();
    }

    try {
      final resp = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/goals'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 401) {
        await _authService.logout();
        throw const GoalUnauthorizedException();
      }

      if (resp.statusCode == 200) {
        final List<dynamic> body = jsonDecode(resp.body);
        return body.map((e) => GoalDto.fromJson(e)).toList();
      } else {
        final msg = jsonDecode(resp.body)['message'] ?? 'Failed to load goals';
        throw GoalException(msg);
      }
    } on SocketException {
      throw const GoalException('No Internet connection');
    } on TimeoutException {
      throw const GoalException('Connection timed out');
    }
  }

  @override
  Future<GoalDto> createGoal({
    required String title,
    required double targetAmount,
    required double currentAmount,
  }) async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const GoalUnauthorizedException();
    }

    try {
      final resp = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/goals'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'title': title,
              'targetAmount': targetAmount,
              'currentAmount': currentAmount,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 401) {
        await _authService.logout();
        throw const GoalUnauthorizedException();
      }

      if (resp.statusCode == 201) {
        return GoalDto.fromJson(jsonDecode(resp.body));
      } else {
        final msg = jsonDecode(resp.body)['message'] ?? 'Failed to create goal';
        throw GoalException(msg);
      }
    } on SocketException {
      throw const GoalException('No Internet connection');
    } on TimeoutException {
      throw const GoalException('Connection timed out');
    }
  }

  @override
  Future<GoalDto> updateGoal({
    required int id,
    required String title,
    required double targetAmount,
    required double currentAmount,
  }) async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const GoalUnauthorizedException();
    }

    try {
      final resp = await http
          .put(
            Uri.parse('${AppConfig.baseUrl}/goals/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'title': title,
              'targetAmount': targetAmount,
              'currentAmount': currentAmount,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 401) {
        await _authService.logout();
        throw const GoalUnauthorizedException();
      }

      if (resp.statusCode == 200) {
        return GoalDto.fromJson(jsonDecode(resp.body));
      } else {
        final msg = jsonDecode(resp.body)['message'] ?? 'Failed to update goal';
        throw GoalException(msg);
      }
    } on SocketException {
      throw const GoalException('No Internet connection');
    } on TimeoutException {
      throw const GoalException('Connection timed out');
    }
  }

  @override
  Future<void> deleteGoal(int id) async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const GoalUnauthorizedException();
    }

    try {
      final resp = await http
          .delete(
            Uri.parse('${AppConfig.baseUrl}/goals/$id'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 401) {
        await _authService.logout();
        throw const GoalUnauthorizedException();
      }

      if (resp.statusCode != 200) {
        final msg = jsonDecode(resp.body)['message'] ?? 'Failed to delete goal';
        throw GoalException(msg);
      }
    } on SocketException {
      throw const GoalException('No Internet connection');
    } on TimeoutException {
      throw const GoalException('Connection timed out');
    }
  }
}
