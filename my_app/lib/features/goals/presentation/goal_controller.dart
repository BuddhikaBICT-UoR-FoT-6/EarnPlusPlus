import 'package:flutter/foundation.dart';
import '../data/api_goal_repository.dart';
import '../domain/goal_dto.dart';
import '../domain/goal_repository.dart';

enum GoalLoadState { initial, loading, success, empty, error, unauthorized }

class GoalController extends ChangeNotifier {
  final GoalRepository _repository;

  List<GoalDto> _goals = [];
  GoalLoadState _state = GoalLoadState.initial;
  String? error;
  String? actionError;
  bool isMutating = false;

  GoalController({GoalRepository? repository})
      : _repository = repository ?? ApiGoalRepository();

  List<GoalDto> get goals => List.unmodifiable(_goals);
  GoalLoadState get state => _state;

  Future<void> load() async {
    _state = GoalLoadState.loading;
    error = null;
    notifyListeners();

    try {
      _goals = await _repository.fetchGoals();
      _state = _goals.isEmpty ? GoalLoadState.empty : GoalLoadState.success;
    } on GoalUnauthorizedException {
      _state = GoalLoadState.unauthorized;
    } catch (e) {
      error = e.toString();
      _state = GoalLoadState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> addGoal({
    required String title,
    required double targetAmount,
    required double currentAmount,
  }) async {
    isMutating = true;
    actionError = null;
    notifyListeners();

    try {
      final newGoal = await _repository.createGoal(
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
      );
      _goals = [newGoal, ..._goals];
      _state = GoalLoadState.success;
      return true;
    } on GoalUnauthorizedException {
      _state = GoalLoadState.unauthorized;
      return false;
    } catch (e) {
      actionError = e.toString();
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> updateGoal({
    required int id,
    required String title,
    required double targetAmount,
    required double currentAmount,
  }) async {
    isMutating = true;
    actionError = null;
    notifyListeners();

    try {
      final updated = await _repository.updateGoal(
        id: id,
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
      );
      final idx = _goals.indexWhere((g) => g.id == id);
      if (idx != -1) {
        final list = List<GoalDto>.from(_goals);
        list[idx] = updated;
        _goals = list;
      }
      return true;
    } on GoalUnauthorizedException {
      _state = GoalLoadState.unauthorized;
      return false;
    } catch (e) {
      actionError = e.toString();
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGoal(int id) async {
    isMutating = true;
    actionError = null;
    notifyListeners();

    try {
      await _repository.deleteGoal(id);
      _goals = _goals.where((g) => g.id != id).toList();
      if (_goals.isEmpty) {
        _state = GoalLoadState.empty;
      }
      return true;
    } on GoalUnauthorizedException {
      _state = GoalLoadState.unauthorized;
      return false;
    } catch (e) {
      actionError = e.toString();
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }
}
