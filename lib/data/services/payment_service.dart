import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod {
  card, // Carte bancaire
  mobileMoney, // Mobile Money (Orange Money, MTN Money, etc.)
  bankTransfer, // Virement bancaire
}

enum PaymentProvider {
  cinetpay, // CinetPay pour l'Afrique de l'Ouest
  stripe, // Stripe pour international
  wave, // Wave pour le Sénégal
}

enum PaymentStatus { pending, processing, completed, failed, cancelled }

class PaymentTransaction {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentProvider provider;
  final PaymentStatus status;
  final String? transactionId; // ID de la transaction chez le provider
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.provider,
    required this.status,
    this.transactionId,
    this.errorMessage,
    this.metadata,
    required this.createdAt,
    this.completedAt,
  });

  factory PaymentTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'XOF',
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${data['method']}',
        orElse: () => PaymentMethod.card,
      ),
      provider: PaymentProvider.values.firstWhere(
        (e) => e.toString() == 'PaymentProvider.${data['provider']}',
        orElse: () => PaymentProvider.cinetpay,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${data['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: data['transactionId'],
      errorMessage: data['errorMessage'],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'method': method.toString().split('.').last,
      'provider': provider.toString().split('.').last,
      'status': status.toString().split('.').last,
      'transactionId': transactionId,
      'errorMessage': errorMessage,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  PaymentTransaction copyWith({
    PaymentStatus? status,
    String? transactionId,
    String? errorMessage,
    DateTime? completedAt,
  }) {
    return PaymentTransaction(
      id: id,
      userId: userId,
      amount: amount,
      currency: currency,
      method: method,
      provider: provider,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _paymentsCollection = _firestore.collection(
    'payments',
  );

  // Initier une recharge avec simulation
  static Future<PaymentTransaction> initiateRecharge({
    required String userId,
    required double amount,
    required PaymentMethod method,
    String currency = 'XOF',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Créer la transaction de paiement
      final payment = PaymentTransaction(
        id: '',
        userId: userId,
        amount: amount,
        currency: currency,
        method: method,
        provider: _getProviderForMethod(method),
        status: PaymentStatus.pending,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      // Sauvegarder en base
      final docRef = await _paymentsCollection.add(payment.toFirestore());
      final savedPayment = payment.copyWith();

      // Pour l'instant, simulation uniquement
      return await _simulatePayment(docRef.id, savedPayment);
    } catch (e) {
      throw Exception('Erreur lors de l\'initiation du paiement: $e');
    }
  }

  // Simulation de paiement (à remplacer par l'intégration réelle)
  static Future<PaymentTransaction> _simulatePayment(
    String paymentId,
    PaymentTransaction payment,
  ) async {
    try {
      // Simuler un délai de traitement
      await Future.delayed(const Duration(seconds: 2));

      // Simuler un succès (90% de chance de succès)
      final isSuccess = DateTime.now().millisecond % 10 != 0;

      final updatedPayment = payment.copyWith(
        status: isSuccess ? PaymentStatus.completed : PaymentStatus.failed,
        transactionId: isSuccess
            ? 'SIM_${DateTime.now().millisecondsSinceEpoch}'
            : null,
        errorMessage: isSuccess ? null : 'Simulation d\'échec de paiement',
        completedAt: isSuccess ? DateTime.now() : null,
      );

      // Mettre à jour en base
      await _paymentsCollection
          .doc(paymentId)
          .update(updatedPayment.toFirestore());

      // Si succès, mettre à jour le solde utilisateur
      if (isSuccess) {
        await _updateUserBalance(payment.userId, payment.amount);
      }

      return updatedPayment;
    } catch (e) {
      throw Exception('Erreur lors de la simulation de paiement: $e');
    }
  }

  // Mettre à jour le solde utilisateur après paiement réussi
  static Future<void> _updateUserBalance(String userId, double amount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('Utilisateur non trouvé');
        }

        final currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
        final newBalance = currentBalance + amount;

        transaction.update(userRef, {'balance': newBalance});
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du solde: $e');
    }
  }

  // Déterminer le provider selon la méthode
  static PaymentProvider _getProviderForMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return PaymentProvider.cinetpay;
      case PaymentMethod.mobileMoney:
        return PaymentProvider.cinetpay;
      case PaymentMethod.bankTransfer:
        return PaymentProvider.cinetpay;
    }
  }

  // Obtenir l'historique des paiements d'un utilisateur
  static Future<List<PaymentTransaction>> getUserPayments(String userId) async {
    try {
      final querySnapshot = await _paymentsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paiements: $e');
    }
  }

  // Stream des paiements d'un utilisateur
  static Stream<List<PaymentTransaction>> streamUserPayments(String userId) {
    return _paymentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentTransaction.fromFirestore(doc))
              .toList(),
        );
  }

  // Vérifier le statut d'un paiement
  static Future<PaymentTransaction?> getPaymentStatus(String paymentId) async {
    try {
      final doc = await _paymentsCollection.doc(paymentId).get();
      if (!doc.exists) return null;

      return PaymentTransaction.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la vérification du statut: $e');
    }
  }
}

// Configuration CinetPay (pour l'intégration future)
class CinetPayConfig {
  static const String baseUrl = 'https://api-checkout.cinetpay.com/v2/';
  static const String siteName = 'FinIMoi';

  // À configurer avec vos vraies clés
  static const String apiKey = 'YOUR_API_KEY';
  static const String siteId = 'YOUR_SITE_ID';

  // Méthodes de paiement supportées par CinetPay
  static const List<String> supportedMethods = [
    'ORANGE_MONEY_CM',
    'ORANGE_MONEY_CI',
    'ORANGE_MONEY_SN',
    'MTN_MONEY',
    'MOOV_MONEY',
    'FLOOZ',
    'WAVE_CI',
    'WAVE_SN',
    'VISA',
    'MASTERCARD',
  ];
}
