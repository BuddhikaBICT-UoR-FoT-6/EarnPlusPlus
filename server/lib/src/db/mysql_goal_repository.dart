import 'package:mysql1/mysql1.dart';
import '../domain/goal_repository.dart';

class MySqlGoalRepository implements GoalRepository {
  final MySqlConnection _conn;
  final String _dbName;

  MySqlGoalRepository(this._conn, this._dbName);

  @override
  Future<List<Map<String, dynamic>>> fetchGoals(int userId) async {
    final results = await _conn.query(
      'SELECT id, title, target_amount, current_amount, created_at '
      'FROM `$_dbName`.goals WHERE user_id = ? ORDER BY created_at DESC',
      [userId],
    );
    return results.map((row) => row.fields).toList();
  }

  @override
  Future<Map<String, dynamic>?> getGoalById(int id, int userId) async {
    final results = await _conn.query(
      'SELECT id, title, target_amount, current_amount, created_at '
      'FROM `$_dbName`.goals WHERE id = ? AND user_id = ?',
      [id, userId],
    );
    if (results.isEmpty) return null;
    return results.first.fields;
  }

  @override
  Future<int> createGoal(int userId, String title, double targetAmount, double currentAmount) async {
    final result = await _conn.query(
      'INSERT INTO `$_dbName`.goals (user_id, title, target_amount, current_amount) VALUES (?, ?, ?, ?)',
      [userId, title, targetAmount, currentAmount],
    );
    return result.insertId ?? 0;
  }

  @override
  Future<int> updateGoal(int id, int userId, String title, double targetAmount, double currentAmount) async {
    final result = await _conn.query(
      'UPDATE `$_dbName`.goals SET title = ?, target_amount = ?, current_amount = ? '
      'WHERE id = ? AND user_id = ?',
      [title, targetAmount, currentAmount, id, userId],
    );
    return result.affectedRows ?? 0;
  }

  @override
  Future<int> deleteGoal(int id, int userId) async {
    final result = await _conn.query(
      'DELETE FROM `$_dbName`.goals WHERE id = ? AND user_id = ?',
      [id, userId],
    );
    return result.affectedRows ?? 0;
  }
}
