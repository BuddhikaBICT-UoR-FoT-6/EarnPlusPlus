import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../domain/investment.dart';

class InvestmentRepository {
  final AuthService _authService;

  InvestmentRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<List<Investment>> fetchInvestments() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw const InvestmentUnauthorizedException();
    }

    final resp = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/investments'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 401) {
      await _authService.logout();
      throw const InvestmentUnauthorizedException();
    }

    if (resp.statusCode != 200) {
      throw InvestmentApiException('Server returned ${resp.statusCode}');
    }

    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => Investment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class InvestmentUnauthorizedException implements Exception {
  const InvestmentUnauthorizedException();
}

class InvestmentApiException implements Exception {
  final String message;
  const InvestmentApiException(this.message);

  @override
  String toString() => message;
}
