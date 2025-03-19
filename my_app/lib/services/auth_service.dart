import 'dart:convert'; // encode decode json
import 'package:http/http.dart' as http; // send post requests to backend
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // save login token securely
import '../config/app_config.dart';

class AuthService {
  static const String _tokenKey =
      'auth_token'; // identify the token when saving it to the phone's storage
  static const String _refreshTokenKey = 'refresh_token';
  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage(); // instance of
  // FlutterSecureStorage to handle secure storage operations such as saving,
  // retrieving, and deleting the authentication token on the device securely
  // using platform-specific secure storage mechanisms like Keychain on iOS and
  // EncryptedSharedPreferences on Android to protect sensitive data like
  //authentication tokens from unauthorized access and ensure that the user's
  // login state is maintained securely across app sessions and app restarts

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
    final refreshToken = (data['refresh_token'] ?? '').toString();

    if (token.isEmpty) {
      throw Exception('Missing token in server response');
    }

    if (refreshToken.isEmpty) {
      throw Exception('Missing refresh token in server response');
    }

    await _secureStorage.write(key: _tokenKey, value: token); // saves the token
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    // to the phone's secure storage with the key _tokenKey for later retrieval
    // when making authenticated requests to the backend, allowing the app to maintain
    // the user's login state across sessions and app restarts without requiring
    // the user to log in again until the token expires or is deleted
  }

  // retrieves the saved string from storage
  Future<String?> getToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  // retrieves the saved token and checks if it has expired by decoding the token's
  // payload and comparing the expiration time to the current time. If the token
  // is valid and not expired, it returns the token; otherwise, it returns null,
  // indicating that the user is not logged in or needs to log in again.
  Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null) {
      return null;
    }

    if (!_isExpired(token)) {
      return token;
    }

    final refreshedToken = await _refreshAccessToken();
    if (refreshedToken == null || _isExpired(refreshedToken)) {
      await logout();
      return null;
    }

    return refreshedToken;
  }

  Future<String> getCurrentRole() async {
    final token = await getValidToken();
    if (token == null) {
      return 'user';
    }

    final payload = _decodePayload(token);
    final role = (payload?['role'] ?? 'user').toString();
    if (role == 'admin' || role == 'superadmin') {
      return role;
    }
    return 'user';
  }

  // deletes the token from the phone
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<void> logoutAllSessions() async {
    final token = await getValidToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await http.post(
      Uri.parse('${AppConfig.baseUrl}/auth/logout-all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    await logout();
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

  // checks if the token is expired by decoding the JWT token's payload and comparing
  // the "exp" claim to the current time. If the token is malformed, missing the
  // "exp" claim, or if the current time is past the expiration time, it returns
  // true, indicating that the token is expired; otherwise, it returns false.
  bool _isExpired(String token) {
    try {
      final payload = _decodePayload(token);
      if (payload == null) {
        return true;
      }

      final exp = payload['exp']; // the "exp" claim represents the expiration
      // time of the token in seconds since the epoch (Unix time). The code checks
      // if the "exp" claim is present and is a number, and then compares it to
      // the current time to determine if the token has expired. If the "exp" claim
      // is missing or not a valid number, it treats the token as expired for security reasons.
      if (exp is! num) {
        return true;
      }

      final expiryMs = exp.toInt() * 1000;
      return DateTime.now().millisecondsSinceEpoch >= expiryMs;
    } catch (_) {
      return true;
    }
  }

  Map<String, dynamic>? _decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
    final decoded = jsonDecode(utf8.decode(payloadBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  }

  Future<String?> _getRefreshToken() async {
    final token = await _secureStorage.read(key: _refreshTokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) {
      return null;
    }

    try {
      final resp = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (resp.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = (data['token'] ?? '').toString();
      if (token.isEmpty) {
        return null;
      }

      await _secureStorage.write(key: _tokenKey, value: token);
      return token;
    } catch (_) {
      return null;
    }
  }
}
