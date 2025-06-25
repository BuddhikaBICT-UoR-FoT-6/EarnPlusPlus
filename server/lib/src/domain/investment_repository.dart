abstract class InvestmentRepository {
  Future<List<Map<String, dynamic>>> fetchInvestments(int userId);
  Future<void> createInvestment(int userId, DateTime date, String asset, double amount);
  Future<int> updateInvestment(int id, int userId, DateTime date, String asset, double amount);
  Future<int> deleteInvestment(int id, int userId);
  Future<Map<String, dynamic>?> getInvestmentById(int id, int userId);
}
