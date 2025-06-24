import 'package:mysql1/mysql1.dart';
import '../domain/investment_repository.dart';

class MySqlInvestmentRepository implements InvestmentRepository {
  final MySqlConnection conn;
  final String dbName;

  MySqlInvestmentRepository(this.conn, this.dbName);

  @override
  Future<List<Map<String, dynamic>>> fetchInvestments(int userId) async {
    await conn.query('USE $dbName');
    final results = await conn.query(
      'SELECT id, date, asset, amount FROM investments WHERE user_id = ? ORDER BY date ASC, id ASC',
      [userId],
    );
    return results.map((row) => {
      'id': row['id'] as int,
      'date': (row['date'] as DateTime).toIso8601String().split('T').first,
      'asset': row['asset'] as String,
      'amount': (row['amount'] as num).toDouble(),
    }).toList();
  }

  @override
  Future<void> createInvestment(int userId, DateTime date, String asset, double amount) async {
    await conn.query('USE $dbName');
    await conn.query(
      'INSERT INTO investments (user_id, date, asset, amount) VALUES (?, ?, ?, ?)',
      [userId, date, asset, amount],
    );
  }

  @override
  Future<int> updateInvestment(int id, int userId, DateTime date, String asset, double amount) async {
    await conn.query('USE $dbName');
    final result = await conn.query(
      'UPDATE investments SET date = ?, asset = ?, amount = ? WHERE id = ? AND user_id = ?',
      [date, asset, amount, id, userId],
    );
    return result.affectedRows ?? 0;
  }

  @override
  Future<int> deleteInvestment(int id, int userId) async {
    await conn.query('USE $dbName');
    final result = await conn.query(
      'DELETE FROM investments WHERE id = ? AND user_id = ?',
      [id, userId],
    );
    return result.affectedRows ?? 0;
  }

  @override
  Future<Map<String, dynamic>?> getInvestmentById(int id, int userId) async {
    await conn.query('USE $dbName');
    final rows = await conn.query(
      'SELECT id, date, asset, amount FROM investments WHERE id = ? AND user_id = ? LIMIT 1',
      [id, userId],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return {
      'id': row['id'] as int,
      'date': (row['date'] as DateTime).toIso8601String().split('T').first,
      'asset': row['asset'] as String,
      'amount': (row['amount'] as num).toDouble(),
    };
  }
}
