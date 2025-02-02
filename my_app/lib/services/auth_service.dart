import 'dart:convert'; // encode decode json
import 'package:http/http.dart' as http; // send post requests to backend
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // save login token securely
import '../config/app_config.dart';

class AuthService {
  static const String _tokenKey =
      'auth_token'; // identify the token when saving it to the phone's storage
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> register({
    required String email,
    required String password,
  }) async {
    // send req to server registration endpoint
    final resp = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/register'),
      headers: const {
        'Content-Type': 'application/json',
      }, // tell server the data being sent is in json format
      body: jsonEncode({
        'email': email,
        'password': password,
      }), // converts the Map of user credentials into a raw json string
    );

    // pulls the error reason from the server's response to show to the user
    if (resp.statusCode != 201) {
      throw Exception(_extractMessage(resp.body));
    }
  }

  // send login req to backend and save the returned token to the phone's storage for future authenticated requests
  Future<void> login({required String email, required String password}) async {
    final resp = await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (resp.statusCode != 200) {
      throw Exception(_extractMessage(resp.body));
    }

    // takes the response string from the server and turns it back into a dart map
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final token = (data['token'] ?? '')
        .toString(); // looks for the key token in the server's response

    if (token.isEmpty) {
      throw Exception('Missing token in server response');
    }

    await _secureStorage.write(key: _tokenKey, value: token);
  }

  // retrieves the saved string from storage
  Future<String?> getToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  // deletes the token from the phone
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  String _extractMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message']; // finds a "message" field, and returns it
        if (message != null) {
          return message
              .toString(); // if the response isn't json (or the field is missing), it just returns the raw response text as a fallback
        }
      }
      return responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}
