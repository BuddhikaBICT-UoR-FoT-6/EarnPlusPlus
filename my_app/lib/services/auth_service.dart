import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthService {
	static const String _tokenKey = 'auth_token';

	Future<void> register({required String email, required String password}) async {
		final resp = await http.post(
			Uri.parse('${AppConfig.baseUrl}/auth/register'),
			headers: const {'Content-Type': 'application/json'},
			body: jsonEncode({'email': email, 'password': password}),
		);

		if (resp.statusCode != 201) {
			throw Exception(_extractMessage(resp.body));
		}
	}

	Future<void> login({required String email, required String password}) async {
		final resp = await http.post(
			Uri.parse('${AppConfig.baseUrl}/auth/login'),
			headers: const {'Content-Type': 'application/json'},
			body: jsonEncode({'email': email, 'password': password}),
		);

		if (resp.statusCode != 200) {
			throw Exception(_extractMessage(resp.body));
		}

		final data = jsonDecode(resp.body) as Map<String, dynamic>;
		final token = (data['token'] ?? '').toString();

		if (token.isEmpty) {
			throw Exception('Missing token in server response');
		}

		final prefs = await SharedPreferences.getInstance();
		await prefs.setString(_tokenKey, token);
	}

	Future<String?> getToken() async {
		final prefs = await SharedPreferences.getInstance();
		final token = prefs.getString(_tokenKey);
		if (token == null || token.isEmpty) {
			return null;
		}
		return token;
	}

	Future<void> logout() async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.remove(_tokenKey);
	}

	String _extractMessage(String responseBody) {
		try {
			final decoded = jsonDecode(responseBody);
			if (decoded is Map<String, dynamic>) {
				final message = decoded['message'];
				if (message != null) {
					return message.toString();
				}
			}
			return responseBody;
		} catch (_) {
			return responseBody;
		}
	}
}
