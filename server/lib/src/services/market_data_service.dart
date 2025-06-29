import 'dart:math';

class MarketDataService {
  final _random = Random();
  
  // Baseline prices for known assets
  final Map<String, double> _baselinePrices = {
    'BTC': 65000.0,
    'ETH': 3500.0,
    'AAPL': 180.0,
    'TSLA': 200.0,
    'GOOGL': 150.0,
  };

  /// Fetch live multipliers for a list of assets (e.g. 1.05 means +5%)
  Map<String, double> fetchLiveMultipliers(Set<String> assets) {
    final Map<String, double> multipliers = {};
    for (var asset in assets) {
      // Simulate up to 10% price fluctuation (-5% to +5%)
      final fluctuation = 1.0 + (_random.nextDouble() * 0.1 - 0.05);
      multipliers[asset] = double.parse(fluctuation.toStringAsFixed(4));
    }
    return multipliers;
  }
}
