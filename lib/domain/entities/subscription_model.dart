import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionStatus { active, paused, cancelled, ended }
enum SubscriptionFrequency { weekly, monthly, yearly }

class SubscriptionModel {
  final String id;
  final String merchantId;
  final String customerId;
  final double amount;
  final SubscriptionFrequency frequency;
  final DateTime startDate;
  final DateTime nextPaymentDate;
  final SubscriptionStatus status;
  final String? paymentMethodId; // e.g., a token for a card

  SubscriptionModel({
    required this.id,
    required this.merchantId,
    required this.customerId,
    required this.amount,
    required this.frequency,
    required this.startDate,
    required this.nextPaymentDate,
    required this.status,
    this.paymentMethodId,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      merchantId: data['merchantId'],
      customerId: data['customerId'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      frequency: _frequencyFromString(data['frequency'] ?? 'monthly'),
      startDate: (data['startDate'] as Timestamp).toDate(),
      nextPaymentDate: (data['nextPaymentDate'] as Timestamp).toDate(),
      status: _statusFromString(data['status'] ?? 'active'),
      paymentMethodId: data['paymentMethodId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'customerId': customerId,
      'amount': amount,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'nextPaymentDate': Timestamp.fromDate(nextPaymentDate),
      'status': status.name,
      'paymentMethodId': paymentMethodId,
    };
  }

  static SubscriptionStatus _statusFromString(String status) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => SubscriptionStatus.active,
    );
  }

  static SubscriptionFrequency _frequencyFromString(String frequency) {
    return SubscriptionFrequency.values.firstWhere(
      (e) => e.name == frequency,
      orElse: () => SubscriptionFrequency.monthly,
    );
  }
}
