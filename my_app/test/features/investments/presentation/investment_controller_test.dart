import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/investments/data/investment_repository.dart';
import 'package:my_app/features/investments/domain/investment.dart';
import 'package:my_app/features/investments/presentation/investment_controller.dart';
import 'package:decimal/decimal.dart';

class _FakeRepository extends InvestmentRepository {
  _FakeRepository(this._result, {this.throwUnauthorized = false});

  final List<Investment> _result;
  final bool throwUnauthorized;

  @override
  Future<List<Investment>> fetchInvestments() async {
    if (throwUnauthorized) {
      throw const InvestmentUnauthorizedException();
    }
    return _result;
  }
}

void main() {
  test('load success updates state and totals', () async {
    final controller = InvestmentController(
      repository: _FakeRepository([
        Investment(
          date: DateTime(2025, 2, 1),
          asset: 'AAPL',
          amount: Decimal.parse('10.25'),
        ),
        Investment(
          date: DateTime(2025, 2, 2),
          asset: 'AAPL',
          amount: Decimal.parse('5.75'),
        ),
      ]),
    );

    await controller.load();

    expect(controller.state, InvestmentLoadState.success);
    expect(controller.investments.length, 2);
    expect(controller.totalInvested, Decimal.parse('16.00'));
  });

  test('load unauthorized updates state', () async {
    final controller = InvestmentController(
      repository: _FakeRepository(const [], throwUnauthorized: true),
    );

    await controller.load();

    expect(controller.state, InvestmentLoadState.unauthorized);
  });
}
