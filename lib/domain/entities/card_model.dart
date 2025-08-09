import 'package:cloud_firestore/cloud_firestore.dart';

enum CardType { debit, credit, prepaid }

enum CardStatus { active, blocked, expired, pending }

class CardModel {
  final String id;
  final String userId;
  final String userName;
  final String cardType;
  final String cardName;
  final String cardNumber;
  final String expiryDate;
  final String cvv;
  final bool isVirtual;
  final bool isActive;
  final double balance;
  final double limit;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> sharedWith;

  CardModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.cardType,
    required this.cardName,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    required this.isVirtual,
    required this.isActive,
    required this.balance,
    required this.limit,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sharedWith = const [],
  });

  factory CardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CardModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      cardType: data['cardType'] ?? 'debit',
      cardName: data['cardName'] ?? '',
      cardNumber: data['cardNumber'] ?? '',
      expiryDate: data['expiryDate'] ?? '',
      cvv: data['cvv'] ?? '',
      isVirtual: data['isVirtual'] ?? true,
      isActive: data['isActive'] ?? true,
      balance: (data['balance'] ?? 0.0).toDouble(),
      limit: (data['limit'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'active',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.now())
          : DateTime.now(),
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'cardType': cardType,
      'cardName': cardName,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'isVirtual': isVirtual,
      'isActive': isActive,
      'balance': balance,
      'limit': limit,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'sharedWith': sharedWith,
    };
  }

  String get maskedCardNumber {
    if (cardNumber.length < 4) return cardNumber;
    final last4 = cardNumber
        .replaceAll(' ', '')
        .substring(cardNumber.replaceAll(' ', '').length - 4);
    return '**** **** **** $last4';
  }

  String get cardTypeDisplay {
    switch (cardType.toLowerCase()) {
      case 'debit':
        return 'Carte de débit';
      case 'credit':
        return 'Carte de crédit';
      case 'prepaid':
        return 'Carte prépayée';
      default:
        return 'Carte';
    }
  }

  bool get isExpired {
    if (expiryDate.isEmpty) return false;
    try {
      final parts = expiryDate.split('/');
      if (parts.length != 2) return false;

      final month = int.parse(parts[0]);
      final year = 2000 + int.parse(parts[1]);
      final expiry = DateTime(year, month + 1, 0); // Dernier jour du mois

      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return false;
    }
  }

  double get availableBalance => limit - balance;
}
