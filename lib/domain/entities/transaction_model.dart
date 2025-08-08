import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  transfer,
  recharge,
  withdrawal,
  payment,
  request, // Demande de paiement
  tontine,
  loan,
  savings,
}

enum TransactionStatus { pending, completed, failed, cancelled }

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String currency;
  final String? description;
  final String? recipientId;
  final String? recipientName;
  final String? senderName;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? completedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.amount,
    this.currency = 'XOF',
    this.description,
    this.recipientId,
    this.recipientName,
    this.senderName,
    this.metadata,
    required this.createdAt,
    this.completedAt,
  });

  bool get isIncoming => recipientId == userId;
  bool get isOutgoing => !isIncoming;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isPending => status == TransactionStatus.pending;

  String get formattedAmount {
    final sign = isIncoming ? '+' : '-';
    return '$sign${amount.toStringAsFixed(0)} $currency';
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.transfer:
        return 'Transfert';
      case TransactionType.recharge:
        return 'Recharge';
      case TransactionType.withdrawal:
        return 'Retrait';
      case TransactionType.payment:
        return 'Paiement';
      case TransactionType.request:
        return 'Demande';
      case TransactionType.tontine:
        return 'Tontine';
      case TransactionType.loan:
        return 'Crédit';
      case TransactionType.savings:
        return 'Épargne';
    }
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.transfer,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'XOF',
      description: data['description'],
      recipientId: data['recipientId'],
      recipientName: data['recipientName'],
      senderName: data['senderName'],
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
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'currency': currency,
      'description': description,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'senderName': senderName,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    TransactionStatus? status,
    double? amount,
    String? currency,
    String? description,
    String? recipientId,
    String? recipientName,
    String? senderName,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      senderName: senderName ?? this.senderName,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
