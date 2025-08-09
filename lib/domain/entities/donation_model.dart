import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String id;
  final String userId;
  final String orphanageId;
  final String orphanageName; // Denormalized
  final double amount;
  final bool isRecurring;
  final Timestamp createdAt;

  Donation({
    required this.id,
    required this.userId,
    required this.orphanageId,
    required this.orphanageName,
    required this.amount,
    required this.isRecurring,
    required this.createdAt,
  });

  factory Donation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Donation(
      id: doc.id,
      userId: data['userId'] ?? '',
      orphanageId: data['orphanageId'] ?? '',
      orphanageName: data['orphanageName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      isRecurring: data['isRecurring'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orphanageId': orphanageId,
      'orphanageName': orphanageName,
      'amount': amount,
      'isRecurring': isRecurring,
      'createdAt': createdAt,
    };
  }
}
