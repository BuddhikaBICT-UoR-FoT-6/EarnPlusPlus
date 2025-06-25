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
            name TEXT NOT NULL,
            currentValue REAL NOT NULL,
            plPercent REAL NOT NULL,
            insightTags TEXT NOT NULL
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
          'name': inv.name,
          'currentValue': inv.currentValue,
          'plPercent': inv.plPercent,
          'insightTags': inv.insightTags.join(','),
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
        name: map['name'] as String,
        currentValue: map['currentValue'] as double,
        plPercent: map['plPercent'] as double,
        insightTags: (map['insightTags'] as String).split(',').where((s) => s.isNotEmpty).toList(),
      );
    }).toList();
  }
}
