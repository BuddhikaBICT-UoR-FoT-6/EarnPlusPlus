import 'package:decimal/decimal.dart'; // for handling decimal values with high
// precision, which is important for financial calculations
import 'package:flutter/material.dart'; // importing the Flutter material package
// components and widgets to use Material Design components and state management features

import '../data/investment_repository.dart';
import '../domain/investment.dart';

// defining an enum for different states of investment loading to manage the UI
// state based on the current status of data fetching and processing. The states
// include idle, loading, success, empty, error, and unauthorized, which can be
// used to display appropriate UI elements such as loading indicators, error messages,
// or the list of investments.
enum InvestmentLoadState { idle, loading, success, empty, error, unauthorized }

// the InvestmentController extends ChangeNotifier to manage the state of
// investment data and notify listeners when changes occur. It interacts with the
// InvestmentRepository to fetch, create, update, and delete investments. The
// controller tracks loading state, errors, and provides filtered and aggregated
// views of investments (by asset, total amount, average amount) for display in
// the UI. When state changes, it calls notifyListeners() to trigger UI rebuilds.
class InvestmentController extends ChangeNotifier {
  final InvestmentRepository _repository;

  // The constructor initializes the InvestmentRepository, allowing for dependency
  // injection. If no repository is provided, it creates a default instance of
  // InvestmentRepository. This design allows for easier testing and flexibility
  // in swapping out the data source if needed.
  InvestmentController({InvestmentRepository? repository})
    : _repository = repository ?? InvestmentRepository();

  InvestmentLoadState _state =
      InvestmentLoadState.idle; // initial state is idle,
  // indicating that no data fetching has started yet
  List<Investment> _investments =
      const []; // the list of investments is initialized
  // as an empty list, and it will be populated with data fetched from the repository
  // when the load method is called
  String selectedAsset = 'All'; // the selected asset for filtering investments,
  // initialized to 'All' to show all investments by default
  String? error; // a nullable string to hold any error messages that may occur
  // during data fetching
  bool isMutating = false;
  String? actionError;

  InvestmentLoadState get state => _state; // getter for the current load state,
  // which is useful for the UI to determine what to display based on the current
  // state allowing the UI to react to changes in the loading process and show
  // appropriate feedback to the user such as loading indicators, error messages,
  // or the list of investments
  List<Investment> get investments => _investments; // getter for the list of
  // investments, which can be used by the UI to display the fetched investment
  // data to the user. This allows the UI to access the investment data managed
  // by the controller and update the display accordingly when the data changes.

  // the filtered getter returns a list of investments based on the selected asset.
  // If the selected asset is 'All', it returns the full list of investments.
  List<Investment> get filtered => selectedAsset == 'All'
      ? _investments
      : _investments.where((i) => i.asset == selectedAsset).toList();

  // the totalInvested getter calculates the total amount invested by summing the
  // amounts of the filtered investments. It uses the fold method to iterate over
  // the filtered list and accumulate the total amount, starting from Decimal.zero.
  // This provides a precise total investment amount that can be displayed in the
  // UI or used for further calculations.
  Decimal get totalInvested =>
      filtered.fold(Decimal.zero, (prev, item) => prev + item.amount);

  // the averageInvested getter calculates the average amount invested by dividing the
  // total invested amount by the number of filtered investments. It checks if
  // the filtered list is empty to avoid division by zero, returning Decimal.zero
  // in that case. If there are investments, it performs the division and converts
  // the result to a string with 6 decimal places for precision before parsing it
  // back into a Decimal. This provides an accurate average investment amount that
  // can be displayed in the UI or used for further calculations.
  Decimal get averageInvested {
    if (filtered.isEmpty) return Decimal.zero;
    final avg = totalInvested.toDouble() / filtered.length;
    return Decimal.parse(avg.toStringAsFixed(6));
  }

