import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/savings_goal.dart';

class SavingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _savingsGoalsCollection =>
      _firestore.collection('savings_goals');
  CollectionReference get _savingsPlansCollection =>
      _firestore.collection('savings_plans');

  // Get user's savings goals
  Stream<List<SavingsGoal>> getUserSavingsGoals(String userId) {
    return _savingsGoalsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SavingsGoal.fromFirestore(doc))
              .toList(),
        );
  }

  // Get available savings plans
  Stream<List<SavingsPlan>> getAvailableSavingsPlans() {
    return _savingsPlansCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SavingsPlan.fromFirestore(doc))
              .toList(),
        );
  }

  // Create a new savings goal
  Future<void> createSavingsGoal(SavingsGoal goal) async {
    await _savingsGoalsCollection.add(goal.toFirestore());
  }

  // Update savings goal
  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await _savingsGoalsCollection.doc(goal.id).update(goal.toFirestore());
  }

  // Delete savings goal
  Future<void> deleteSavingsGoal(String goalId) async {
    await _savingsGoalsCollection.doc(goalId).delete();
  }

  // Add contribution to savings goal
  Future<void> addContribution(String goalId, double amount) async {
    await _firestore.runTransaction((transaction) async {
      final goalDoc = await transaction.get(
        _savingsGoalsCollection.doc(goalId),
      );
      if (!goalDoc.exists) throw Exception('Objectif d\'épargne introuvable');

      final goalData = goalDoc.data() as Map<String, dynamic>;
      final currentAmount = (goalData['currentAmount'] ?? 0).toDouble();
      final newAmount = currentAmount + amount;

      final contribution = SavingsContribution(
        amount: amount,
        date: DateTime.now(),
        source: 'manual',
      );

      final contributions = List<Map<String, dynamic>>.from(
        goalData['contributions'] ?? [],
      );
      contributions.add(contribution.toMap());

      transaction.update(_savingsGoalsCollection.doc(goalId), {
        'currentAmount': newAmount,
        'contributions': contributions,
        'status': newAmount >= (goalData['targetAmount'] ?? 0)
            ? 'completed'
            : 'active',
      });
    });
  }

  // Withdraw from savings goal
  Future<void> withdrawFromGoal(String goalId, double amount) async {
    await _firestore.runTransaction((transaction) async {
      final goalDoc = await transaction.get(
        _savingsGoalsCollection.doc(goalId),
      );
      if (!goalDoc.exists) throw Exception('Objectif d\'épargne introuvable');

      final goalData = goalDoc.data() as Map<String, dynamic>;
      final currentAmount = (goalData['currentAmount'] ?? 0).toDouble();

      if (currentAmount < amount) {
        throw Exception('Montant insuffisant dans l\'objectif d\'épargne');
      }

      final newAmount = currentAmount - amount;

      transaction.update(_savingsGoalsCollection.doc(goalId), {
        'currentAmount': newAmount,
        'status': newAmount >= (goalData['targetAmount'] ?? 0)
            ? 'completed'
            : 'active',
      });
    });
  }

  // Get savings goal by id
  Future<SavingsGoal?> getSavingsGoalById(String goalId) async {
    final doc = await _savingsGoalsCollection.doc(goalId).get();
    if (doc.exists) {
      return SavingsGoal.fromFirestore(doc);
    }
    return null;
  }

  // Get total savings amount for user
  Future<double> getTotalSavingsAmount(String userId) async {
    final goals = await _savingsGoalsCollection
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'completed'])
        .get();

    double total = 0;
    for (final doc in goals.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['currentAmount'] ?? 0).toDouble();
    }
    return total;
  }
}

// Providers
final savingsServiceProvider = Provider<SavingsService>((ref) {
  return SavingsService();
});

final userSavingsGoalsProvider =
    StreamProvider.family<List<SavingsGoal>, String>((ref, userId) {
      final savingsService = ref.watch(savingsServiceProvider);
      return savingsService.getUserSavingsGoals(userId);
    });

final availableSavingsPlansProvider = StreamProvider<List<SavingsPlan>>((ref) {
  final savingsService = ref.watch(savingsServiceProvider);
  return savingsService.getAvailableSavingsPlans();
});

final totalSavingsAmountProvider = FutureProvider.family<double, String>((
  ref,
  userId,
) {
  final savingsService = ref.watch(savingsServiceProvider);
  return savingsService.getTotalSavingsAmount(userId);
});
