import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../domain/admin_models.dart';

class AdminRepository {
  final AuthService _authService;

  AdminRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<String> _token() async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const AdminUnauthorizedException();
    }
    return token;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {'Authorization': 'Bearer $token'};
  }

  Future<UserAccount> fetchMe() async {
    final resp = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/users/me'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 401) {
      await _authService.logout();
      throw const AdminUnauthorizedException();
    }

    if (resp.statusCode != 200) {
      throw AdminApiException('Server returned ${resp.statusCode}');
    }

    return UserAccount.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<List<UserAccount>> fetchUsers() async {
    final resp = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/admin/users'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 401) {
      await _authService.logout();
      throw const AdminUnauthorizedException();
    }

    if (resp.statusCode == 403) {
      throw const AdminForbiddenException();
    }

    if (resp.statusCode != 200) {
      throw AdminApiException('Server returned ${resp.statusCode}');
    }

    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => UserAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminSummary> fetchAdminSummary() async {
    final resp = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/admin/dashboard'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 401) {
      await _authService.logout();
      throw const AdminUnauthorizedException();
    }

    if (resp.statusCode == 403) {
      throw const AdminForbiddenException();
    }

    if (resp.statusCode != 200) {
      throw AdminApiException('Server returned ${resp.statusCode}');
    }

    return AdminSummary.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  Future<SuperAdminSummary> fetchSuperAdminSummary() async {
    final resp = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/superadmin/dashboard'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 401) {
      await _authService.logout();
      throw const AdminUnauthorizedException();
    }

    if (resp.statusCode == 403) {
      throw const AdminForbiddenException();
    }

    if (resp.statusCode != 200) {
      throw AdminApiException('Server returned ${resp.statusCode}');
    }

    return SuperAdminSummary.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  Future<void> updateUserRole({required int userId, required String role}) async {
    final resp = await http
        .patch(
          Uri.parse('${AppConfig.baseUrl}/superadmin/users/$userId/role'),
          headers: {
            ...(await _headers()),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'role': role}),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 401) {
      await _authService.logout();
      throw const AdminUnauthorizedException();
    }

    if (resp.statusCode == 403) {
      throw const AdminForbiddenException();
    }

    if (resp.statusCode != 200) {
      throw AdminApiException('Server returned ${resp.statusCode}');
    }
  }
}

class AdminUnauthorizedException implements Exception {
  const AdminUnauthorizedException();
}

class AdminForbiddenException implements Exception {
  const AdminForbiddenException();
}

class AdminApiException implements Exception {
  final String message;
  const AdminApiException(this.message);

  @override
  String toString() => message;
}
