import '../domain/investment_repository.dart';

class InMemoryInvestmentRepository implements InvestmentRepository {
  final List<Map<String, dynamic>> _data = [];
  int _nextId = 1;

  @override
  Future<List<Map<String, dynamic>>> fetchInvestments(int userId) async {
    final userInvestments = _data.where((item) => item['user_id'] == userId).toList();
    userInvestments.sort((a, b) {
      final dateA = DateTime.parse(a['date']);
      final dateB = DateTime.parse(b['date']);
      final dateCompare = dateA.compareTo(dateB);
      if (dateCompare != 0) return dateCompare;
      return (a['id'] as int).compareTo(b['id'] as int);
    });
    return userInvestments.map((item) => {
      'id': item['id'],
      'date': item['date'],
      'asset': item['asset'],
      'amount': item['amount'],
    }).toList();
  }

  @override
  Future<void> createInvestment(int userId, DateTime date, String asset, double amount) async {
    _data.add({
      'id': _nextId++,
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'asset': asset,
      'amount': amount,
    });
  }

  @override
  Future<int> updateInvestment(int id, int userId, DateTime date, String asset, double amount) async {
    final index = _data.indexWhere((item) => item['id'] == id && item['user_id'] == userId);
    if (index == -1) return 0;
    _data[index] = {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'asset': asset,
      'amount': amount,
    };
    return 1;
  }

  @override
  Future<int> deleteInvestment(int id, int userId) async {
    final initialLength = _data.length;
    _data.removeWhere((item) => item['id'] == id && item['user_id'] == userId);
    return initialLength - _data.length;
  }

  @override
  Future<Map<String, dynamic>?> getInvestmentById(int id, int userId) async {
    try {
      final item = _data.firstWhere((item) => item['id'] == id && item['user_id'] == userId);
      return {
        'id': item['id'],
        'date': item['date'],
        'asset': item['asset'],
        'amount': item['amount'],
      };
    } catch (_) {
      return null;
    }
  }
}
