import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/savings_model.dart';

final realSavingsServiceProvider = Provider<RealSavingsService>((ref) {
  return RealSavingsService();
});

class RealSavingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _savingsRef => _firestore.collection('savings');

  // Obtenir les épargnes de l'utilisateur
  Stream<List<SavingsModel>> getUserSavings(String userId) {
    return _savingsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return SavingsModel.fromFirestore(doc);
                } catch (e) {
                  print('Erreur lors du parsing de l\'épargne ${doc.id}: $e');
                  return null;
                }
              })
              .where((savings) => savings != null)
              .cast<SavingsModel>()
              .toList();
        });
  }

  // Obtenir une épargne par ID
  Stream<SavingsModel?> getSavingsById(String savingsId) {
    return _savingsRef.doc(savingsId).snapshots().map((doc) {
      if (!doc.exists) return null;
      try {
        return SavingsModel.fromFirestore(doc);
      } catch (e) {
        print('Erreur lors du parsing de l\'épargne $savingsId: $e');
        return null;
      }
    });
  }

  // Créer une nouvelle épargne
  Future<String> createSavings(SavingsModel savings) async {
    try {
      final docRef = await _savingsRef.add(savings.toFirestore());
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'épargne: $e');
    }
  }

  // Mettre à jour une épargne
  Future<void> updateSavings(String savingsId, Map<String, dynamic> data) async {
    try {
      await _savingsRef.doc(savingsId).update(data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'épargne: $e');
    }
  }

  // Ajouter de l'argent à une épargne
  Future<void> addToSavings(
    String savingsId,
    String userId,
    double amount,
  ) async {
    if (amount <= 0) {
      throw Exception('Le montant doit être positif');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final savingsRef = _savingsRef.doc(savingsId);
        final userRef = _firestore.collection('users').doc(userId);

        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception('Utilisateur introuvable');
        final userData = userDoc.data() as Map<String, dynamic>;
        final userBalance = (userData['balance'] ?? 0.0).toDouble();
        if (userBalance < amount) throw Exception('Solde insuffisant');

        final savingsDoc = await transaction.get(savingsRef);
        if (!savingsDoc.exists) throw Exception('Épargne introuvable');
        final savingsData = savingsDoc.data() as Map<String, dynamic>;
        final currentAmount = (savingsData['currentAmount'] ?? 0.0).toDouble();
        final targetAmount = (savingsData['targetAmount'] ?? 0.0).toDouble();
        final newAmount = currentAmount + amount;

        transaction.update(userRef, {'balance': userBalance - amount});
        transaction.update(savingsRef, {
          'currentAmount': newAmount,
          'isCompleted': newAmount >= targetAmount,
          'updatedAt': Timestamp.now(),
        });

        final contributionRef = savingsRef.collection('contributions').doc();
        transaction.set(contributionRef, {
          'amount': amount,
          'createdAt': Timestamp.now(),
          'userId': userId,
        });
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout à l\'épargne: $e');
    }
  }

  // Retirer de l'argent d'une épargne
  Future<void> withdrawFromSavings(
    String savingsId,
    String userId,
    double amount, {
    bool bypassApproval = false,
  }) async {
    if (amount <= 0) {
      throw Exception('Le montant doit être positif');
    }

    final savingsRef = _savingsRef.doc(savingsId);
    final savingsDoc = await savingsRef.get();
    if (!savingsDoc.exists) {
      throw Exception('Épargne introuvable');
    }
    final savings = SavingsModel.fromFirestore(savingsDoc);

    if (savings.approverId != null &&
        savings.approverId!.isNotEmpty &&
        !bypassApproval) {
      await _createWithdrawalRequest(savingsId, userId, amount);
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);

        if (savings.isLocked && savings.deadline.isAfter(DateTime.now())) {
          throw Exception('Cette épargne est bloquée jusqu\'à la date d\'échéance.');
        }

        if (savings.currentAmount < amount) {
          throw Exception('Montant insuffisant dans l\'épargne');
        }

        final newAmount = savings.currentAmount - amount;

        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception('Utilisateur introuvable');
        final userData = userDoc.data() as Map<String, dynamic>;
        final userBalance = (userData['balance'] ?? 0.0).toDouble();

        transaction.update(userRef, {'balance': userBalance + amount});
        transaction.update(savingsRef, {
          'currentAmount': newAmount,
          'isCompleted': false,
          'updatedAt': Timestamp.now(),
        });

        final withdrawalRef = savingsRef.collection('withdrawals').doc();
        transaction.set(withdrawalRef, {
          'amount': amount,
          'createdAt': Timestamp.now(),
          'userId': userId,
        });
      });
    } catch (e) {
      throw Exception('Erreur lors du retrait de l\'épargne: $e');
    }
  }

  Future<void> _createWithdrawalRequest(
      String savingsId, String userId, double amount) async {
    final requestRef =
        _savingsRef.doc(savingsId).collection('withdrawal_requests').doc();
    await requestRef.set({
      'userId': userId,
      'amount': amount,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> approveWithdrawalRequest(
      String savingsId, String requestId) async {
    final requestRef =
        _savingsRef.doc(savingsId).collection('withdrawal_requests').doc(requestId);
    final requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
      throw Exception('Demande de retrait introuvable');
    }

    final requestData = requestDoc.data() as Map<String, dynamic>;
    final userId = requestData['userId'];
    final amount = requestData['amount'];

    await withdrawFromSavings(savingsId, userId, amount, bypassApproval: true);
    await requestRef.update({'status': 'approved'});
  }

  // Simulated scheduled function to calculate and apply interest
  Future<void> calculateAndApplyInterest() async {
    final snapshot = await _savingsRef.where('isCompleted', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final savings = SavingsModel.fromFirestore(doc);
      final monthlyRate = savings.interestRate / 12;
      final interestAmount = savings.currentAmount * monthlyRate;
      if (interestAmount > 0) {
        batch.update(doc.reference, {
          'currentAmount': FieldValue.increment(interestAmount),
          'updatedAt': Timestamp.now(),
        });
      }
    }
    await batch.commit();
  }

  // Simulated scheduled function to process automatic deposits
  Future<void> processAutomaticDeposits() async {
    final snapshot = await _savingsRef.where('autoSave', isEqualTo: true).get();
    for (final doc in snapshot.docs) {
      final savings = SavingsModel.fromFirestore(doc);
      if (savings.autoSaveAmount > 0) {
        try {
          await addToSavings(
              savings.id, savings.userId, savings.autoSaveAmount);
        } catch (e) {
          print('Failed to process auto-deposit for ${savings.id}: $e');
        }
      }
    }
  }
}
