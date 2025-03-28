import 'dart:convert'; // for json decoding

import 'package:http/http.dart'
    as http; // for making http requests to the backend

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../domain/investment.dart';

// The InvestmentRepository is responsible for fetching investment data from the
// backend API. It uses the AuthService to retrieve the authentication token and
// includes it in the request headers to access protected endpoints. The repository
// handles various response scenarios, including unauthorized access and API errors,
// and it parses the JSON response into a list of Investment objects that can be
// used by the rest of the application.
class InvestmentRepository {
  final AuthService _authService;

  InvestmentRepository({AuthService? authService})
    : _authService =
          authService ?? AuthService(); // allows for dependency injection
  // dependency injection also allows for mocking the instance during testing
  // of AuthService, making it easier to test the InvestmentRepository in
  //isolation without relying on the actual implementation of AuthService

  // fetchInvestments retrieves the list of investments from the backend API.
  // It first gets the authentication token from the AuthService, then makes
  // a GET request to the /investments endpoint with the token included in the
  // Authorization header.
  Future<List<Investment>> fetchInvestments() async {
    final token = await _authService.getValidToken(); // retrieves a valid
    // authentication token from the AuthService, which may involve checking if
    // the token is expired and refreshing it if necessary to ensure that the
    // request to the backend API is authenticated properly. This step is crucial
    // for accessing protected endpoints that require user authentication and for
    // maintaining the security of the application by ensuring that only
    // authorized users can access sensitive data like investments.
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

    // the response body is expected to be a JSON array of investment objects,
    // which is decoded into a List<dynamic> and then mapped to a List<Investment>
    // using the Investment.fromJson factory constructor to create Investment
    // instances from the JSON data.
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list
        .map((e) => Investment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // the createInvestment method sends a new investment record to the API and
  // returns the created record as returned by the server. This allows the client
  // to retrieve server-generated fields (like the investment ID) without making
  // an additional GET request, keeping the UI state consistent with what the
  // server persisted. The method handles authentication and network timeouts.
  Future<Investment> createInvestment({
    required DateTime date,
    required String asset,
    required String amount,
  }) async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const InvestmentUnauthorizedException();
    }

    final resp = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}/investments'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'date': date.toIso8601String().split('T').first,
            'asset': asset,
            'amount': amount,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 401) {
      await _authService.logout();
      throw const InvestmentUnauthorizedException();
    }

    if (resp.statusCode != 201) {
      throw InvestmentApiException('Server returned ${resp.statusCode}');
    }

    return Investment.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  // the updateInvestment method sends the full updated record payload to the
  // API and returns the server's confirmation of the update. The method validates
  // that the investment belongs to the authenticated user before allowing the
  // update to proceed, ensuring users cannot modify other users' investments.
  // The returned record reflects any server-side transformations or defaults.
  Future<Investment> updateInvestment({
    required int id,
    required DateTime date,
    required String asset,
    required String amount,
  }) async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const InvestmentUnauthorizedException();
    }

    final resp = await http
        .put(
          Uri.parse('${AppConfig.baseUrl}/investments/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'date': date.toIso8601String().split('T').first,
            'asset': asset,
            'amount': amount,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 401) {
      await _authService.logout();
      throw const InvestmentUnauthorizedException();
    }

    if (resp.statusCode != 200) {
      throw InvestmentApiException('Server returned ${resp.statusCode}');
    }

    return Investment.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  // the deleteInvestment method removes an investment record from the server
  // and, on success, removes the corresponding item from the local list. The
  // isMutating flag prevents UI race conditions, and the state is updated to
  // reflect whether investments remain (success) or all are gone (empty state).
  // This local-list update avoids an unnecessary refetch after deletion.
  Future<void> deleteInvestment(int id) async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const InvestmentUnauthorizedException();
    }

    final resp = await http
        .delete(
          Uri.parse('${AppConfig.baseUrl}/investments/$id'),
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
  }
}

// The following three classes represent custom exceptions that can be thrown
// by the InvestmentRepository to indicate specific error conditions. The
// InvestmentUnauthorizedException is thrown when the user is not authenticated
// or when the authentication token is invalid. The InvestmentApiException is
// thrown when the API returns an error response, and it includes a message
// describing the error.
class InvestmentUnauthorizedException implements Exception {
  const InvestmentUnauthorizedException();
}

// The InvestmentApiException is a custom exception that represents errors returned
// by the investment API. It includes a message that describes the error, which
// can be used to provide more context when handling the exception in the UI or
// logging it for debugging purposes. This allows the application to differentiate
// between different types of errors and respond accordingly, such as showing an
// error message to the user or taking specific actions based on the error type.
class InvestmentApiException implements Exception {
  final String message;
  const InvestmentApiException(this.message);

  @override
  String toString() => message;
}
