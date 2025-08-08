import 'package:intl/intl.dart';

class CurrencyUtils {
  static const String defaultCurrency = 'XOF'; // Franc CFA
  static const String euroSymbol = '€';
  static const String dollarSymbol = '\$';
  static const String cfaSymbol = 'CFA';

  /// Format amount with currency symbol
  static String formatAmount(
    double amount, {
    String currency = defaultCurrency,
  }) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: currency == defaultCurrency ? 0 : 2,
      locale: 'fr_FR',
    );
    return formatter.format(amount);
  }

  /// Format amount without currency symbol
  static String formatAmountOnly(double amount, {bool showDecimals = true}) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    if (showDecimals) {
      return formatter.format(amount);
    } else {
      return formatter.format(amount.round());
    }
  }

  /// Format amount with compact notation (K, M, B)
  static String formatCompactAmount(
    double amount, {
    String currency = defaultCurrency,
  }) {
    final formatter = NumberFormat.compactCurrency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 1,
      locale: 'fr_FR',
    );
    return formatter.format(amount);
  }

  /// Parse string amount to double
  static double? parseAmount(String amount) {
    try {
      // Remove currency symbols and spaces
      final cleanAmount = amount
          .replaceAll(RegExp(r'[€\$CFA\s]'), '')
          .replaceAll(',', '.')
          .trim();
      return double.parse(cleanAmount);
    } catch (e) {
      return null;
    }
  }

  /// Validate amount
  static bool isValidAmount(String amount) {
    return parseAmount(amount) != null;
  }

  /// Check if amount is positive
  static bool isPositiveAmount(double amount) {
    return amount > 0;
  }

  /// Check if amount is within transfer limits
  static bool isWithinTransferLimits(double amount) {
    return amount >= 1.0 && amount <= 1000000.0;
  }

  /// Check if amount is within recharge limits
  static bool isWithinRechargeLimits(double amount) {
    return amount >= 5.0 && amount <= 500000.0;
  }

  /// Convert between currencies (simplified)
  static double convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
    double exchangeRate,
  ) {
    return amount * exchangeRate;
  }

  /// Get currency symbol
  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'EUR':
        return euroSymbol;
      case 'USD':
        return dollarSymbol;
      case 'XOF':
      case 'CFA':
        return cfaSymbol;
      default:
        return currency;
    }
  }

  /// Format percentage
  static String formatPercentage(double percentage, {int decimalPlaces = 1}) {
    final formatter = NumberFormat.percentPattern('fr_FR');
    formatter.minimumFractionDigits = decimalPlaces;
    formatter.maximumFractionDigits = decimalPlaces;
    return formatter.format(percentage / 100);
  }

  /// Calculate percentage
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0.0;
    return (value / total) * 100;
  }

  /// Calculate interest
  static double calculateSimpleInterest(
    double principal,
    double rate,
    int durationInDays,
  ) {
    return principal * (rate / 100) * (durationInDays / 365);
  }

  /// Calculate compound interest
  static double calculateCompoundInterest(
    double principal,
    double annualRate,
    int compoundingFrequency,
    int years,
  ) {
    return principal *
        (1 + (annualRate / 100) / compoundingFrequency).pow(
          compoundingFrequency * years,
        );
  }

  /// Round to nearest currency unit
  static double roundToCurrency(
    double amount, {
    String currency = defaultCurrency,
  }) {
    if (currency == defaultCurrency) {
      // Round to nearest whole number for CFA
      return amount.roundToDouble();
    } else {
      // Round to 2 decimal places for other currencies
      return double.parse(amount.toStringAsFixed(2));
    }
  }
}

extension DoubleExtension on double {
  /// Extension method to get pow operation
  double pow(num exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}
