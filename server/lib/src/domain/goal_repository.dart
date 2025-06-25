abstract class GoalRepository {
  Future<List<Map<String, dynamic>>> fetchGoals(int userId);
  Future<Map<String, dynamic>?> getGoalById(int id, int userId);
  Future<int> createGoal(int userId, String title, double targetAmount, double currentAmount);
  Future<int> updateGoal(int id, int userId, String title, double targetAmount, double currentAmount);
  Future<int> deleteGoal(int id, int userId);
}
