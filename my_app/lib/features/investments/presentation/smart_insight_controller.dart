import 'package:flutter/material.dart';

// The SmartInsightController handles only the NLP query state and logic,
// strictly separating it from the InvestmentController (CRUD operations)
// to satisfy the Single Responsibility Principle (SRP).
class SmartInsightController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _insights = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get insights => _insights;

  Future<void> askPortfolio(String query) async {
    if (query.trim().isEmpty) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mocking the delay for now. Will wire up to InsightRepository later.
      await Future.delayed(const Duration(seconds: 2));
      _insights = [
        {'tag': 'Steady Grower', 'description': 'Consistent growth observed.'}
      ];
    } catch (e) {
      _error = 'Failed to generate insights. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
