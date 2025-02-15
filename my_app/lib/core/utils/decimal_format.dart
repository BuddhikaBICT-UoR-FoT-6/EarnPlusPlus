import 'package:decimal/decimal.dart'; // importing the Decimal class from the
// decimal package to handle precise decimal arithmetic, which is crucial for
// financial calculations to avoid issues with floating-point precision.

// The decimalToFixed function takes a Decimal value and formats it as a string
// with a specified number of fraction digits. It splits the Decimal into its
// whole and fractional parts, normalizes the fractional part to ensure it has
// the correct number of digits, and then combines them back into a formatted string.
String decimalToFixed(Decimal value, {int fractionDigits = 2}) {
  final parts = value.toString().split('.');
  final whole = parts.first;
  final frac = parts.length > 1 ? parts[1] : ''; // handles the case where there
  // is no fractional part by using an empty string as the default value for fraction

  if (fractionDigits <= 0) return whole; // if no fraction digits are requested,
  // return just the whole part

  // normalize the fractional part to ensure it has the correct number of digits
  // by padding with zeros if necessary and truncating if it exceeds the specified length
  final normalized = (frac + ('0' * fractionDigits)).substring(
    0,
    fractionDigits,
  );
  return '$whole.$normalized';
}
