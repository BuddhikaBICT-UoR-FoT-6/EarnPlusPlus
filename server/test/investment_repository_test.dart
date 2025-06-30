import 'package:test/test.dart';
import '../lib/src/domain/investment_repository.dart';
import '../lib/src/db/in_memory_investment_repository.dart';

void runSharedTests(InvestmentRepository Function() createRepo) {
  group('InvestmentRepository Shared Tests', () {
    late InvestmentRepository repo;

    setUp(() {
      repo = createRepo();
    });

    test('create and fetch investments', () async {
      await repo.createInvestment(1, DateTime(2023, 1, 1), 'Stock A', 1000.0);
      final results = await repo.fetchInvestments(1);
      expect(results.length, 1);
      expect(results.first['asset'], 'Stock A');
    });

    test('update investment', () async {
      await repo.createInvestment(1, DateTime(2023, 1, 1), 'Stock A', 1000.0);
      final initial = await repo.fetchInvestments(1);
      final id = initial.first['id'];
      
      final updated = await repo.updateInvestment(id, 1, DateTime(2023, 1, 1), 'Stock A', 2000.0);
      expect(updated, 1);
      
      final afterUpdate = await repo.fetchInvestments(1);
      expect(afterUpdate.first['amount'], 2000.0);
    });

    test('delete investment', () async {
      await repo.createInvestment(1, DateTime(2023, 1, 1), 'Stock A', 1000.0);
      final initial = await repo.fetchInvestments(1);
      final id = initial.first['id'];
      
      final deleted = await repo.deleteInvestment(id, 1);
      expect(deleted, 1);
      
      final afterDelete = await repo.fetchInvestments(1);
      expect(afterDelete.isEmpty, true);
    });
  });
}

void main() {
  runSharedTests(() => InMemoryInvestmentRepository());
  // MySqlInvestmentRepository would be tested here as well, requiring a test db.
}
