import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/investments/domain/investment_repository.dart';
import 'package:my_app/features/investments/domain/investment_summary_dto.dart';
import 'package:my_app/features/investments/domain/investment_detail_dto.dart';
import 'package:my_app/features/investments/presentation/investment_controller.dart';
import 'package:my_app/screens/investment_management_page.dart';

class _FakeInvestmentRepository implements InvestmentRepository {
  @override
  Future<List<InvestmentSummaryDto>> fetchInvestments() async {
    return [
      InvestmentSummaryDto(
        id: 1,
        name: 'AAPL',
        currentValue: 100.00,
        plPercent: 0,
        insightTags: [],
      ),
    ];
  }

  @override
  Future<InvestmentDetailDto> createInvestment({
    required DateTime date,
    required String asset,
    required String amount,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<InvestmentDetailDto> updateInvestment({
    required int id,
    required DateTime date,
    required String asset,
    required String amount,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteInvestment(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<InvestmentDetailDto> fetchInvestmentById(int id) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('renders investment management list', (tester) async {
    final controller = InvestmentController(
      repository: _FakeInvestmentRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: InvestmentManagementPage(controller: controller)),
    );

    // Pump to trigger build
    await tester.pump();
    // Pump enough time to allow animations (AnimatedSlideIn, AnimatedFadeIn) to complete
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('Manage Investments'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
