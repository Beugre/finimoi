// Configuration CinetPay pour FinIMoi
// Clés CinetPay configurées - Modifiables via l'interface de configuration

class CinetPayConfig {
  // Identifiants CinetPay FinIMoi
  static const String apiKey = '4734286366839c8e3c73584.02614643';
  static const String secretKey = '17751511186839c928f29376.24716920';
  static const String siteId = '105896797';

  // Environment (sandbox ou production)
  static const bool isProduction = false; // Mode sandbox pour les tests

  // URLs de callback FinIMoi
  static const String returnUrl = 'https://finimoi.com/payment-return.html';
  static const String notifyUrl =
      'https://finimoi.com/api/payment/notify'; // Webhook pour notifications
  static const String cancelUrl = 'https://finimoi.com/payment-cancel.html';

  // Configuration générale
  static const String defaultCurrency = 'XOF'; // Franc CFA par défaut
  static const String secondaryCurrency = 'EUR'; // Euro en second
  static const String defaultCountry = 'CI'; // Côte d'Ivoire prioritaire

  // Taux de change XOF/EUR (à mettre à jour régulièrement)
  static const double xofToEurRate =
      0.00152; // 1 XOF = 0.00152 EUR (approximatif)
  static const double eurToXofRate =
      655.957; // 1 EUR = 655.957 XOF (approximatif)

  // Préférences d'affichage
  static bool showOnlyXOF =
      false; // true = afficher seulement XOF, false = afficher les deux
  static bool showOnlyEUR =
      false; // true = afficher seulement EUR, false = afficher les deux

  // Méthodes de paiement supportées - Priorité Côte d'Ivoire
  static const List<String> supportedMethods = [
    'ALL', // Toutes les méthodes
    'MOBILE_MONEY', // Mobile Money (Orange, MTN, Moov)
    'WALLET', // Portefeuilles électroniques (Wave)
    'CREDIT_CARD', // Cartes de crédit
    'INTERNATIONAL_CARD', // Cartes internationales
  ];

  // URLs de base API - Votre endpoint personnalisé
  static String get baseUrl => isProduction
      ? 'https://api-checkout.cinetpay.com/v2'
      : 'https://api-checkout.cinetpay.com/v2';
}

// Modèles pour les réponses CinetPay
class CinetPayTransaction {
  final String transactionId;
  final String paymentUrl;
  final String status;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  CinetPayTransaction({
    required this.transactionId,
    required this.paymentUrl,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.metadata,
  });

  factory CinetPayTransaction.fromJson(Map<String, dynamic> json) {
    return CinetPayTransaction(
      transactionId: json['transaction_id'] ?? '',
      paymentUrl: json['payment_url'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'XOF',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      metadata: json['metadata'],
    );
  }
}

enum CinetPayStatus { pending, completed, failed, cancelled }

class CinetPayPaymentMethod {
  final String code;
  final String name;
  final String description;
  final bool isAvailable;

  CinetPayPaymentMethod({
    required this.code,
    required this.name,
    required this.description,
    required this.isAvailable,
  });

  static List<CinetPayPaymentMethod> getAvailableMethods() {
    return [
      CinetPayPaymentMethod(
        code: 'ORANGE_MONEY_CI',
        name: 'Orange Money',
        description: 'Paiement via Orange Money Côte d\'Ivoire',
        isAvailable: true,
      ),
      CinetPayPaymentMethod(
        code: 'MTN_MONEY_CI',
        name: 'MTN Money',
        description: 'Paiement via MTN Mobile Money',
        isAvailable: true,
      ),
      CinetPayPaymentMethod(
        code: 'MOOV_MONEY_CI',
        name: 'Moov Money',
        description: 'Paiement via Moov Money',
        isAvailable: true,
      ),
      CinetPayPaymentMethod(
        code: 'WAVE_CI',
        name: 'Wave',
        description: 'Paiement via Wave',
        isAvailable: true,
      ),
      CinetPayPaymentMethod(
        code: 'VISA',
        name: 'Visa',
        description: 'Paiement par carte Visa',
        isAvailable: true,
      ),
      CinetPayPaymentMethod(
        code: 'MASTERCARD',
        name: 'Mastercard',
        description: 'Paiement par carte Mastercard',
        isAvailable: true,
      ),
    ];
  }
}
