import 'package:cloud_firestore/cloud_firestore.dart';

class CreditModel {
  final String id;
  final String userId;
  final double amount;
  final String purpose;
  final int duration; // en mois
  final double interestRate;
  final String
  status; // 'pending', 'approved', 'rejected', 'active', 'completed'
  final double monthlyPayment;
  final double remainingAmount;
  final DateTime applicationDate;
  final DateTime? approvalDate;
  final DateTime? nextPaymentDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final List<String>? documentUrls;

  CreditModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.purpose,
    required this.duration,
    required this.interestRate,
    required this.status,
    required this.monthlyPayment,
    required this.remainingAmount,
    required this.applicationDate,
    this.approvalDate,
    this.nextPaymentDate,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.documentUrls,
  });

  // Factory constructor depuis Firestore
  factory CreditModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CreditModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      purpose: data['purpose'] ?? '',
      duration: data['duration'] ?? 0,
      interestRate: (data['interestRate'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      monthlyPayment: (data['monthlyPayment'] ?? 0.0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0.0).toDouble(),
      applicationDate:
          (data['applicationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvalDate: (data['approvalDate'] as Timestamp?)?.toDate(),
      nextPaymentDate: (data['nextPaymentDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
    );
  }

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'purpose': purpose,
      'duration': duration,
      'interestRate': interestRate,
      'status': status,
      'monthlyPayment': monthlyPayment,
      'remainingAmount': remainingAmount,
      'applicationDate': Timestamp.fromDate(applicationDate),
      'approvalDate': approvalDate != null
          ? Timestamp.fromDate(approvalDate!)
          : null,
      'nextPaymentDate': nextPaymentDate != null
          ? Timestamp.fromDate(nextPaymentDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'documentUrls': documentUrls,
    };
  }

  // Getters utiles
  double get totalAmount => amount + (amount * interestRate);
  double get paidAmount => totalAmount - remainingAmount;
  double get progressPercentage =>
      totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0.0;

  bool get isActive => status == 'active' || status == 'approved';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';

  int get remainingPayments =>
      monthlyPayment > 0 ? (remainingAmount / monthlyPayment).ceil() : 0;

  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }

  // Méthode copyWith
  CreditModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? purpose,
    int? duration,
    double? interestRate,
    String? status,
    double? monthlyPayment,
    double? remainingAmount,
    DateTime? applicationDate,
    DateTime? approvalDate,
    DateTime? nextPaymentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<String>? documentUrls,
  }) {
    return CreditModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      duration: duration ?? this.duration,
      interestRate: interestRate ?? this.interestRate,
      status: status ?? this.status,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      applicationDate: applicationDate ?? this.applicationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      documentUrls: documentUrls ?? this.documentUrls,
    );
  }

  @override
  String toString() {
    return 'CreditModel(id: $id, amount: $amount, purpose: $purpose, status: $status)';
  }
}

class RepaymentSchedule {
  final int month;
  final DateTime dueDate;
  final double principal;
  final double interest;
  final double totalPayment;
  final double remainingBalance;
  bool isPaid;

  RepaymentSchedule({
    required this.month,
    required this.dueDate,
    required this.principal,
    required this.interest,
    required this.totalPayment,
    required this.remainingBalance,
    this.isPaid = false,
  });
}
