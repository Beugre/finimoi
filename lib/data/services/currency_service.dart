import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/cinetpay_config.dart';

// Provider pour les préférences de devise
final currencyPreferencesProvider =
    StateNotifierProvider<CurrencyPreferencesNotifier, CurrencyPreferences>((
      ref,
    ) {
      return CurrencyPreferencesNotifier();
    });

// Provider pour le service de conversion
final currencyConverterProvider = Provider<CurrencyConverterService>((ref) {
  return CurrencyConverterService();
});

class CurrencyPreferences {
  final String displayCurrency; // 'XOF', 'EUR', ou 'BOTH'
  final bool showBothCurrencies;
  final String primaryCurrency;

  CurrencyPreferences({
    this.displayCurrency = 'BOTH',
    this.showBothCurrencies = true,
    this.primaryCurrency = 'XOF',
  });

  CurrencyPreferences copyWith({
    String? displayCurrency,
    bool? showBothCurrencies,
    String? primaryCurrency,
  }) {
    return CurrencyPreferences(
      displayCurrency: displayCurrency ?? this.displayCurrency,
      showBothCurrencies: showBothCurrencies ?? this.showBothCurrencies,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
    );
  }
}

class CurrencyPreferencesNotifier extends StateNotifier<CurrencyPreferences> {
  CurrencyPreferencesNotifier() : super(CurrencyPreferences());

  void setDisplayCurrency(String currency) {
    if (currency == 'XOF') {
      state = state.copyWith(
        displayCurrency: 'XOF',
        showBothCurrencies: false,
        primaryCurrency: 'XOF',
      );
    } else if (currency == 'EUR') {
      state = state.copyWith(
        displayCurrency: 'EUR',
        showBothCurrencies: false,
        primaryCurrency: 'EUR',
      );
    } else {
      state = state.copyWith(
        displayCurrency: 'BOTH',
        showBothCurrencies: true,
        primaryCurrency: 'XOF',
      );
    }
  }

  void toggleCurrencyDisplay() {
    if (state.displayCurrency == 'XOF') {
      setDisplayCurrency('EUR');
    } else if (state.displayCurrency == 'EUR') {
      setDisplayCurrency('BOTH');
    } else {
      setDisplayCurrency('XOF');
    }
  }

  void setPrimaryCurrency(String currency) {
    state = state.copyWith(primaryCurrency: currency);
  }
}

class CurrencyConverterService {
  // Convertir XOF vers EUR
  double convertXofToEur(double amountXof) {
    return amountXof * CinetPayConfig.xofToEurRate;
  }

  // Convertir EUR vers XOF
  double convertEurToXof(double amountEur) {
    return amountEur * CinetPayConfig.eurToXofRate;
  }

  // Obtenir le montant dans la devise spécifiée
  double getAmountInCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    if (fromCurrency == toCurrency) return amount;

    if (fromCurrency == 'XOF' && toCurrency == 'EUR') {
      return convertXofToEur(amount);
    } else if (fromCurrency == 'EUR' && toCurrency == 'XOF') {
      return convertEurToXof(amount);
    }

    return amount; // Si conversion non supportée
  }

  // Formater le montant avec la devise
  String formatAmount(
    double amount,
    String currency, {
    bool showSymbol = true,
  }) {
    if (currency == 'XOF') {
      return showSymbol
          ? '${amount.toStringAsFixed(0)} XOF'
          : amount.toStringAsFixed(0);
    } else if (currency == 'EUR') {
      return showSymbol
          ? '${amount.toStringAsFixed(2)} €'
          : amount.toStringAsFixed(2);
    }
    return amount.toString();
  }

  // Formater avec les deux devises
  String formatAmountBoth(double amountXof, {bool primaryFirst = true}) {
    final amountEur = convertXofToEur(amountXof);

    if (primaryFirst) {
      return '${formatAmount(amountXof, 'XOF')} (${formatAmount(amountEur, 'EUR')})';
    } else {
      return '${formatAmount(amountEur, 'EUR')} (${formatAmount(amountXof, 'XOF')})';
    }
  }

  // Obtenir le taux de change actuel
  double getExchangeRate(String fromCurrency, String toCurrency) {
    if (fromCurrency == 'XOF' && toCurrency == 'EUR') {
      return CinetPayConfig.xofToEurRate;
    } else if (fromCurrency == 'EUR' && toCurrency == 'XOF') {
      return CinetPayConfig.eurToXofRate;
    }
    return 1.0;
  }

  // Formater selon les préférences utilisateur
  String formatWithPreferences(
    double amountXof,
    CurrencyPreferences preferences,
  ) {
    switch (preferences.displayCurrency) {
      case 'XOF':
        return formatAmount(amountXof, 'XOF');
      case 'EUR':
        final amountEur = convertXofToEur(amountXof);
        return formatAmount(amountEur, 'EUR');
      case 'BOTH':
      default:
        return formatAmountBoth(
          amountXof,
          primaryFirst: preferences.primaryCurrency == 'XOF',
        );
    }
  }
}

// Widget helper pour afficher les montants
class CurrencyDisplay {
  static String format(
    double amountXof,
    CurrencyPreferences preferences,
    CurrencyConverterService converter,
  ) {
    return converter.formatWithPreferences(amountXof, preferences);
  }

  static String getSymbol(String currency) {
    switch (currency) {
      case 'XOF':
        return 'XOF';
      case 'EUR':
        return '€';
      default:
        return '';
    }
  }

  static String getCurrencyName(String currency) {
    switch (currency) {
      case 'XOF':
        return 'Franc CFA';
      case 'EUR':
        return 'Euro';
      default:
        return currency;
    }
  }
}
