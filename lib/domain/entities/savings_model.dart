import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final bool isActive;
  final bool isCompleted;
  final bool autoSave;
  final double autoSaveAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastContributionAt;
  final DateTime? lastWithdrawalAt;
  final Map<String, dynamic>? metadata;

  SavingsModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.isActive,
    required this.isCompleted,
    required this.autoSave,
    required this.autoSaveAmount,
    required this.createdAt,
    required this.updatedAt,
    this.lastContributionAt,
    this.lastWithdrawalAt,
    this.metadata,
  });

  // Factory constructor depuis Firestore
  factory SavingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SavingsModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      targetAmount: (data['targetAmount'] ?? 0.0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0.0).toDouble(),
      targetDate:
          (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      isCompleted: data['isCompleted'] ?? false,
      autoSave: data['autoSave'] ?? false,
      autoSaveAmount: (data['autoSaveAmount'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastContributionAt: (data['lastContributionAt'] as Timestamp?)?.toDate(),
      lastWithdrawalAt: (data['lastWithdrawalAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': Timestamp.fromDate(targetDate),
      'isActive': isActive,
      'isCompleted': isCompleted,
      'autoSave': autoSave,
      'autoSaveAmount': autoSaveAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastContributionAt': lastContributionAt != null
          ? Timestamp.fromDate(lastContributionAt!)
          : null,
      'lastWithdrawalAt': lastWithdrawalAt != null
          ? Timestamp.fromDate(lastWithdrawalAt!)
          : null,
      'metadata': metadata,
    };
  }

  // Getters utiles
  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0.0;

  double get remainingAmount =>
      targetAmount > currentAmount ? targetAmount - currentAmount : 0.0;

  int get daysRemaining {
    final now = DateTime.now();
    return targetDate.isAfter(now) ? targetDate.difference(now).inDays : 0;
  }

  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;

  String get statusText {
    if (isCompleted) return 'Objectif atteint';
    if (isOverdue) return 'En retard';
    if (!isActive) return 'Suspendu';
    return 'En cours';
  }

  // Méthode copyWith pour créer une copie avec modifications
  SavingsModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    bool? isActive,
    bool? isCompleted,
    bool? autoSave,
    double? autoSaveAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastContributionAt,
    DateTime? lastWithdrawalAt,
    Map<String, dynamic>? metadata,
  }) {
    return SavingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      autoSave: autoSave ?? this.autoSave,
      autoSaveAmount: autoSaveAmount ?? this.autoSaveAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastContributionAt: lastContributionAt ?? this.lastContributionAt,
      lastWithdrawalAt: lastWithdrawalAt ?? this.lastWithdrawalAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'SavingsModel(id: $id, title: $title, targetAmount: $targetAmount, currentAmount: $currentAmount, progressPercentage: ${progressPercentage.toStringAsFixed(1)}%)';
  }
}
