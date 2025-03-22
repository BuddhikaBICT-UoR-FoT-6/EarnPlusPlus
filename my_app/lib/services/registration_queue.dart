import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Represents a pending registration record stored locally on the device.
class PendingRegistration {
  final int? id;
  final String email;
  final String passwordKey; // secure storage key for the password
  final DateTime createdAt;
  final String status; // queued, sending, failed, done

  PendingRegistration({
    this.id,
    required this.email,
    required this.passwordKey,
    required this.createdAt,
    required this.status,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'email': email,
    'password_key': passwordKey,
    'created_at': createdAt.toIso8601String(),
    'status': status,
  };

  static PendingRegistration fromMap(Map<String, Object?> m) =>
      PendingRegistration(
        id: m['id'] as int?,
        email: m['email'] as String,
        passwordKey: m['password_key'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        status: m['status'] as String,
      );
}

/// Local SQLite database for managing pending registrations queued for retry.
class RegistrationDb {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'app_data.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE pending_registrations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL,
          password_key TEXT NOT NULL,
          created_at TEXT NOT NULL,
          status TEXT NOT NULL
        )
      ''');
      },
    );
    return _db!;
  }

  static Future<int> insertPending(PendingRegistration p) async {
    final db = await instance;
    return await db.insert('pending_registrations', p.toMap());
  }

  static Future<List<PendingRegistration>> getQueued() async {
    final db = await instance;
    final rows = await db.query(
      'pending_registrations',
      where: 'status = ?',
      whereArgs: ['queued'],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => PendingRegistration.fromMap(r)).toList();
  }

  static Future<void> updateStatus(int id, String status) async {
    final db = await instance;
    await db.update(
      'pending_registrations',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> delete(int id) async {
    final db = await instance;
    await db.delete('pending_registrations', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}

/// Service that manages queuing of registrations and syncing them when network is available.
class RegistrationQueueService {
  final String serverBase; // e.g. 'http://10.0.2.2:8080'
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  StreamSubscription<ConnectivityResult>? _sub;

  RegistrationQueueService(this.serverBase);

  /// Initialize the service: listen for connectivity changes and attempt flush at startup.
  Future<void> init() async {
    _sub = Connectivity().onConnectivityChanged.listen((_) {
      _flushQueueIfOnline();
    });
    // Also attempt to flush queued items at startup
    await Future.delayed(const Duration(milliseconds: 500));
    await _flushQueueIfOnline();
  }

  /// Clean up resources.
  Future<void> dispose() async {
    await _sub?.cancel();
  }

  /// Enqueue a registration (stores password securely; stores email+key in DB).
  Future<void> enqueue(String email, String password) async {
    final key = 'pending_pw_${DateTime.now().millisecondsSinceEpoch}';
    await _secure.write(key: key, value: password);
    final p = PendingRegistration(
      email: email,
      passwordKey: key,
      createdAt: DateTime.now(),
      status: 'queued',
    );
    await RegistrationDb.insertPending(p);
    // Try flush in case online
    await _flushQueueIfOnline();
  }

  /// Check connectivity and attempt to send all queued registrations if online.
  Future<void> _flushQueueIfOnline() async {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      return;
    }

    final items = await RegistrationDb.getQueued();
    for (final item in items) {
      await RegistrationDb.updateStatus(item.id!, 'sending');
      final password = await _secure.read(key: item.passwordKey);

      try {
        final resp = await http
            .post(
              Uri.parse('$serverBase/auth/register/send-otp'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': item.email, 'password': password}),
            )
            .timeout(const Duration(seconds: 10));

        if (resp.statusCode == 202 || resp.statusCode == 200) {
          await RegistrationDb.updateStatus(item.id!, 'done');
          await RegistrationDb.delete(item.id!);
          await _secure.delete(key: item.passwordKey);
        } else {
          await RegistrationDb.updateStatus(item.id!, 'failed');
        }
      } catch (e) {
        // Network error — revert to queued so it retries later
        await RegistrationDb.updateStatus(item.id!, 'queued');
      }
    }
  }

  /// Get the current list of queued registrations (for UI display).
  Future<List<PendingRegistration>> getQueuedItems() async {
    return await RegistrationDb.getQueued();
  }
}
