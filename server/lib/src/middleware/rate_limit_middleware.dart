import 'package:shelf/shelf.dart';

class RateLimiter {
  final int maxRequests;
  final Duration window;
  
  // Map of IP -> list of request timestamps
  final Map<String, List<DateTime>> _requests = {};

  RateLimiter({this.maxRequests = 100, this.window = const Duration(minutes: 1)});

  Middleware get middleware => (innerHandler) {
        return (request) async {
          final ip = _getClientIp(request);
          final now = DateTime.now();

          // Clean up old requests
          _requests.putIfAbsent(ip, () => []);
          _requests[ip]!.removeWhere((timestamp) => now.difference(timestamp) > window);

          if (_requests[ip]!.length >= maxRequests) {
            return Response(429, body: 'Too Many Requests');
          }

          _requests[ip]!.add(now);
          return innerHandler(request);
        };
      };

  String _getClientIp(Request request) {
    // Attempt to get X-Forwarded-For if behind a proxy
    final forwardedFor = request.headers['x-forwarded-for'];
    if (forwardedFor != null && forwardedFor.isNotEmpty) {
      return forwardedFor.split(',').first.trim();
    }
    
    // Fallback to connection info if available (shelf exposes some info, but typically just return a generic key if not found)
    // For local MVP, we use a generic string or extract from context if possible
    final connectionInfo = request.context['shelf.io.connection_info'];
    if (connectionInfo != null) {
      // It's a HttpConnectionInfo object, but we can't easily cast it without importing dart:io inside shelf context sometimes
      return connectionInfo.toString();
    }
    return 'unknown_ip';
  }
}

Middleware rateLimiter({int maxRequests = 100, Duration window = const Duration(minutes: 1)}) {
  return RateLimiter(maxRequests: maxRequests, window: window).middleware;
}
