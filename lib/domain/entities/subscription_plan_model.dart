import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlanModel {
  final String id;
  final String merchantId;
  final String planName;
  final double amount;
  final String frequency; // e.g., 'weekly', 'monthly'

  SubscriptionPlanModel({
    required this.id,
    required this.merchantId,
    required this.planName,
    required this.amount,
    required this.frequency,
  });

  factory SubscriptionPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionPlanModel(
      id: doc.id,
      merchantId: data['merchantId'] ?? '',
      planName: data['planName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      frequency: data['frequency'] ?? 'monthly',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'planName': planName,
      'amount': amount,
      'frequency': frequency,
    };
  }
}
