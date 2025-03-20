import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/investments/data/investment_repository.dart';
import 'package:my_app/features/investments/domain/investment.dart';
import 'package:my_app/features/investments/presentation/investment_controller.dart';
import 'package:my_app/screens/investment_management_page.dart';

class _FakeInvestmentRepository extends InvestmentRepository {
  @override
  Future<List<Investment>> fetchInvestments() async {
    return [
      Investment(
        id: 1,
        date: DateTime(2025, 3, 2),
        asset: 'AAPL',
        amount: Decimal.parse('100.00'),
      ),
    ];
  }
}

void main() {
  testWidgets('renders investment management list', (tester) async {
    final controller = InvestmentController(
      repository: _FakeInvestmentRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: InvestmentManagementPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Manage Investments'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
