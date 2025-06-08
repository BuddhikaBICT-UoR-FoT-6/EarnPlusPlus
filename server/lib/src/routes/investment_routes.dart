import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart'; // for verifying JWT tokens in the request headers
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart'; // for handling HTTP requests and responses
import 'package:shelf_router/shelf_router.dart'; // for defining routes and handling route parameters

import '../config.dart';

/// Helper function to create a JSON response with the specified status code and body
Response _json(int statusCode, Object body) => Response(
      // the _json function takes a status code and a body object, encodes the body
      // as a JSON string, and returns a Response object with the appropriate headers
      // for JSON content and the specified status code
      statusCode,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );



// the _readJson helper function standardizes request body parsing across all
// mutation endpoints. It reads the raw request body, decodes it as JSON, and
// ensures that the result is a JSON object (not an array or primitive), throwing
// a FormatException if the body is malformed or not a valid object. This centralized
// parsing ensures consistent error handling and DX across POST, PUT, and DELETE routes.
Future<Map<String, dynamic>> _readJson(Request request) async {
  final body = await request.readAsString();
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Body must be a JSON object');
  }
  return decoded;
}

// the _parseDate helper validates and parses the date field from request payloads.
// It checks that the date is provided (not null) and that it can be parsed as a
// valid DateTime. By centralizing this parsing logic, all investment creation and
// update endpoints use the same validation rules and error messages, ensuring
// consistent API behavior and making error handling predictable for clients.
DateTime _parseDate(Object? value) {
  if (value == null) {
    throw const FormatException('date is required');
  }
  return DateTime.parse(value.toString());
}

// the _parseAsset helper validates and normalizes the asset name from request
// payloads. It trims whitespace and ensures the asset is not empty, rejecting
// blank or whitespace-only values that would create invalid portfolio entries.
// This validation keeps the database clean and ensures that users cannot add
// meaningless placeholder assets to their investment records.
String _parseAsset(Object? value) {
  final asset = (value ?? '').toString().trim();
  if (asset.isEmpty) {
    throw const FormatException('asset is required');
  }
  return asset;
}

// the _parseAmount helper validates that the investment amount is a positive
// number and coerces it to a double. It rejects zero, negative, or non-numeric
// values, ensuring that only valid investment amounts are recorded. This prevents
// nonsensical data like negative investments or zero-value entries from polluting
// the portfolio, maintaining data integrity and meaningful aggregations.
double _parseAmount(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  final parsed = double.tryParse((value ?? '').toString());
  if (parsed == null || parsed <= 0) {
    throw const FormatException('amount must be a positive number');
  }
  return parsed;
}

