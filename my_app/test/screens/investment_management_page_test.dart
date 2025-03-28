import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/investments/data/investment_repository.dart';
import 'package:my_app/features/investments/domain/investment.dart';
import 'package:my_app/features/investments/presentation/investment_controller.dart';
import 'package:my_app/screens/investment_management_page.dart';

class _FakeInvestmentRepository extends InvestmentRepository {
  // this fake repository returns a fixed set of investments without making
  // network requests, isolating the widget test from transport and authentication
  // concerns. The deterministic data (a single AAPL stock investment from March 2)
  // allows test assertions to verify that the investment list renders correctly,
  // buttons appear, and the UI responds to controller state changes.
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
    // the test initializes the controller with the fake repository and calls
    // load() to populate the investment list before pumping the widget. This
    // ensures the widget renders with real data loaded, allowing assertions to
    // verify that the list displays investments, the add button appears, and edit/delete
    // icons are present without having to simulate the async loading flow.
    final controller = InvestmentController(
      repository: _FakeInvestmentRepository(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(home: InvestmentManagementPage(controller: controller)),
    );

    await tester.pumpAndSettle();

    expect(find.text('Manage Investments'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
