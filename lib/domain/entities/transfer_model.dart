import 'package:cloud_firestore/cloud_firestore.dart';

/// Types de transfert supportés
enum TransferType {
  internal, // Entre utilisateurs de l'app
  mobileMoney, // Vers Mobile Money (Orange, MTN, Moov, Wave)
  bankTransfer, // Vers compte bancaire
  qrCode, // Paiement par QR Code
}

/// Statuts de transfert
enum TransferStatus {
  pending, // En attente
  processing, // En cours de traitement
  completed, // Terminé avec succès
  failed, // Échoué
  cancelled, // Annulé
  refunded, // Remboursé
}

/// Modèle principal pour un transfert
class TransferModel {
  final String id;
  final String senderId;
  final String? recipientId; // Pour transferts internes
  final String? recipientPhone; // Pour Mobile Money/Banque
  final String? recipientName;
  final double amount; // Montant principal
  final double fees; // Frais de transfert
  final double totalAmount; // Montant total (amount + fees)
  final String currency;
  final TransferType type;
  final String? provider; // Orange, MTN, Moov, Wave, etc.
  final TransferStatus status;
  final String reference; // Référence unique
  final String? description;
  final String? recipientBank; // Pour virements bancaires
  final String? recipientAccountNumber;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final Timestamp? completedAt;
  final String? failureReason;
  final Map<String, dynamic>? metadata;

  const TransferModel({
    required this.id,
    required this.senderId,
    this.recipientId,
    this.recipientPhone,
    this.recipientName,
    required this.amount,
    required this.fees,
    required this.totalAmount,
    this.currency = 'XOF',
    required this.type,
    this.provider,
    required this.status,
    required this.reference,
    this.description,
    this.recipientBank,
    this.recipientAccountNumber,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.failureReason,
    this.metadata,
  });

  /// Crée une instance depuis Firestore
  factory TransferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TransferModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      recipientId: data['recipientId'],
      recipientPhone: data['recipientPhone'],
      recipientName: data['recipientName'],
      amount: (data['amount'] as num).toDouble(),
      fees: (data['fees'] as num).toDouble(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      currency: data['currency'] ?? 'XOF',
      type: TransferType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransferType.internal,
      ),
      provider: data['provider'],
      status: TransferStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransferStatus.pending,
      ),
      reference: data['reference'] ?? '',
      description: data['description'],
      recipientBank: data['recipientBank'],
      recipientAccountNumber: data['recipientAccountNumber'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      completedAt: data['completedAt'],
      failureReason: data['failureReason'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  /// Convertit vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'recipientPhone': recipientPhone,
      'recipientName': recipientName,
      'amount': amount,
      'fees': fees,
      'totalAmount': totalAmount,
      'currency': currency,
      'type': type.name,
      'provider': provider,
      'status': status.name,
      'reference': reference,
      'description': description,
      'recipientBank': recipientBank,
      'recipientAccountNumber': recipientAccountNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
      'failureReason': failureReason,
      'metadata': metadata,
    };
  }

  /// Copie avec modifications
  TransferModel copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? recipientPhone,
    String? recipientName,
    double? amount,
    double? fees,
    double? totalAmount,
    String? currency,
    TransferType? type,
    String? provider,
    TransferStatus? status,
    String? reference,
    String? description,
    String? recipientBank,
    String? recipientAccountNumber,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? completedAt,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) {
    return TransferModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientName: recipientName ?? this.recipientName,
      amount: amount ?? this.amount,
      fees: fees ?? this.fees,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      recipientBank: recipientBank ?? this.recipientBank,
      recipientAccountNumber:
          recipientAccountNumber ?? this.recipientAccountNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Vérifie si le transfert est en cours
  bool get isPending =>
      status == TransferStatus.pending || status == TransferStatus.processing;

  /// Vérifie si le transfert est terminé
  bool get isCompleted => status == TransferStatus.completed;

  /// Vérifie si le transfert a échoué
  bool get isFailed => status == TransferStatus.failed;

  /// Vérifie si le transfert peut être annulé
  bool get canBeCancelled => status == TransferStatus.pending;

  /// Vérifie si le transfert peut être remboursé
  bool get canBeRefunded => status == TransferStatus.completed;

  /// Récupère l'icône selon le type de transfert
  String get typeIcon {
    switch (type) {
      case TransferType.internal:
        return '👤';
      case TransferType.mobileMoney:
        return '📱';
      case TransferType.bankTransfer:
        return '🏦';
      case TransferType.qrCode:
        return '📷';
    }
  }

  /// Récupère la couleur selon le statut
  String get statusColor {
    switch (status) {
      case TransferStatus.pending:
        return '#FFA500';
      case TransferStatus.processing:
        return '#3B82F6';
      case TransferStatus.completed:
        return '#10B981';
      case TransferStatus.failed:
        return '#EF4444';
      case TransferStatus.cancelled:
        return '#6B7280';
      case TransferStatus.refunded:
        return '#8B5CF6';
    }
  }

  /// Formate l'heure du transfert
  String get formattedTime {
    final now = DateTime.now();
    final transferDateTime = createdAt.toDate();
    final today = DateTime(now.year, now.month, now.day);
    final transferDate = DateTime(
      transferDateTime.year,
      transferDateTime.month,
      transferDateTime.day,
    );

    if (transferDate == today) {
      return '${transferDateTime.hour.toString().padLeft(2, '0')}:${transferDateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${transferDateTime.day}/${transferDateTime.month}';
    }
  }

  @override
  String toString() =>
      'TransferModel(id: $id, amount: $amount, status: $status)';
}

