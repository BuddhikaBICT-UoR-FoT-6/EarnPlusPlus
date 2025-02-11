import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../data/investment_repository.dart';
import '../domain/investment.dart';

enum InvestmentLoadState { idle, loading, success, empty, error, unauthorized }

class InvestmentController extends ChangeNotifier {
  final InvestmentRepository _repository;

  InvestmentController({InvestmentRepository? repository})
      : _repository = repository ?? InvestmentRepository();

  InvestmentLoadState _state = InvestmentLoadState.idle;
  List<Investment> _investments = const [];
  String selectedAsset = 'All';
  String? error;

  InvestmentLoadState get state => _state;
  List<Investment> get investments => _investments;

  List<Investment> get filtered => selectedAsset == 'All'
      ? _investments
      : _investments.where((i) => i.asset == selectedAsset).toList();

  Decimal get totalInvested => filtered.fold(
        Decimal.zero,
        (prev, item) => prev + item.amount,
      );

  Decimal get averageInvested {
    if (filtered.isEmpty) return Decimal.zero;
    final avg = totalInvested.toDouble() / filtered.length;
    return Decimal.parse(avg.toStringAsFixed(6));
  }

  Future<void> load() async {
    _state = InvestmentLoadState.loading;
    error = null;
    notifyListeners();

    try {
      _investments = await _repository.fetchInvestments();
      _state = _investments.isEmpty
          ? InvestmentLoadState.empty
          : InvestmentLoadState.success;
    } on InvestmentUnauthorizedException {
      _state = InvestmentLoadState.unauthorized;
    } catch (e) {
      error = 'Failed to fetch investments: $e';
      _state = InvestmentLoadState.error;
    }

    notifyListeners();
  }

  void setAsset(String value) {
    selectedAsset = value;
    notifyListeners();
  }

  List<String> assets() {
    final set = <String>{'All'};
    for (final i in _investments) {
      set.add(i.asset);
    }
    final list = set.toList()..sort();
    return list;
  }
}
