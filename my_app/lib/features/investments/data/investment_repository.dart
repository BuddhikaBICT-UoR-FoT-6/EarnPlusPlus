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
    final token = await _authService.getValidToken();
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
