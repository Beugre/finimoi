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

      // Mettre à jour l'ID avec l'ID du document
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'épargne: $e');
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

        // Vérifier le solde de l'utilisateur
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('Utilisateur introuvable');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final userBalance = (userData['balance'] ?? 0.0).toDouble();

        if (userBalance < amount) {
          throw Exception('Solde insuffisant');
        }

        // Obtenir l'épargne actuelle
        final savingsDoc = await transaction.get(savingsRef);
        if (!savingsDoc.exists) {
          throw Exception('Épargne introuvable');
        }

        final savingsData = savingsDoc.data() as Map<String, dynamic>;
        final currentAmount = (savingsData['currentAmount'] ?? 0.0).toDouble();
        final targetAmount = (savingsData['targetAmount'] ?? 0.0).toDouble();

        final newAmount = currentAmount + amount;
        final isCompleted = newAmount >= targetAmount;

        // Mettre à jour le solde de l'utilisateur
        transaction.update(userRef, {'balance': userBalance - amount});

        // Mettre à jour l'épargne
        transaction.update(savingsRef, {
          'currentAmount': newAmount,
          'isCompleted': isCompleted,
          'lastContributionAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Ajouter l'historique de la contribution
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
    double amount,
  ) async {
    if (amount <= 0) {
      throw Exception('Le montant doit être positif');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final savingsRef = _savingsRef.doc(savingsId);
        final userRef = _firestore.collection('users').doc(userId);

        // Obtenir l'épargne actuelle
        final savingsDoc = await transaction.get(savingsRef);
        if (!savingsDoc.exists) {
          throw Exception('Épargne introuvable');
        }

        final savingsData = savingsDoc.data() as Map<String, dynamic>;
        final currentAmount = (savingsData['currentAmount'] ?? 0.0).toDouble();

        if (currentAmount < amount) {
          throw Exception('Montant insuffisant dans l\'épargne');
        }

        final newAmount = currentAmount - amount;

        // Obtenir l'utilisateur
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('Utilisateur introuvable');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final userBalance = (userData['balance'] ?? 0.0).toDouble();

        // Mettre à jour le solde de l'utilisateur
        transaction.update(userRef, {'balance': userBalance + amount});

        // Mettre à jour l'épargne
        transaction.update(savingsRef, {
          'currentAmount': newAmount,
          'isCompleted': false,
          'lastWithdrawalAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Ajouter l'historique du retrait
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

  // Supprimer une épargne
  Future<void> deleteSavings(String savingsId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final savingsRef = _savingsRef.doc(savingsId);

        // Vérifier que l'épargne appartient à l'utilisateur
        final savingsDoc = await transaction.get(savingsRef);
        if (!savingsDoc.exists) {
          throw Exception('Épargne introuvable');
        }

        final savingsData = savingsDoc.data() as Map<String, dynamic>;
        if (savingsData['userId'] != userId) {
          throw Exception(
            'Vous n\'êtes pas autorisé à supprimer cette épargne',
          );
        }

        final currentAmount = (savingsData['currentAmount'] ?? 0.0).toDouble();

        // Rembourser le montant épargné à l'utilisateur
        if (currentAmount > 0) {
          final userRef = _firestore.collection('users').doc(userId);
          final userDoc = await transaction.get(userRef);

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final userBalance = (userData['balance'] ?? 0.0).toDouble();

            transaction.update(userRef, {
              'balance': userBalance + currentAmount,
            });
          }
        }

        // Supprimer l'épargne
        transaction.delete(savingsRef);
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'épargne: $e');
    }
  }

  // Obtenir les statistiques d'épargne
  Future<Map<String, dynamic>> getSavingsStats(String userId) async {
    try {
      final snapshot = await _savingsRef
          .where('userId', isEqualTo: userId)
          .get();

      double totalSaved = 0;
      double totalTarget = 0;
      int activeSavings = 0;
      int completedSavings = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final currentAmount = (data['currentAmount'] ?? 0.0).toDouble();
        final targetAmount = (data['targetAmount'] ?? 0.0).toDouble();
        final isActive = data['isActive'] ?? true;
        final isCompleted = data['isCompleted'] ?? false;

        totalSaved += currentAmount;
        totalTarget += targetAmount;

        if (isActive) {
          activeSavings++;
        }
        if (isCompleted) {
          completedSavings++;
        }
      }

      return {
        'totalSaved': totalSaved,
        'totalTarget': totalTarget,
        'activeSavings': activeSavings,
        'completedSavings': completedSavings,
        'totalSavings': snapshot.docs.length,
        'progressPercentage': totalTarget > 0
            ? (totalSaved / totalTarget) * 100
            : 0.0,
      };
    } catch (e) {
      return {
        'totalSaved': 0.0,
        'totalTarget': 0.0,
        'activeSavings': 0,
        'completedSavings': 0,
        'totalSavings': 0,
        'progressPercentage': 0.0,
      };
    }
  }

  // Obtenir l'historique des contributions
  Stream<List<Map<String, dynamic>>> getContributionHistory(String savingsId) {
    return _savingsRef
        .doc(savingsId)
        .collection('contributions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList();
        });
  }

  // Obtenir l'historique des retraits
  Stream<List<Map<String, dynamic>>> getWithdrawalHistory(String savingsId) {
    return _savingsRef
        .doc(savingsId)
        .collection('withdrawals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList();
        });
  }
}
