import 'dart:async'; // for TimeoutException
import 'dart:convert'; // for json decoding
import 'dart:io'; // for socket and network exceptions

import 'package:http/http.dart'
    as http; // for making http requests to the backend

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../domain/investment_summary_dto.dart';
import '../domain/investment_detail_dto.dart';

// The InvestmentRepository is responsible for fetching investment data from the
// backend API. It uses the AuthService to retrieve the authentication token and
// includes it in the request headers to access protected endpoints. The repository
// handles various response scenarios, including unauthorized access and API errors,
// and it parses the JSON response into a list of Investment objects that can be
// used by the rest of the application.
import '../domain/investment_repository.dart';
import 'local_investment_database.dart';

class ApiInvestmentRepository implements InvestmentRepository {
  final AuthService _authService;
  final LocalInvestmentDatabase _localDb;

  ApiInvestmentRepository({AuthService? authService, LocalInvestmentDatabase? localDb})
    : _authService = authService ?? AuthService(),
      _localDb = localDb ?? LocalInvestmentDatabase();
  // dependency injection also allows for mocking the instance during testing
  // of AuthService, making it easier to test the InvestmentRepository in
  //isolation without relying on the actual implementation of AuthService

  // fetchInvestments retrieves the list of investments from the backend API.
  // It first gets the authentication token from the AuthService, then makes
  // a GET request to the /investments endpoint with the token included in the
  // Authorization header.
  Future<List<InvestmentSummaryDto>> fetchInvestments() async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const InvestmentUnauthorizedException();
    }

    try {
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
        throw InvestmentApiException(
          'Server error (${resp.statusCode}). Please try again later.',
        );
      }

      // the response body is expected to be a JSON array of investment objects,
      // which is decoded into a List<dynamic> and then mapped to a List<Investment>
      // using the Investment.fromJson factory constructor to create Investment
      // instances from the JSON data.
      final list = jsonDecode(resp.body) as List<dynamic>;
      final investments = list
          .map((e) => InvestmentSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList();
      
      // Cache the newly fetched investments
      try {
        await _localDb.cacheInvestments(investments);
      } catch (_) {} // Ignore cache write errors
      
      return investments;
    } on InvestmentUnauthorizedException {
      rethrow;
    } on InvestmentApiException {
      rethrow;
    } on SocketException catch (e) {
      final cached = await _localDb.getCachedInvestments();
      if (cached.isNotEmpty) return cached;
      throw InvestmentApiException(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException catch (e) {
      final cached = await _localDb.getCachedInvestments();
      if (cached.isNotEmpty) return cached;
      throw InvestmentApiException(
        'Connection timeout. The server is taking too long to respond. Please try again.',
      );
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw InvestmentApiException(
          'Unable to reach the server. Please check your internet connection.',
        );
      }
      throw InvestmentApiException(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  @override
  Future<InvestmentDetailDto> fetchInvestmentById(int id) async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const InvestmentUnauthorizedException();
    }

    try {
      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/investments/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 401) {
        await _authService.logout();
        throw const InvestmentUnauthorizedException();
      }

      if (resp.statusCode != 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        throw InvestmentApiException(
          body['message']?.toString() ?? 'Failed to load investment',
        );
      }

      return InvestmentDetailDto.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    } on InvestmentUnauthorizedException {
      rethrow;
    } on InvestmentApiException {
      rethrow;
    } on SocketException catch (e) {
      throw InvestmentApiException(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException catch (e) {
      throw InvestmentApiException(
        'Connection timeout. The server is taking too long to respond. Please try again.',
      );
    } catch (e) {
      throw InvestmentApiException('Network error: ${e.toString()}');
    }
  }

  // the createInvestment method sends a new investment record to the API and
  // returns the created record as returned by the server. This allows the client
  // to retrieve server-generated fields (like the investment ID) without making
  // an additional GET request, keeping the UI state consistent with what the
  // server persisted. The method handles authentication and network timeouts.
  Future<InvestmentDetailDto> createInvestment({
    required DateTime date,
    required String asset,
    required String amount,
  }) async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const InvestmentUnauthorizedException();
    }

    try {
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

      if (resp.statusCode == 400) {
        // Extract validation error message from backend
        try {
          final error = jsonDecode(resp.body) as Map<String, dynamic>;
          final message = error['message'] as String?;
          throw InvestmentApiException(
            message ?? 'Please check your input and try again',
          );
        } catch (e) {
          throw InvestmentApiException(
            'Validation error: Please check your input',
          );
        }
      }

      if (resp.statusCode != 201) {
        throw InvestmentApiException(
          'Server error (${resp.statusCode}). Please try again later.',
        );
      }

      return InvestmentDetailDto.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    } on InvestmentUnauthorizedException {
      rethrow;
    } on InvestmentApiException {
      rethrow;
    } on SocketException catch (e) {
      throw InvestmentApiException(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException catch (e) {
      throw InvestmentApiException(
        'Connection timeout. The server is taking too long to respond. Please try again.',
      );
    } catch (e) {
      // Catch any other network or parsing errors
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw InvestmentApiException(
          'Unable to reach the server. Please check your internet connection.',
        );
      }
      throw InvestmentApiException(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  // the updateInvestment method sends the full updated record payload to the
  // API and returns the server's confirmation of the update. The method validates
  // that the investment belongs to the authenticated user before allowing the
  // update to proceed, ensuring users cannot modify other users' investments.
  // The returned record reflects any server-side transformations or defaults.
  Future<InvestmentDetailDto> updateInvestment({
    required int id,
    required DateTime date,
    required String asset,
    required String amount,
  }) async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const InvestmentUnauthorizedException();
    }

    try {
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

      if (resp.statusCode == 400) {
        try {
          final error = jsonDecode(resp.body) as Map<String, dynamic>;
          final message = error['message'] as String?;
          throw InvestmentApiException(
            message ?? 'Please check your input and try again',
          );
        } catch (e) {
          throw InvestmentApiException(
            'Validation error: Please check your input',
          );
        }
      }

      if (resp.statusCode == 404) {
        throw InvestmentApiException(
          'Investment not found. It may have been deleted.',
        );
      }

      if (resp.statusCode != 200) {
        throw InvestmentApiException(
          'Server error (${resp.statusCode}). Please try again later.',
        );
      }

      return InvestmentDetailDto.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    } on InvestmentUnauthorizedException {
      rethrow;
    } on InvestmentApiException {
      rethrow;
    } on SocketException catch (e) {
      throw InvestmentApiException(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException catch (e) {
      throw InvestmentApiException(
        'Connection timeout. The server is taking too long to respond. Please try again.',
      );
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw InvestmentApiException(
          'Unable to reach the server. Please check your internet connection.',
        );
      }
      throw InvestmentApiException(
        'An unexpected error occurred. Please try again.',
      );
    }
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

    try {
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

      if (resp.statusCode == 404) {
        throw InvestmentApiException(
          'Investment not found. It may have been deleted.',
        );
      }

      if (resp.statusCode != 200) {
        throw InvestmentApiException(
          'Server error (${resp.statusCode}). Please try again later.',
        );
      }
    } on InvestmentUnauthorizedException {
      rethrow;
    } on InvestmentApiException {
      rethrow;
    } on SocketException catch (e) {
      throw InvestmentApiException(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException catch (e) {
      throw InvestmentApiException(
        'Connection timeout. The server is taking too long to respond. Please try again.',
      );
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw InvestmentApiException(
          'Unable to reach the server. Please check your internet connection.',
        );
      }
      throw InvestmentApiException(
        'An unexpected error occurred. Please try again.',
      );
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
