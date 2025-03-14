import 'package:flutter_test/flutter_test.dart'; // imports the Flutter testing
//framework, which provides tools for writing unit tests
import 'package:my_app/features/investments/data/investment_repository.dart';
import 'package:my_app/features/investments/domain/investment.dart';
import 'package:my_app/features/investments/presentation/investment_controller.dart';
import 'package:decimal/decimal.dart';

class _FakeRepository extends InvestmentRepository {
  _FakeRepository({
    required List<Investment> result,
    this.created,
    this.updated,
    this.throwUnauthorized = false,
    this.throwOnMutation = false,
  }) : _result = result;

  final List<Investment> _result;
  final bool throwUnauthorized;
  final bool throwOnMutation;
  final Investment? created;
  final Investment? updated;

  @override
  Future<List<Investment>> fetchInvestments() async {
    if (throwUnauthorized) {
      throw const InvestmentUnauthorizedException();
    }
    return _result;
  }

  @override
  Future<Investment> createInvestment({
    required DateTime date,
    required String asset,
    required String amount,
  }) async {
    if (throwUnauthorized) {
      throw const InvestmentUnauthorizedException();
    }
    if (throwOnMutation) {
      throw const InvestmentApiException('mutation failed');
    }
    return created ??
        Investment(
          id: 99,
          date: date,
          asset: asset,
          amount: Decimal.parse(amount),
        );
  }

  @override
  Future<Investment> updateInvestment({
    required int id,
    required DateTime date,
    required String asset,
    required String amount,
  }) async {
    if (throwUnauthorized) {
      throw const InvestmentUnauthorizedException();
    }
    if (throwOnMutation) {
      throw const InvestmentApiException('mutation failed');
    }
    return updated ??
        Investment(
          id: id,
          date: date,
          asset: asset,
          amount: Decimal.parse(amount),
        );
  }

  @override
  Future<void> deleteInvestment(int id) async {
    if (throwUnauthorized) {
      throw const InvestmentUnauthorizedException();
    }
    if (throwOnMutation) {
      throw const InvestmentApiException('mutation failed');
    }
  }
}

void main() {
  test('load success updates state and totals', () async {
    final controller = InvestmentController(
      repository: _FakeRepository(
        result: [
          Investment(
            id: 1,
            date: DateTime(2025, 2, 1),
            asset: 'AAPL',
            amount: Decimal.parse('10.25'),
          ),
          Investment(
            id: 2,
            date: DateTime(2025, 2, 2),
            asset: 'AAPL',
            amount: Decimal.parse('5.75'),
          ),
        ],
      ),
    );

    await controller.load();

    expect(controller.state, InvestmentLoadState.success);
    expect(controller.investments.length, 2);
    expect(controller.totalInvested, Decimal.parse('16.00'));
  });

  test('load unauthorized updates state', () async {
    final controller = InvestmentController(
      repository: _FakeRepository(result: const [], throwUnauthorized: true),
    );

    await controller.load();

    expect(controller.state, InvestmentLoadState.unauthorized);
  });

  test('addInvestment appends record on success', () async {
    final controller = InvestmentController(
      repository: _FakeRepository(
        result: [
          Investment(
            id: 2,
            date: DateTime(2025, 2, 1),
            asset: 'AAPL',
            amount: Decimal.parse('10.00'),
          ),
        ],
        created: Investment(
          id: 1,
          date: DateTime(2025, 2, 3),
          asset: 'MSFT',
          amount: Decimal.parse('20.00'),
        ),
      ),
    );

    await controller.load();
    final ok = await controller.addInvestment(
      date: DateTime(2025, 2, 3),
      asset: 'MSFT',
      amount: '20.00',
    );

    expect(ok, isTrue);
    expect(controller.investments.length, 2);
    expect(controller.state, InvestmentLoadState.success);
  });

  test('updateInvestment replaces matching item on success', () async {
    final original = Investment(
      id: 7,
      date: DateTime(2025, 2, 1),
      asset: 'AAPL',
      amount: Decimal.parse('10.00'),
    );
    final updated = Investment(
      id: 7,
      date: DateTime(2025, 2, 1),
      asset: 'AAPL',
      amount: Decimal.parse('11.00'),
    );

    final controller = InvestmentController(
      repository: _FakeRepository(result: [original], updated: updated),
    );

    await controller.load();
    final ok = await controller.updateInvestment(
      id: 7,
      date: DateTime(2025, 2, 1),
      asset: 'AAPL',
      amount: '11.00',
    );

    expect(ok, isTrue);
    expect(controller.investments.first.amount, Decimal.parse('11.00'));
  });

  test('deleteInvestment removes matching item on success', () async {
    final controller = InvestmentController(
      repository: _FakeRepository(
        result: [
          Investment(
            id: 4,
            date: DateTime(2025, 2, 1),
            asset: 'AAPL',
            amount: Decimal.parse('10.00'),
          ),
        ],
      ),
    );

    await controller.load();
    final ok = await controller.deleteInvestment(4);

    expect(ok, isTrue);
    expect(controller.investments, isEmpty);
    expect(controller.state, InvestmentLoadState.empty);
  });

  test('mutation error sets actionError', () async {
    final controller = InvestmentController(
      repository: _FakeRepository(result: const [], throwOnMutation: true),
    );

    await controller.load();
    final ok = await controller.addInvestment(
      date: DateTime(2025, 2, 1),
      asset: 'AAPL',
      amount: '10.00',
    );

    expect(ok, isFalse);
    expect(controller.actionError, contains('Failed to add investment'));
  });
}
