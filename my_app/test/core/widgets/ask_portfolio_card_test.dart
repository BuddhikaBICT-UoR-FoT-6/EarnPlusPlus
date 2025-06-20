import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/widgets/ask_portfolio_card.dart';
import 'package:my_app/features/investments/presentation/smart_insight_controller.dart';

void main() {
  testWidgets('AskPortfolioCard renders search box and handles query', (WidgetTester tester) async {
    final controller = SmartInsightController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<SmartInsightController>.value(
            value: controller,
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
  });
}
