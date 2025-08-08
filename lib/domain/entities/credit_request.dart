import 'package:cloud_firestore/cloud_firestore.dart';

class CreditRequest {
  final String id;
  final String userId;
  final double amount;
  final int durationMonths;
  final String purpose;
  final double interestRate;
  final CreditStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? adminId;
  final List<CreditDocument> documents;
  final CreditTerms terms;
  final List<CreditPayment> payments;

  const CreditRequest({
    required this.id,
    required this.userId,
    required this.amount,
    required this.durationMonths,
    required this.purpose,
    required this.interestRate,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.adminId,
    required this.documents,
    required this.terms,
    required this.payments,
  });

  double get monthlyPayment {
    if (durationMonths == 0) return 0;
    final monthlyRate = interestRate / 100 / 12;
    if (monthlyRate == 0) return amount / durationMonths;

    return amount *
        monthlyRate *
        (1 + monthlyRate).pow(durationMonths) /
        ((1 + monthlyRate).pow(durationMonths) - 1);
  }

  double get totalAmount => monthlyPayment * durationMonths;

  double get totalInterest => totalAmount - amount;

  double get paidAmount => payments
      .where((p) => p.status == PaymentStatus.paid)
      .fold(0.0, (sum, p) => sum + p.amount);

  double get remainingAmount => totalAmount - paidAmount;

  int get paidPayments =>
      payments.where((p) => p.status == PaymentStatus.paid).length;

  int get remainingPayments => durationMonths - paidPayments;

  bool get isFullyPaid => paidPayments >= durationMonths;

  factory CreditRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      durationMonths: data['durationMonths'] ?? 0,
      purpose: data['purpose'] ?? '',
      interestRate: (data['interestRate'] ?? 0).toDouble(),
      status: CreditStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => CreditStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: data['rejectedAt'] != null
          ? (data['rejectedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'],
      adminId: data['adminId'],
      documents:
          (data['documents'] as List<dynamic>?)
              ?.map((e) => CreditDocument.fromMap(e))
              .toList() ??
          [],
      terms: CreditTerms.fromMap(data['terms'] ?? {}),
      payments:
          (data['payments'] as List<dynamic>?)
              ?.map((e) => CreditPayment.fromMap(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'durationMonths': durationMonths,
      'purpose': purpose,
      'interestRate': interestRate,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
      'adminId': adminId,
      'documents': documents.map((e) => e.toMap()).toList(),
      'terms': terms.toMap(),
      'payments': payments.map((e) => e.toMap()).toList(),
    };
  }

  CreditRequest copyWith({
    String? id,
    String? userId,
    double? amount,
    int? durationMonths,
    String? purpose,
    double? interestRate,
    CreditStatus? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? adminId,
    List<CreditDocument>? documents,
    CreditTerms? terms,
    List<CreditPayment>? payments,
  }) {
    return CreditRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      durationMonths: durationMonths ?? this.durationMonths,
      purpose: purpose ?? this.purpose,
      interestRate: interestRate ?? this.interestRate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminId: adminId ?? this.adminId,
      documents: documents ?? this.documents,
      terms: terms ?? this.terms,
      payments: payments ?? this.payments,
    );
  }
}

enum CreditStatus {
  pending,
  underReview,
  approved,
  rejected,
  active,
  completed,
  defaulted,
}

extension CreditStatusExtension on CreditStatus {
  String get displayName {
    switch (this) {
      case CreditStatus.pending:
        return 'En attente';
      case CreditStatus.underReview:
        return 'En cours d\'examen';
      case CreditStatus.approved:
        return 'Approuvé';
      case CreditStatus.rejected:
        return 'Rejeté';
      case CreditStatus.active:
        return 'Actif';
      case CreditStatus.completed:
        return 'Terminé';
      case CreditStatus.defaulted:
        return 'En défaut';
    }
  }

  String get color {
    switch (this) {
      case CreditStatus.pending:
        return 'orange';
      case CreditStatus.underReview:
        return 'blue';
      case CreditStatus.approved:
        return 'green';
      case CreditStatus.rejected:
        return 'red';
      case CreditStatus.active:
        return 'purple';
      case CreditStatus.completed:
        return 'green';
      case CreditStatus.defaulted:
        return 'red';
    }
  }
}

class CreditDocument {
  final String id;
  final String name;
  final String url;
  final String type;
  final DateTime uploadedAt;
  final bool isVerified;

  const CreditDocument({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.uploadedAt,
    required this.isVerified,
  });

  factory CreditDocument.fromMap(Map<String, dynamic> map) {
    return CreditDocument(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'isVerified': isVerified,
    };
  }
}

class CreditTerms {
  final double monthlyPayment;
  final DateTime firstPaymentDate;
  final DateTime lastPaymentDate;
  final double totalAmount;
  final double totalInterest;
  final double penaltyRate;
  final int gracePeriodDays;

  const CreditTerms({
    required this.monthlyPayment,
    required this.firstPaymentDate,
    required this.lastPaymentDate,
    required this.totalAmount,
    required this.totalInterest,
    required this.penaltyRate,
    required this.gracePeriodDays,
  });

  factory CreditTerms.fromMap(Map<String, dynamic> map) {
    return CreditTerms(
      monthlyPayment: (map['monthlyPayment'] ?? 0).toDouble(),
      firstPaymentDate: map['firstPaymentDate'] != null
          ? (map['firstPaymentDate'] as Timestamp).toDate()
          : DateTime.now(),
      lastPaymentDate: map['lastPaymentDate'] != null
          ? (map['lastPaymentDate'] as Timestamp).toDate()
          : DateTime.now(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      totalInterest: (map['totalInterest'] ?? 0).toDouble(),
      penaltyRate: (map['penaltyRate'] ?? 0).toDouble(),
      gracePeriodDays: map['gracePeriodDays'] ?? 7,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monthlyPayment': monthlyPayment,
      'firstPaymentDate': Timestamp.fromDate(firstPaymentDate),
      'lastPaymentDate': Timestamp.fromDate(lastPaymentDate),
      'totalAmount': totalAmount,
      'totalInterest': totalInterest,
      'penaltyRate': penaltyRate,
      'gracePeriodDays': gracePeriodDays,
    };
  }
}

class CreditPayment {
  final String id;
  final int paymentNumber;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final PaymentStatus status;
  final double? penaltyAmount;
  final String? transactionId;

  const CreditPayment({
    required this.id,
    required this.paymentNumber,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.penaltyAmount,
    this.transactionId,
  });

  bool get isOverdue =>
      status != PaymentStatus.paid && DateTime.now().isAfter(dueDate);

  int get daysPastDue =>
      isOverdue ? DateTime.now().difference(dueDate).inDays : 0;

  factory CreditPayment.fromMap(Map<String, dynamic> map) {
    return CreditPayment(
      id: map['id'] ?? '',
      paymentNumber: map['paymentNumber'] ?? 0,
      amount: (map['amount'] ?? 0).toDouble(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      paidDate: map['paidDate'] != null
          ? (map['paidDate'] as Timestamp).toDate()
          : null,
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      penaltyAmount: map['penaltyAmount']?.toDouble(),
      transactionId: map['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentNumber': paymentNumber,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'status': status.name,
      'penaltyAmount': penaltyAmount,
      'transactionId': transactionId,
    };
  }
}

enum PaymentStatus { pending, paid, overdue, failed }

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.overdue:
        return 'En retard';
      case PaymentStatus.failed:
        return 'Échec';
    }
  }
}

// Extension pour les calculs mathématiques
extension MathExtension on num {
  num pow(num exponent) {
    num result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}
