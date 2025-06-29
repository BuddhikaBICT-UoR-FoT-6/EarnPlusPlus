import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

final List<WebSocketChannel> _clients = [];
Timer? _marketSimulationTimer;

Router wsRoutes() {
  final router = Router();

  // The actual WebSocket handler
  final handler = webSocketHandler((WebSocketChannel webSocket) {
    _clients.add(webSocket);
    
    // Start simulation timer if not already running
    if (_marketSimulationTimer == null || !_marketSimulationTimer!.isActive) {
      _startMarketSimulation();
    }

    webSocket.stream.listen(
      (message) {
        // Handle incoming messages if needed
      },
      onDone: () {
        _clients.remove(webSocket);
        if (_clients.isEmpty) {
          _marketSimulationTimer?.cancel();
        }
      },
      onError: (e) {
        _clients.remove(webSocket);
      },
    );
  });

  router.get('/live', handler);

  return router;
}

void _startMarketSimulation() {
  final random = Random();
  _marketSimulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
    if (_clients.isEmpty) {
      timer.cancel();
      return;
    }

    // Broadcast market update
    final update = {
      'type': 'market_update',
      'multiplier': 0.95 + random.nextDouble() * 0.1, // +/- 5%
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final payload = jsonEncode(update);
    for (final client in _clients) {
      client.sink.add(payload);
    }
  });
}
