import 'goal_dto.dart';

abstract class GoalRepository {
  Future<List<GoalDto>> fetchGoals();
  Future<GoalDto> createGoal({required String title, required double targetAmount, required double currentAmount});
  Future<GoalDto> updateGoal({required int id, required String title, required double targetAmount, required double currentAmount});
  Future<void> deleteGoal(int id);
}
