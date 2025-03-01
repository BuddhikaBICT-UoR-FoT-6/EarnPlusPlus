import 'package:flutter_test/flutter_test.dart'; // imports the Flutter testing
//framework, which provides tools for writing unit tests
import 'package:my_app/features/investments/data/investment_repository.dart';
import 'package:my_app/features/investments/domain/investment.dart';
import 'package:my_app/features/investments/presentation/investment_controller.dart';
import 'package:decimal/decimal.dart';

// A fake implementation of the InvestmentRepository interface that returns
// predefined data or throws exceptions for testing purposes. This allows us to
// test the InvestmentController's behavior in different scenarios without relying
// on actual repository implementations.
class _FakeRepository extends InvestmentRepository {
  _FakeRepository(
    this._result, {
    this.throwUnauthorized = false,
  }); // The _FakeRepository
  // class has a constructor that takes a list of Investment objects as a result to return
  // and an optional boolean parameter to indicate whether to throw an unauthorized exception,
  // allowing for flexible testing of different scenarios in the InvestmentController.

  final List<Investment> _result; // a list of Investment objects that will be
  // returned when fetchInvestments is called on this fake repository, allowing
  // us to simulate successful data fetching scenarios in our tests

  final bool throwUnauthorized; // a boolean flag that indicates whether the
  // fetchInvestments method should throw an unauthorized exception, allowing us
  // to simulate unauthorized access scenarios in our tests and verify that the
  // InvestmentController handles such cases correctly

  // the fetchInvestments method is overridden to return the predefined result or
  // throw an unauthorized exception based on the throwUnauthorized flag, allowing
  // us to test both successful and failed data fetching scenarios in the InvestmentController
  // if throwUnauthorized is true, it throws an InvestmentUnauthorizedException;
  // otherwise, it returns the predefined list of investments. This design allows
  // us to test how the InvestmentController handles both successful data retrieval
  // and unauthorized access situations.
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
    // the test case for loading investments successfully creates an instance of
    // the InvestmentController with a _FakeRepository that returns a predefined
    // list of investments. It then calls the load method on the controller and
    // verifies that the state is updated to success, the number of investments
    // is correct, and the total invested amount is calculated accurately, ensuring
    // that the InvestmentController behaves as expected when data is fetched
    // successfully from the repository.
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

    await controller.load(); // calls the load method on the controller to fetch
    // investments from the fake repository

    expect(controller.state, InvestmentLoadState.success); // verifies that the
    // state of the controller is updated to success after loading the investments
    expect(
      controller.investments.length,
      2,
    ); // checks that the number of investments
    // loaded is correct
    expect(
      controller.totalInvested,
      Decimal.parse('16.00'),
    ); // verifies that the
    // total invested amount is calculated correctly as the sum of the amounts of
    // the loaded investments
  });

  test('load unauthorized updates state', () async {
    // the test case for unauthorized loading creates an instance of the
    // InvestmentController with a _FakeRepository that is configured to throw an
    // InvestmentUnauthorizedException when fetchInvestments is called. It then calls
    // the load method on the controller and verifies that the state is updated to
    // unauthorized, ensuring that the InvestmentController correctly handles
    // unauthorized access scenarios and updates its state accordingly when the
    // repository throws an unauthorized exception.
    final controller = InvestmentController(
      repository: _FakeRepository(const [], throwUnauthorized: true),
    );

    await controller.load();

    expect(controller.state, InvestmentLoadState.unauthorized);
  });
}
