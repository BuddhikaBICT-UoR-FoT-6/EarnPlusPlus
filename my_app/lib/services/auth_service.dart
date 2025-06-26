import 'dart:convert'; // encode decode json
import 'package:http/http.dart' as http; // send post requests to backend
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // save login token securely
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class AuthService {
  static const String _tokenKey =
      'auth_token'; // identify the token when saving it to the phone's storage
  static const String _refreshTokenKey = 'refresh_token';
  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await startRegisterOtp(email: email, password: password);
  }

  Future<void> startRegisterOtp({
    required String email,
    required String password,
  }) async {
    if (kIsWeb && AppConfig.baseUrl == 'https://api.earnplusplus.com') {
      // Mock for GitHub Pages Web Demo
      await Future.delayed(const Duration(seconds: 1));
      return; 
    }

    final resp = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}/auth/register/send-otp'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 202) {
      throw Exception(_extractMessage(resp.body));
    }
  }

  Future<void> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    if (kIsWeb && AppConfig.baseUrl == 'https://api.earnplusplus.com') {
      // Mock for GitHub Pages Web Demo
      await Future.delayed(const Duration(seconds: 1));
      if (otp != '123456') {
        throw Exception('Invalid OTP. Use 123456 for web demo.');
      }
      return;
    }

    final resp = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}/auth/register/verify'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'otp': otp}),
        )
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 201) {
      throw Exception(_extractMessage(resp.body));
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (kIsWeb && AppConfig.baseUrl == 'https://api.earnplusplus.com') {
      // Mock for GitHub Pages Web Demo
      await Future.delayed(const Duration(seconds: 1));
      if (email.isNotEmpty && password.length >= 6) {
        await _secureStorage.write(key: _tokenKey, value: 'mock_token_web');
        await _secureStorage.write(key: _refreshTokenKey, value: 'mock_refresh_web');
        return;
      }
      throw Exception('Invalid credentials.');
    }

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
    final refreshToken = (data['refresh_token'] ?? '').toString();

    if (token.isEmpty) throw Exception('Missing token in server response');
    if (refreshToken.isEmpty) throw Exception('Missing refresh token in server response');

    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
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

  Future<String?> getCurrentEmail() async {
    final token = await getValidToken();
    if (token == null) {
      return null;
    }

    final payload = _decodePayload(token);
    return (payload?['email'] ?? '').toString();
  }

  Future<int?> getCurrentUserId() async {
    final token = await getValidToken();
    if (token == null) {
      return null;
    }

    final payload = _decodePayload(token);
    final sub = payload?['sub'];
    if (sub is int) {
      return sub;
    }
    if (sub is String) {
      return int.tryParse(sub);
    }
    return null;
  }

  // deletes the token from the phone
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // the logoutAllSessions method calls the backend logout-all endpoint to invalidate
  // all active sessions across all devices by incrementing the server's token_version.
  // After the backend confirms the invalidation, it also clears local credentials
  // so the current device is immediately logged out without waiting for token expiry.
  // This protects the user if they suspect credential compromise or want a complete
  // logout across all their sessions and devices.
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

  // the _decodePayload method decodes a JWT token's payload without verifying
  // the signature, allowing client-side inspection of claims like expiration time,
  // role, and user ID. This enables optimizations like checking expiration locally
  // before attempting a network request or gating UI elements based on role without
  // re-fetching user data. The backend still performs authoritative validation on
  // all API requests, ensuring security is not compromised by client-side claims.
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

  // the _refreshAccessToken method attempts to silently renew the access token
  // using the stored refresh token. If successful, it updates the local token and
  // returns the new access token without interrupting the user experience. If the
  // refresh fails (e.g., refresh token expired or revoked), it returns null,
  // signaling that the user needs to re-authenticate. This enables uninterrupted
  // app usage across long sessions without forcing explicit re-login on expiration.
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