/// Requête de transfert
class TransferRequest {
  final String? recipientId;
  final String? recipientPhone;
  final String? recipientName;
  final double amount;
  final String currency;
  final TransferType type;
  final String? provider;
  final String? description;
  final String? recipientBank;
  final String? recipientAccountNumber;
  final double fees;

  const TransferRequest({
    this.recipientId,
    this.recipientPhone,
    this.recipientName,
    required this.amount,
    this.currency = 'XOF',
    required this.type,
    this.provider,
    this.description,
    this.recipientBank,
    this.recipientAccountNumber,
    this.fees = 0.0,
  });

  /// Crée une requête de transfert interne
  factory TransferRequest.internal({
    required String recipientId,
    required String recipientName,
    required double amount,
    String? description,
  }) {
    return TransferRequest(
      recipientId: recipientId,
      recipientName: recipientName,
      amount: amount,
      type: TransferType.internal,
      description: description,
      fees: 0.0,
    );
  }

  /// Crée une requête de transfert Mobile Money
  factory TransferRequest.mobileMoney({
    required String recipientPhone,
    required String recipientName,
    required double amount,
    required String provider,
    required double fees,
    String? description,
  }) {
    return TransferRequest(
      recipientPhone: recipientPhone,
      recipientName: recipientName,
      amount: amount,
      type: TransferType.mobileMoney,
      provider: provider,
      fees: fees,
      description: description,
    );
  }

  /// Crée une requête de virement bancaire
  factory TransferRequest.bankTransfer({
    required String recipientName,
    required String recipientBank,
    required String recipientAccountNumber,
    required double amount,
    required double fees,
    String? description,
  }) {
    return TransferRequest(
      recipientName: recipientName,
      recipientBank: recipientBank,
      recipientAccountNumber: recipientAccountNumber,
      amount: amount,
      type: TransferType.bankTransfer,
      fees: fees,
      description: description,
    );
  }

  /// Crée une requête de paiement QR Code
  factory TransferRequest.qrCode({
    required String recipientId,
    required String recipientName,
    required double amount,
    String? description,
  }) {
    return TransferRequest(
      recipientId: recipientId,
      recipientName: recipientName,
      amount: amount,
      type: TransferType.qrCode,
      description: description,
      fees: 0.0,
    );
  }
}

/// Résultat d'un transfert
class TransferResult {
  final bool isSuccess;
  final TransferModel? transfer;
  final String? error;

  const TransferResult._({required this.isSuccess, this.transfer, this.error});

  /// Crée un résultat de succès
  factory TransferResult.success(TransferModel transfer) {
    return TransferResult._(isSuccess: true, transfer: transfer);
  }

  /// Crée un résultat d'erreur
  factory TransferResult.error(String error) {
    return TransferResult._(isSuccess: false, error: error);
  }
}

/// Résultat de validation d'une requête de transfert
class TransferValidationResult {
  final bool isValid;
  final List<String> errors;

  const TransferValidationResult({required this.isValid, required this.errors});
}

/// Statistiques de transfert
class TransferStats {
  final int totalTransfers;
  final double totalAmount;
  final int successfulTransfers;
  final int failedTransfers;
  final double averageAmount;
  final Map<TransferType, int> transfersByType;
  final Map<String, int> transfersByProvider;

  const TransferStats({
    required this.totalTransfers,
    required this.totalAmount,
    required this.successfulTransfers,
    required this.failedTransfers,
    required this.averageAmount,
    required this.transfersByType,
    required this.transfersByProvider,
  });

  /// Calcule le taux de succès
  double get successRate {
    if (totalTransfers == 0) return 0.0;
    return (successfulTransfers / totalTransfers) * 100;
  }

  /// Crée depuis Firestore
  factory TransferStats.fromFirestore(Map<String, dynamic> data) {
    return TransferStats(
      totalTransfers: data['totalTransfers'] ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      successfulTransfers: data['successfulTransfers'] ?? 0,
      failedTransfers: data['failedTransfers'] ?? 0,
      averageAmount: (data['averageAmount'] as num?)?.toDouble() ?? 0.0,
      transfersByType: Map<TransferType, int>.from(
        (data['transfersByType'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                TransferType.values.firstWhere((e) => e.name == key),
                value as int,
              ),
            ) ??
            {},
      ),
      transfersByProvider: Map<String, int>.from(
        data['transfersByProvider'] ?? {},
      ),
    );
  }

  /// Convertit vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'totalTransfers': totalTransfers,
      'totalAmount': totalAmount,
      'successfulTransfers': successfulTransfers,
      'failedTransfers': failedTransfers,
      'averageAmount': averageAmount,
      'transfersByType': transfersByType.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'transfersByProvider': transfersByProvider,
    };
  }
}