// the _extractUserId function extracts the user ID from the Authorization header
// of the incoming request, verifies the JWT token using the provided secret,
// and returns the user ID if the token is valid, or null if the token is missing,
// invalid, or does not contain a valid user ID in the "sub" claim
int? _extractUserId(Request req, String jwtSecret) {
  final auth = req.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) {
    return null;
  }

  final token = auth.substring('Bearer '.length).trim(); // trims the "Bearer "
  // and trims any leading/trailing whitespace to remove the "Bearer "
  // prefix from the Authorization header to get the raw token string
  if (token.isEmpty) {
    return null;
  }

  try {
    final verified = JWT.verify(token, SecretKey(jwtSecret));
    final payload =
        verified.payload; // the payload variable contains the decoded
    // JWT payload, which is expected to be a map with a "sub" field representing
    // the user ID. The function checks if the "sub" field is an integer
    // or a string that can be parsed as an integer, and returns the user ID as
    // an integer if valid, or null if the "sub" field is missing or invalid.
    if (payload is Map<String, dynamic>) {
      final tokenType = (payload['typ'] ?? 'access').toString();
      if (tokenType != 'access') {
        return null;
      }
      final sub = payload['sub'];
      if (sub is int) {
        return sub;
      }
      if (sub is String) {
        return int.tryParse(sub);
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

import '../domain/investment_repository.dart';
import '../domain/investment_dtos.dart';
import '../services/market_data_service.dart';

/// Creates and configures the investment routes router
Router investmentRoutes(InvestmentRepository repository, ServerConfig config, MarketDataService marketDataService) {
  final router = Router();

  /// GET /investments - Retrieves all investments from the database
  router.get('/investments', (Request req) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final list = await repository.fetchInvestments(userId);
    
    // Get unique assets
    final assets = list.map((item) => item['asset'] as String).toSet();
    final multipliers = marketDataService.fetchLiveMultipliers(assets);

    final dtos = list.map((item) {
      final initialAmount = (item['amount'] as num).toDouble();
      final assetName = item['asset'] as String;
      final multiplier = multipliers[assetName] ?? 1.0;
      final currentValue = initialAmount * multiplier;
      final plPercent = ((currentValue - initialAmount) / initialAmount) * 100;

      return InvestmentSummaryDto(
        id: item['id'] as int,
        name: assetName,
        currentValue: currentValue,
        plPercent: plPercent,
        insightTags: [], // Will be hydrated later
      ).toJson();
    }).toList();
    return _json(200, dtos);
  });

  /// GET /investments/export/csv - Export all investments as CSV
  router.get('/investments/export/csv', (Request req) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final list = await repository.fetchInvestments(userId);
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('ID,Date,Asset,InitialAmount');
    
    for (var item in list) {
      final id = item['id'];
      final date = item['date'];
      final asset = item['asset'];
      final amount = item['amount'];
      buffer.writeln('$id,$date,$asset,$amount');
    }

    return Response.ok(
      buffer.toString(),
      headers: {
        'Content-Type': 'text/csv',
        'Content-Disposition': 'attachment; filename="investments.csv"'
      },
    );
  });

  /// GET /investments/<id> - Retrieves a single investment detail
  router.get('/investments/<id>', (Request req, String id) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final investmentId = int.tryParse(id);
    if (investmentId == null) {
      return _json(400, {'message': 'Invalid investment id'});
    }

    try {
      final row = await repository.getInvestmentById(investmentId, userId);
      if (row == null) {
        return _json(404, {'message': 'Investment not found'});
      }
      
      final dto = InvestmentDetailDto(
        id: row['id'] as int,
        date: row['date'].toString(),
        name: row['asset'] as String,
        currentValue: (row['amount'] as num).toDouble(),
      );
      return _json(200, dto.toJson());
    } catch (e) {
      return _json(500, {'message': 'Internal Server Error'});
    }
  });

  // the POST /investments endpoint creates a new investment record for the
  // authenticated user. The endpoint validates the date, asset, and amount fields
  // using the centralized parser helpers, then inserts the record into the database.
  // On success, it returns a 201 Created status with the full created record,
  // allowing the client to immediately display the new investment without an extra fetch.
  router.post('/investments', (Request req) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    try {
      final payload = await _readJson(req);
      final date = _parseDate(payload['date']);
      final asset = _parseAsset(payload['asset']);
      final amount = _parseAmount(payload['amount']);

      await repository.createInvestment(userId, date, asset, amount);

      final list = await repository.fetchInvestments(userId);
      final lastItem = list.last;
      final dto = InvestmentDetailDto(
        id: lastItem['id'] as int,
        date: lastItem['date'].toString(),
        name: lastItem['asset'] as String,
        currentValue: (lastItem['amount'] as num).toDouble(),
      );
      return _json(201, dto.toJson());
    } on FormatException catch (e) {
      return _json(400, {'message': e.message});
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

  // the PUT /investments/<id> endpoint updates an existing investment record,
  // but only if the investment belongs to the authenticated user. This scopes
  // mutations to the user's own data, preventing one user from modifying another's
  // investments. The endpoint re-validates all fields (date, asset, amount) and
  // returns the updated record on success, keeping client state in sync with the server.
  router.put('/investments/<id>', (Request req, String id) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final investmentId = int.tryParse(id);
    if (investmentId == null) {
      return _json(400, {'message': 'Invalid investment id'});
    }

    try {
      final payload = await _readJson(req);
      final date = _parseDate(payload['date']);
      final asset = _parseAsset(payload['asset']);
      final amount = _parseAmount(payload['amount']);

      final affectedRows = await repository.updateInvestment(investmentId, userId, date, asset, amount);

      if (affectedRows == 0) {
        return _json(404, {'message': 'Investment not found'});
      }

      final row = await repository.getInvestmentById(investmentId, userId);
      if (row == null) {
        return _json(404, {'message': 'Investment not found'});
      }
      
      final dto = InvestmentDetailDto(
        id: row['id'] as int,
        date: row['date'].toString(),
        name: row['asset'] as String,
        currentValue: (row['amount'] as num).toDouble(),
      );
      return _json(200, dto.toJson());
    } on FormatException catch (e) {
      return _json(400, {'message': e.message});
    } catch (e) {
      return _json(400, {'message': 'Bad request: ${e.toString()}'});
    }
  });

  // the DELETE /investments/<id> endpoint permanently removes an investment
  // record, but only if it belongs to the authenticated user. This ensures users
  // can only manage their own investments and prevents accidental or malicious
  // deletions of other users' portfolio entries. The endpoint returns a 200 OK
  // on success with a confirmation message, or 404 if the investment does not exist
  // or does not belong to the caller.
  router.delete('/investments/<id>', (Request req, String id) async {
    final userId = _extractUserId(req, config.jwtSecret);
    if (userId == null) {
      return _json(401, {'message': 'Unauthorized'});
    }

    final investmentId = int.tryParse(id);
    if (investmentId == null) {
      return _json(400, {'message': 'Invalid investment id'});
    }

    final affectedRows = await repository.deleteInvestment(investmentId, userId);

    if (affectedRows == 0) {
      return _json(404, {'message': 'Investment not found'});
    }

    return _json(200, {'message': 'Investment deleted'});
  });

  return router;
}
