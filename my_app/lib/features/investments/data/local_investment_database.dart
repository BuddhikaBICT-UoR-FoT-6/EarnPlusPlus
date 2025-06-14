import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../domain/investment_summary_dto.dart';

class LocalInvestmentDatabase {
  static const String _dbName = 'investments_cache.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE investments_cache (
            id INTEGER PRIMARY KEY,
            user_id INTEGER NOT NULL,
            asset_name TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            risk_level TEXT NOT NULL,
            category TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> cacheInvestments(List<InvestmentSummaryDto> investments) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('investments_cache');
      for (final inv in investments) {
        await txn.insert('investments_cache', {
          'id': inv.id,
          'user_id': inv.userId,
          'asset_name': inv.assetName,
          'amount': inv.amount,
          'date': inv.date,
          'risk_level': inv.riskLevel,
          'category': inv.category,
        });
      }
    });
  }

  Future<List<InvestmentSummaryDto>> getCachedInvestments() async {
    final db = await database;
    final maps = await db.query('investments_cache');

    return maps.map((map) {
      return InvestmentSummaryDto(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        assetName: map['asset_name'] as String,
        amount: map['amount'] as double,
        date: map['date'] as String,
        riskLevel: map['risk_level'] as String,
        category: map['category'] as String,
      );
    }).toList();
  }
}
