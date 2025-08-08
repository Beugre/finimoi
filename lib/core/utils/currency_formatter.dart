import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Formateur pour les montants en FCFA
  static final NumberFormat _fcfaFormatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '',
    decimalDigits: 0,
  );

  // Formateur pour les montants en Euros
  static final NumberFormat _euroFormatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  // Formateur pour les montants en Dollars
  static final NumberFormat _dollarFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  // Formateur compact pour les gros montants
  static final NumberFormat _compactFormatter = NumberFormat.compact(
    locale: 'fr_FR',
  );

  /// Formate un montant en FCFA
  ///
  /// [amount] - Le montant à formater
  /// [withSymbol] - Inclure le symbole FCFA (défaut: true)
  /// [compact] - Utiliser le format compact pour les gros montants (défaut: false)
  static String formatCFA(
    double amount, {
    bool withSymbol = true,
    bool compact = false,
  }) {
    if (compact && amount >= 1000) {
      return '${_compactFormatter.format(amount)}${withSymbol ? ' FCFA' : ''}';
    }

    final formatted = _fcfaFormatter.format(amount);
    return withSymbol ? '$formatted FCFA' : formatted;
  }

  /// Formate un montant en Euros
  static String formatEuro(double amount) {
    return _euroFormatter.format(amount);
  }

  /// Formate un montant en Dollars
  static String formatDollar(double amount) {
    return _dollarFormatter.format(amount);
  }

  /// Formate un montant selon la devise spécifiée
  static String formatCurrency(
    double amount,
    String currency, {
    bool compact = false,
  }) {
    switch (currency.toUpperCase()) {
      case 'XOF':
      case 'FCFA':
        return formatCFA(amount, compact: compact);
      case 'EUR':
        return formatEuro(amount);
      case 'USD':
        return formatDollar(amount);
      default:
        return formatCFA(amount, compact: compact);
    }
  }

  /// Formate un pourcentage
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Formate un taux de change
  static String formatExchangeRate(double rate) {
    return rate.toStringAsFixed(4);
  }

  /// Parse un montant depuis une chaîne
  static double parseAmount(String amountString) {
    // Supprime tous les caractères non-numériques sauf le point et la virgule
    String cleanedAmount = amountString.replaceAll(RegExp(r'[^\d,.-]'), '');

    // Remplace la virgule par un point pour la décimale
    cleanedAmount = cleanedAmount.replaceAll(',', '.');

    try {
      return double.parse(cleanedAmount);
    } catch (e) {
      return 0.0;
    }
  }

  /// Valide qu'un montant est dans une plage acceptable
  static bool isValidAmount(
    double amount, {
    double minAmount = 0.0,
    double maxAmount = double.infinity,
  }) {
    return amount >= minAmount && amount <= maxAmount;
  }

  /// Formate un montant avec des couleurs selon le signe
  static Map<String, dynamic> formatAmountWithColor(double amount) {
    final isPositive = amount >= 0;
    return {
      'formatted': formatCFA(amount.abs()),
      'isPositive': isPositive,
      'prefix': isPositive ? '+' : '-',
    };
  }

  /// Calcule et formate une commission
  static String formatFee(double amount, double feePercentage) {
    final fee = amount * (feePercentage / 100);
    return formatCFA(fee);
  }

  /// Formate un montant de manière compacte pour les interfaces
  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B FCFA';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M FCFA';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K FCFA';
    } else {
      return formatCFA(amount);
    }
  }

  /// Arrondit un montant selon les règles bancaires
  static double roundBankingAmount(double amount) {
    // Arrondit au multiple de 5 le plus proche pour FCFA
    return (amount / 5).round() * 5;
  }

  /// Divise un montant équitablement entre plusieurs personnes
  static List<double> divideAmount(double totalAmount, int numberOfPeople) {
    final baseAmount = roundBankingAmount(totalAmount / numberOfPeople);
    final remainder = totalAmount - (baseAmount * numberOfPeople);

    final amounts = List<double>.filled(numberOfPeople, baseAmount);

    // Distribue le reste sur les premiers participants
    if (remainder > 0) {
      for (int i = 0; i < remainder ~/ 5 && i < numberOfPeople; i++) {
        amounts[i] += 5;
      }
    }

    return amounts;
  }

  /// Calcule le montant total avec taxes
  static double calculateTotalWithTax(double amount, double taxPercentage) {
    return amount * (1 + taxPercentage / 100);
  }

  /// Formate une plage de montants
  static String formatAmountRange(double minAmount, double maxAmount) {
    return '${formatCFA(minAmount)} - ${formatCFA(maxAmount)}';
  }
}
