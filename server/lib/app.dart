import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import 'src/config.dart';
import 'src/db/mysql.dart';
import 'src/db/schema.dart';
import 'src/routes/auth_routes.dart';
import 'src/routes/investment_routes.dart';
import 'src/routes/user_routes.dart';

// Entry point for starting the server
Future<void> runServer() async {
  // Load server configuration from environment variables
  final config = ServerConfig.fromEnv(const {});

  // Establish MySQL database connection
  final MySqlConnection conn = await openMySqlConnection(config);
  // Initialize database schema
  await ensureSchema(conn, dbName: config.dbName);

  // Create a new router instance for handling routes
  final router = Router();

  // Health check endpoint
  router.get('/health', (Request req) => Response.ok('OK'));

  // Mount authentication routes
  router.mount('/', authRoutes(conn, config));
  // Mount investment routes
  router.mount('/', investmentRoutes(conn, config));
  // Mount user/admin routes
  router.mount('/', userRoutes(conn, config));

  // Create middleware pipeline with logging and CORS support
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router);

  // Start server and listen on configured host and port
  final server = await io.serve(handler, config.host, config.port);
  print('Server listening on http://${server.address.host}:${server.port}');
}
