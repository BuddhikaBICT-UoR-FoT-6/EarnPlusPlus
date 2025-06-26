import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/widgets/ask_portfolio_card.dart';
import 'package:my_app/features/investments/presentation/smart_insight_controller.dart';

import 'package:my_app/features/investments/presentation/investment_controller.dart';
import 'package:my_app/features/investments/data/in_memory_investment_repository.dart';

void main() {
  testWidgets('AskPortfolioCard renders search box and handles query', (WidgetTester tester) async {
    final controller = SmartInsightController();
    final invController = InvestmentController(repository: InMemoryInvestmentRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<SmartInsightController>.value(value: controller),
              ChangeNotifierProvider<InvestmentController>.value(value: invController),
            ],
            child: const AskPortfolioCard(),
          ),
        ),
      ),
    );

    expect(find.text('Ask Your Portfolio'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    
    // Check Hick's law pre-defined actions
    expect(find.text('What is my top gainer?'), findsOneWidget);

    // Enter a query
    await tester.enterText(find.byType(TextField), 'Test query');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(); // Start animation

    // Should be loading
    expect(controller.isLoading, isTrue);

    // Wait for the mock Future.delayed to finish to prevent pending timer error
    // We use pump instead of pumpAndSettle because AskPortfolioCard has a repeating background animation
    await tester.pump(const Duration(seconds: 3));
    expect(controller.isLoading, isFalse);
  });
}
