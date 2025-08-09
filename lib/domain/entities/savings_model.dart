import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsModel {
  final String id;
  final String userId;
  final String goalName;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final double monthlyContribution;
  final DateTime deadline;
  final bool isLocked;
  final bool isCompleted;
  final double interestRate;
  final bool autoSave;
  final double autoSaveAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? approverId;

  SavingsModel({
    required this.id,
    required this.userId,
    required this.goalName,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.monthlyContribution,
    required this.deadline,
    required this.isLocked,
    required this.isCompleted,
    required this.interestRate,
    this.autoSave = false,
    this.autoSaveAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.approverId,
  });

  factory SavingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      goalName: data['goalName'] ?? '',
      description: data['description'] ?? '',
      targetAmount: (data['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0.0).toDouble(),
      monthlyContribution: (data['monthlyContribution'] ?? 0.0).toDouble(),
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLocked: data['isLocked'] ?? false,
      isCompleted: data['isCompleted'] ?? false,
      interestRate: (data['interestRate'] ?? 0.0).toDouble(),
      autoSave: data['autoSave'] ?? false,
      autoSaveAmount: (data['autoSaveAmount'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approverId: data['approverId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'goalName': goalName,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'monthlyContribution': monthlyContribution,
      'deadline': Timestamp.fromDate(deadline),
      'isLocked': isLocked,
      'isCompleted': isCompleted,
      'interestRate': interestRate,
      'autoSave': autoSave,
      'autoSaveAmount': autoSaveAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'approverId': approverId,
    };
  }

  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0.0;

  double get remainingAmount =>
      targetAmount > currentAmount ? targetAmount - currentAmount : 0.0;

  int get daysRemaining {
    final now = DateTime.now();
    return deadline.isAfter(now) ? deadline.difference(now).inDays : 0;
  }

  bool get isOverdue => DateTime.now().isAfter(deadline) && !isCompleted;

  String get statusText {
    if (isCompleted) return 'Objectif atteint';
    if (isOverdue) return 'En retard';
    if (isLocked && deadline.isAfter(DateTime.now())) return 'Bloqué';
    return 'En cours';
  }

  SavingsModel copyWith({
    String? id,
    String? userId,
    String? goalName,
    String? description,
    double? targetAmount,
    double? currentAmount,
    double? monthlyContribution,
    DateTime? deadline,
    bool? isLocked,
    bool? isCompleted,
    double? interestRate,
    bool? autoSave,
    double? autoSaveAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? approverId,
  }) {
    return SavingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalName: goalName ?? this.goalName,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      deadline: deadline ?? this.deadline,
      isLocked: isLocked ?? this.isLocked,
      isCompleted: isCompleted ?? this.isCompleted,
      interestRate: interestRate ?? this.interestRate,
      autoSave: autoSave ?? this.autoSave,
      autoSaveAmount: autoSaveAmount ?? this.autoSaveAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approverId: approverId ?? this.approverId,
    );
  }

  @override
  String toString() {
    return 'SavingsModel(id: $id, goalName: $goalName, targetAmount: $targetAmount, currentAmount: $currentAmount, progressPercentage: ${progressPercentage.toStringAsFixed(1)}%)';
  }
}
