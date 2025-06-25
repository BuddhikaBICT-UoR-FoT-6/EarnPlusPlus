import 'package:mysql1/mysql1.dart';
import '../domain/notification_repository.dart';

class MySqlNotificationRepository implements NotificationRepository {
  final MySqlConnection _conn;
  final String _dbName;

  MySqlNotificationRepository(this._conn, this._dbName);

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications(int userId) async {
    final results = await _conn.query(
      'SELECT id, title, body, is_read, created_at '
      'FROM `$_dbName`.notifications WHERE user_id = ? ORDER BY created_at DESC',
      [userId],
    );
    return results.map((row) => row.fields).toList();
  }

  @override
  Future<int> markAsRead(int notificationId, int userId) async {
    final result = await _conn.query(
      'UPDATE `$_dbName`.notifications SET is_read = 1 WHERE id = ? AND user_id = ?',
      [notificationId, userId],
    );
    return result.affectedRows ?? 0;
  }

  @override
  Future<int> createNotification(int userId, String title, String body) async {
    final result = await _conn.query(
      'INSERT INTO `$_dbName`.notifications (user_id, title, body, is_read) VALUES (?, ?, ?, 0)',
      [userId, title, body],
    );
    return result.insertId ?? 0;
  }
}
