import 'dart:convert'; // for encoding and decoding JSON data

import 'package:http/http.dart'
    as http; // for making HTTP requests to the backend
// API, allowing us to fetch data and interact with the server's endpoints for
// admin-related operations

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../domain/admin_models.dart';

// The AdminRepository is responsible for handling all data operations related to
// admin functionalities. It interacts with the backend API to fetch user accounts,
// admin summaries, and to update user roles. It uses the AuthService to manage
// authentication tokens and includes them in the request headers to access protected
// endpoints. The repository also handles various response scenarios, including
// unauthorized access, forbidden access, and API errors, throwing appropriate
// exceptions that can be caught and handled by the UI layer to provide feedback to the user.
class AdminRepository {
  final AuthService
  _authService; // instance of AuthService to manage authentication
  // tokens and handle user authentication for admin-related API requests, ensuring
  // that only authorized users can access admin functionalities and that the
  // authentication state is maintained securely across the application

  AdminRepository({AuthService? authService})
    : _authService =
          authService ?? AuthService(); // allows for dependency injection
  // of AuthService, enabling easier testing and flexibility in swapping out the
  // authentication service if needed without modifying the AdminRepository's
  //implementation, making it more modular and testable by allowing us to inject
  // a mock AuthService during testing or to use a different implementation if
  // the authentication logic changes in the future without affecting the AdminRepository's code

  // the _token method retrieves a valid authentication token from the AuthService.
  // It checks if the token is null or empty, and if so, it throws an AdminUnauthorizedException
  // to indicate that the user is not authorized to perform admin operations.
  // If a valid token is retrieved, it returns the token as a string. This method
  // is used internally by the AdminRepository to ensure that all API requests
  // include a valid authentication token in the headers, allowing access to protected
  // admin endpoints and maintaining the security of the application.
  Future<String> _token() async {
    final token = await _authService.getValidToken();
    if (token == null || token.isEmpty) {
      throw const AdminUnauthorizedException();
    }
    return token;
  }

  // The _headers method is a private helper function that constructs the HTTP headers
  // required for authenticated API requests. It retrieves a valid authentication
  // token using the _token method and creates a map of headers containing the
  // Authorization token. This ensures that every API request made by the AdminRepository
  // includes the necessary authentication credentials, allowing the backend to
  // verify the user's identity and permissions before processing the request.
  // The method is asynchronous because it awaits the result of _token(), which
  // might involve asynchronous operations like checking token validity or refreshing
  // the token if it has expired. This approach centralizes header management and
  // ensures consistent authentication across all admin-related API calls.
  Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {'Authorization': 'Bearer $token'};
  }

  // The fetchMe method retrieves the current user's account information from the
  // backend API. It makes a GET request to the /users/me endpoint with the
  // necessary authentication headers. If the response status code is 401, it logs
  // the user out and throws an AdminUnauthorizedException. If the status code is
  // not 200, it throws an AdminApiException with the status code. If the request
  // is successful, it parses the JSON response and returns a UserAccount object
  // representing the current user's account information, which can be used by the UI
  // to display user details or manage user-specific admin functionalities.
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

  // fetchUsers retrieves the list of user accounts from the backend API. It makes
  // a GET request to the /admin/users endpoint with the necessary authentication
  // headers. If the response status code is 401, it logs the user out and throws
  // an AdminUnauthorizedException. If the status code is 403, it throws an
  // AdminForbiddenException. If the status code is not 200, it throws an
  // AdminApiException with the status code. If the request is successful,
  // it parses the JSON response into a list of UserAccount objects, which can be
  // used by the UI to display
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

  // fetchAdminSummary retrieves the admin dashboard summary data from the backend API.
  // It makes a GET request to the /admin/dashboard endpoint with the necessary
  // authentication headers. If the response status code is 401, it logs the user out
  // and throws an AdminUnauthorizedException. If the status code is 403, it throws
  // an AdminForbiddenException. If the status code is not 200, it throws an AdminApiException
  // with the status code. If the request is successful, it parses the JSON response
  // and returns an AdminSummary object containing the summary data for the admin dashboard,
  // which can be used by the UI to display key metrics and information relevant to the admin
  // dashboard, such as the number of users, investments, and total amount, providing insights
  // into the overall state and performance of the application's admin features.
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

  // fetchSuperAdminSummary retrieves the super admin dashboard summary data from
  // the backend API. It makes a GET request to the /superadmin/dashboard endpoint
  // with the necessary authentication headers. If the response status code is 401,
  // it logs the user out and throws an AdminUnauthorizedException. If the status
  // code is 403, it throws an AdminForbiddenException. If the status code is not 200,
  // it throws an AdminApiException with the status code. If the request is successful,
  // it parses the JSON response and returns a SuperAdminSummary object containing
  // the summary data for the super admin dashboard, which can be used by the UI
  // to display key metrics
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

  // updateUserRole updates the role of a user account by making a PATCH request to the
  // /superadmin/users/{userId}/role endpoint with the necessary authentication headers
  // and a JSON body containing the new role. If the response status code is 401, it logs
  // the user out and throws an AdminUnauthorizedException. If the status code is 403,
  // it throws an AdminForbiddenException. If the status code is not 200, it throws an
  // AdminApiException with the status code. This method is used to grant or revoke
  // administrative privileges to users, allowing the super admin to manage user
  // permissions and access levels within the application.
  Future<void> updateUserRole({
    required int userId,
    required String role,
  }) async {
    final resp = await http
        .patch(
          Uri.parse('${AppConfig.baseUrl}/superadmin/users/$userId/role'),
          headers: {...(await _headers()), 'Content-Type': 'application/json'},
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
  // thrown when the request cannot be authenticated and the client must
  // re-authenticate before retrying admin operations.
  const AdminUnauthorizedException();
}

class AdminForbiddenException implements Exception {
  // thrown when authentication succeeded but the current role does not have
  // permission to access the requested admin or superadmin endpoint.
  const AdminForbiddenException();
}

class AdminApiException implements Exception {
  // wraps non-auth API failures so the UI layer can surface readable feedback
  // while keeping repository response handling centralized.
  final String message;
  const AdminApiException(this.message);

  @override
  String toString() => message;
}
