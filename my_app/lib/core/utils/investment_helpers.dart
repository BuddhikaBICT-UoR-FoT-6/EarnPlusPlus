import 'package:intl/intl.dart'; // for formatting currency

// Format a number as USD currency with dollar sign
String formatCurrency(double amount) {
  return NumberFormat.simpleCurrency(locale: 'en_US').format(amount);
}

// Format a number with 2 decimal places and dollar sign
String formatDollar(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
}

// Convert user-friendly error message from backend validation
String humanizeErrorMessage(String error) {
  // Parse error messages from backend and make them user-friendly
  if (error.contains('date is required')) {
    return 'Please enter a date for your investment.';
  }
  if (error.contains('Invalid date') || error.contains('date')) {
    return 'The date format is not recognized. Please use YYYY-MM-DD (e.g., 2025-01-15).';
  }
  if (error.contains('asset is required')) {
    return 'Please enter the stock symbol or asset name (e.g., AAPL, MSFT).';
  }
  if (error.contains('asset')) {
    return 'Please check your stock symbol and try again.';
  }
  if (error.contains('amount must be a positive number') ||
      error.contains('amount')) {
    return 'Please enter a valid investment amount (must be greater than zero).';
  }
  if (error.contains('No internet connection')) {
    return 'You are offline. Please check your internet connection and try again.';
  }
  if (error.contains('Connection timeout')) {
    return 'The server is taking too long to respond. Please check your connection or try again later.';
  }
  if (error.contains('Unable to reach the server')) {
    return 'Cannot reach the server. Please check your internet connection.';
  }
  if (error.contains('Unauthorized')) {
    return 'Your session has expired. Please log in again.';
  }
  if (error.contains('not found')) {
    return 'This investment record was not found. It may have been deleted.';
  }
  if (error.contains('Server error') || error.contains('500')) {
    return 'The server encountered an error. Please try again later.';
  }
  // Default: return the error as-is if we don't have a mapping
  return error;
}

// Calculate profit/loss between purchase and current value
Map<String, double> calculateProfitLoss(
  double purchaseAmount,
  double currentAmount,
) {
  final profitLoss = currentAmount - purchaseAmount;
  final percentChange = purchaseAmount != 0
      ? (profitLoss / purchaseAmount) * 100
      : 0.0;

  return {'profit_loss': profitLoss, 'percent_change': percentChange};
}

// Format profit/loss for display
String formatProfitLoss(double profitLoss) {
  if (profitLoss >= 0) {
    return '+${formatDollar(profitLoss)}';
  } else {
    return formatDollar(profitLoss);
  }
}

// Format percentage change for display
String formatPercentChange(double percent) {
  if (percent >= 0) {
    return '+${percent.toStringAsFixed(2)}%';
  } else {
    return '${percent.toStringAsFixed(2)}%';
  }
}