  // the load method is responsible for fetching the investment data from the repository.
  // It updates the state to loading, clears any previous errors, and then attempts
  // to fetch the investments. Based on the result, it updates the state to success
  //, empty, unauthorized, or error, and it notifies listeners to update the UI accordingly.
  // This method handles the entire data fetching process, including error handling
  // and state management, to ensure that the UI can react to changes in the data and
  // provide feedback to the user.
  Future<void> load() async {
    _state = InvestmentLoadState.loading;
    error = null;
    actionError = null;
    notifyListeners(); // notifies listeners that the state has changed to loading,
    // allowing the UI to display a loading indicator while the data is being fetched

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

    notifyListeners(); // notifies listeners that the state has changed,
    // allowing the UI to update and display the fetched data, or an error message
    // if the data fetching failed, or to show an empty state if there are no
    // investments to display
  }

  // the addInvestment method creates a new investment record via the repository
  // and immediately adds it to the local list, sorting by date to maintain a
  // consistent display order. The isMutating flag is set to true during the operation,
  // allowing the UI to disable action buttons and prevent duplicate submissions.
  // If the operation fails, the error is captured and the UI is notified so users
  // see feedback about what went wrong.
  Future<bool> addInvestment({
    required DateTime date,
    required String asset,
    required String amount,
  }) async {
    isMutating = true;
    actionError = null;
    notifyListeners();

    try {
      final created = await _repository.createInvestment(
        date: date,
        asset: asset,
        amount: amount,
      );
      _investments = [..._investments, created]
        ..sort((a, b) => a.date.compareTo(b.date));
      _state = _investments.isEmpty
          ? InvestmentLoadState.empty
          : InvestmentLoadState.success;
      return true;
    } on InvestmentUnauthorizedException {
      _state = InvestmentLoadState.unauthorized;
      return false;
    } catch (e) {
      actionError = 'Failed to add investment: $e';
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  // the updateInvestment method sends a full update payload to the repository
  // and, on success, replaces the matching investment record in the local list
  // with the returned updated record. This keeps the UI state in sync with the
  // server without requiring a full list refetch, reducing network overhead and
  // latency. Sorting is reapplied to maintain chronological order if needed.
  Future<bool> updateInvestment({
    required int id,
    required DateTime date,
    required String asset,
    required String amount,
  }) async {
    isMutating = true;
    actionError = null;
    notifyListeners();

    try {
      final updated = await _repository.updateInvestment(
        id: id,
        date: date,
        asset: asset,
        amount: amount,
      );
      _investments =
          _investments.map((it) => it.id == id ? updated : it).toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      return true;
    } on InvestmentUnauthorizedException {
      _state = InvestmentLoadState.unauthorized;
      return false;
    } catch (e) {
      actionError = 'Failed to update investment: $e';
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  // the deleteInvestment method removes an investment record from the server
  // and, on success, removes the corresponding item from the local list. The
  // isMutating flag prevents UI race conditions, and the state is updated to
  // reflect whether investments remain (success) or all are gone (empty state).
  // This local-list update avoids an unnecessary refetch after deletion.
  Future<bool> deleteInvestment(int id) async {
    isMutating = true;
    actionError = null;
    notifyListeners();

    try {
      await _repository.deleteInvestment(id);
      _investments = _investments.where((it) => it.id != id).toList();
      _state = _investments.isEmpty
          ? InvestmentLoadState.empty
          : InvestmentLoadState.success;
      return true;
    } on InvestmentUnauthorizedException {
      _state = InvestmentLoadState.unauthorized;
      return false;
    } catch (e) {
      actionError = 'Failed to delete investment: $e';
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  // the setAsset method updates the selected asset for filtering investments and
  // notifies listeners to update the UI. This allows the user to select a specific
  // asset to filter the investments by, and the UI will automatically update to
  // show only the investments matching the selected asset.
  void setAsset(String value) {
    selectedAsset = value;
    notifyListeners(); // notifies listeners that the selected asset has changed,
    // allowing the UI to update and display the filtered list of investments based
    // on the new selection
  }

  // the assets method returns a list of unique asset names from the investments,
  // including an 'All' option for showing all investments. It uses a Set to
  // collect unique asset names, then converts it to a List and sorts it
  // alphabetically before returning. This provides a list of assets that can be
  // used in the UI for filtering the investments by asset type.
  List<String> assets() {
    final set = <String>{'All'};
    for (final i in _investments) {
      set.add(i.asset);
    }
    final list = set.toList()..sort();
    return list;
  }
}
