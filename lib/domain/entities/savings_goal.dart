import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoal {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final DateTime createdAt;
  final String status; // 'active', 'completed', 'paused'
  final String color;
  final List<SavingsContribution> contributions;

  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.createdAt,
    required this.status,
    required this.color,
    required this.contributions,
  });

  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  int get daysRemaining {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  bool get isCompleted => currentAmount >= targetAmount;

  factory SavingsGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsGoal(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0).toDouble(),
      deadline: (data['deadline'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      color: data['color'] ?? 'blue',
      contributions:
          (data['contributions'] as List<dynamic>?)
              ?.map((e) => SavingsContribution.fromMap(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'color': color,
      'contributions': contributions.map((e) => e.toMap()).toList(),
    };
  }

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    DateTime? createdAt,
    String? status,
    String? color,
    List<SavingsContribution>? contributions,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      color: color ?? this.color,
      contributions: contributions ?? this.contributions,
    );
  }
}

class SavingsContribution {
  final double amount;
  final DateTime date;
  final String source; // 'manual', 'automatic', 'cashback'

  const SavingsContribution({
    required this.amount,
    required this.date,
    required this.source,
  });

  factory SavingsContribution.fromMap(Map<String, dynamic> map) {
    return SavingsContribution(
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      source: map['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'source': source,
    };
  }
}

class SavingsPlan {
  final String id;
  final String title;
  final String description;
  final double minimumAmount;
  final double interestRate;
  final int durationMonths;
  final List<String> features;
  final String color;
  final bool isActive;

  const SavingsPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.minimumAmount,
    required this.interestRate,
    required this.durationMonths,
    required this.features,
    required this.color,
    required this.isActive,
  });

  factory SavingsPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsPlan(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      minimumAmount: (data['minimumAmount'] ?? 0).toDouble(),
      interestRate: (data['interestRate'] ?? 0).toDouble(),
      durationMonths: data['durationMonths'] ?? 12,
      features: List<String>.from(data['features'] ?? []),
      color: data['color'] ?? 'blue',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'minimumAmount': minimumAmount,
      'interestRate': interestRate,
      'durationMonths': durationMonths,
      'features': features,
      'color': color,
      'isActive': isActive,
    };
  }
}
