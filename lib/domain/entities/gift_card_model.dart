import 'package:cloud_firestore/cloud_firestore.dart';

class GiftCard {
  final String id;
  final String ownerId;
  final String storeId;
  final String storeName; // Denormalized for easy display
  final String storeLogoUrl; // Denormalized for easy display
  final double initialAmount;
  final double remainingBalance;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String code;

  GiftCard({
    required this.id,
    required this.ownerId,
    required this.storeId,
    required this.storeName,
    required this.storeLogoUrl,
    required this.initialAmount,
    required this.remainingBalance,
    required this.issueDate,
    required this.expiryDate,
    required this.code,
  });

  factory GiftCard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GiftCard(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      storeLogoUrl: data['storeLogoUrl'] ?? '',
      initialAmount: (data['initialAmount'] ?? 0.0).toDouble(),
      remainingBalance: (data['remainingBalance'] ?? 0.0).toDouble(),
      issueDate: (data['issueDate'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      code: data['code'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'storeId': storeId,
      'storeName': storeName,
      'storeLogoUrl': storeLogoUrl,
      'initialAmount': initialAmount,
      'remainingBalance': remainingBalance,
      'issueDate': Timestamp.fromDate(issueDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'code': code,
    };
  }
}
