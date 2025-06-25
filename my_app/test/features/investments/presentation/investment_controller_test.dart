import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/investments/domain/investment_repository.dart';
import 'package:my_app/features/investments/data/investment_repository.dart'; // For exceptions
import 'package:my_app/features/investments/domain/investment_summary_dto.dart';
import 'package:my_app/features/investments/domain/investment_detail_dto.dart';
import 'package:my_app/features/investments/presentation/investment_controller.dart';

class _FakeRepository implements InvestmentRepository {
  _FakeRepository({
    required List<InvestmentSummaryDto> result,
    this.created,
    this.updated,
    this.throwUnauthorized = false,
    this.throwOnMutation = false,
  }) : _result = result;

  final List<InvestmentSummaryDto> _result;
  final bool throwUnauthorized;
  final bool throwOnMutation;
  final InvestmentDetailDto? created;
  final InvestmentDetailDto? updated;

  @override
  Future<List<InvestmentSummaryDto>> fetchInvestments() async {
    if (throwUnauthorized) {
      throw const InvestmentUnauthorizedException();
    }
    return _result;
  }

  @override
  Future<InvestmentDetailDto> createInvestment({
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
        InvestmentDetailDto(
          id: 99,
          name: asset,
          currentValue: double.parse(amount),
          date: date.toIso8601String(),
        );
  }

  @override
  Future<InvestmentDetailDto> updateInvestment({
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
        InvestmentDetailDto(
          id: id,
          name: asset,
          currentValue: double.parse(amount),
          date: date.toIso8601String(),
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

  @override
  Future<InvestmentDetailDto> fetchInvestmentById(int id) async {
    return created ?? InvestmentDetailDto(
      id: id,
      name: 'Default',
      currentValue: 0.0,
      date: DateTime.now().toIso8601String(),
    );
  }
}

void main() {
  test('load success updates state and totals', () async {
    final controller = InvestmentController(
      repository: _FakeRepository(
        result: [
          InvestmentSummaryDto(
            id: 1,
            name: 'AAPL',
            currentValue: 10.25,
            plPercent: 0,
            insightTags: [],
          ),
          InvestmentSummaryDto(
            id: 2,
            name: 'AAPL',
            currentValue: 5.75,
            plPercent: 0,
            insightTags: [],
          ),
        ],
      ),
    );

    await controller.load();

    expect(controller.state, InvestmentLoadState.success);
    expect(controller.investments.length, 2);
    expect(controller.totalInvested, 16.0);
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
          InvestmentSummaryDto(
            id: 2,
            name: 'AAPL',
            currentValue: 10.00,
            plPercent: 0,
            insightTags: [],
          ),
        ],
        created: InvestmentDetailDto(
          id: 1,
          name: 'MSFT',
          currentValue: 20.0,
          date: DateTime(2025, 2, 3).toIso8601String(),
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
    final original = InvestmentSummaryDto(
      id: 7,
      name: 'AAPL',
      currentValue: 10.00,
      plPercent: 0,
      insightTags: [],
    );
    final updated = InvestmentDetailDto(
      id: 7,
      name: 'AAPL',
      currentValue: 11.0,
      date: DateTime(2025, 2, 1).toIso8601String(),
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
    expect(controller.investments.first.currentValue, 11.0);
  });

  test('deleteInvestment removes matching item on success', () async {
    final controller = InvestmentController(
      repository: _FakeRepository(
        result: [
          InvestmentSummaryDto(
            id: 4,
            name: 'AAPL',
            currentValue: 10.00,
            plPercent: 0,
            insightTags: [],
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
