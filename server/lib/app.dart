import 'dart:io';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import 'src/config.dart';
import 'src/db/dev_seed.dart';
import 'src/db/mysql.dart';
import 'src/db/schema.dart';
import 'src/routes/auth_routes.dart';
import 'src/routes/investment_routes.dart';
import 'src/routes/user_routes.dart';
import 'src/routes/insight_routes.dart';
import 'src/routes/goal_routes.dart';
import 'src/routes/notification_routes.dart';
import 'src/routes/leaderboard_routes.dart';
import 'src/routes/ws_routes.dart';
import 'src/services/smart_insight_service.dart';
import 'src/domain/insight_generator.dart';
import 'src/db/mysql_investment_repository.dart';
import 'src/db/mysql_goal_repository.dart';
import 'src/db/mysql_notification_repository.dart';
import 'src/services/market_data_service.dart';
import 'src/services/notification_cron_service.dart';
import 'src/middleware/rate_limit_middleware.dart';

// Entry point for starting the server
Future<void> runServer() async {
  // Load server configuration from environment variables
  final config = ServerConfig.fromEnv(Platform.environment);

  // Establish MySQL database connection
  final MySqlConnection conn = await openMySqlConnection(config);
  // Initialize database schema
  await ensureSchema(conn, dbName: config.dbName);
  // Seed secret dev data at startup (idempotent for local development).
  await seedDevData(conn, config);

  // Create a new router instance for handling routes
  final router = Router();

  // Health check endpoint
  router.get('/health', (Request req) => Response.ok('OK'));

  // Mount authentication routes
  router.mount('/', authRoutes(conn, config));
  // Create InvestmentRepository and MarketDataService
  final investmentRepo = MySqlInvestmentRepository(conn, config.dbName);
  final marketDataService = MarketDataService();

  // Mount investment routes
  router.mount('/', investmentRoutes(investmentRepo, config, marketDataService));
  // Create GoalRepository and NotificationRepository
  final goalRepo = MySqlGoalRepository(conn, config.dbName);
  final notificationRepo = MySqlNotificationRepository(conn, config.dbName);

  // Mount goal routes
  router.mount('/', goalRoutes(goalRepo, config));
  
  // Mount notification routes
  router.mount('/', notificationRoutes(notificationRepo, config));

  // Mount leaderboard routes
  router.mount('/', leaderboardRoutes(conn, config));

  // Mount websocket routes
  router.mount('/', wsRoutes());

  // Mount user/admin routes
  router.mount('/', userRoutes(conn, config));
  // Initialize insight service with generators
  final insightService = SmartInsightService([
    RiskInsightGenerator(),
    GrowthInsightGenerator(),
    DiversificationInsightGenerator(),
  ]);

  // Mount insight routes
  router.mount('/', insightRoutes(conn, config, insightService));

  // Create middleware pipeline with logging, CORS support, and Rate Limiting
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(rateLimiter(maxRequests: 200, window: const Duration(minutes: 1)))
      .addHandler(router);

  // Start server and listen on configured host and port
  final server = await io.serve(handler, config.host, config.port);
  print('Server listening on http://${server.address.host}:${server.port}');

  // Start notification cron
  final cronService = NotificationCronService(notificationRepo);
  cronService.start();
}
