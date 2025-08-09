import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tontine_model.dart';
import 'notification_service.dart';

final realTontineServiceProvider = Provider<RealTontineService>((ref) {
  return RealTontineService();
});

class RealTontineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _tontinesRef => _firestore.collection('tontines');

  // Obtenir les tontines de l'utilisateur
  Stream<List<TontineModel>> getUserTontines(String userId) {
    return _tontinesRef.where('members', arrayContains: userId).snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return TontineModel.fromFirestore(doc);
              } catch (e) {
                print('Erreur lors du parsing de la tontine ${doc.id}: $e');
                return null;
              }
            })
            .where((tontine) => tontine != null)
            .cast<TontineModel>()
            .toList();
      },
    );
  }

  // Obtenir toutes les tontines disponibles
  Stream<List<TontineModel>> getAvailableTontines() {
    return _tontinesRef
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return TontineModel.fromFirestore(doc);
                } catch (e) {
                  print('Erreur lors du parsing de la tontine ${doc.id}: $e');
                  return null;
                }
              })
              .where((tontine) => tontine != null)
              .cast<TontineModel>()
              .toList();
        });
  }

  // Obtenir une tontine par ID
  Stream<TontineModel?> getTontineById(String tontineId) {
    return _tontinesRef.doc(tontineId).snapshots().map((doc) {
      if (!doc.exists) return null;
      try {
        return TontineModel.fromFirestore(doc);
      } catch (e) {
        print('Erreur lors du parsing de la tontine $tontineId: $e');
        return null;
      }
    });
  }

  // Créer une nouvelle tontine
  Future<String> createTontine(TontineModel tontine) async {
    try {
      final docRef = await _tontinesRef.add(tontine.toFirestore());

      // Mettre à jour l'ID avec l'ID du document
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la tontine: $e');
    }
  }

  // Rejoindre une tontine
  Future<void> joinTontine(String tontineId, String userId) async {
    try {
      await _tontinesRef.doc(tontineId).update({
        'members': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la jonction à la tontine: $e');
    }
  }

  // Quitter une tontine
  Future<void> leaveTontine(String tontineId, String userId) async {
    try {
      await _tontinesRef.doc(tontineId).update({
        'members': FieldValue.arrayRemove([userId]),
        'memberCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la sortie de la tontine: $e');
    }
  }

  // Effectuer une contribution
  Future<void> makeContribution(
    String tontineId,
    String userId,
    double amount,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final tontineRef = _tontinesRef.doc(tontineId);
        final contributionRef = tontineRef.collection('contributions').doc();

        // Ajouter la contribution
        transaction.set(contributionRef, {
          'userId': userId,
          'amount': amount,
          'createdAt': Timestamp.now(),
          'round': 1, // À calculer selon la logique métier
        });

        // Mettre à jour le montant total collecté
        transaction.update(tontineRef, {
          'totalCollected': FieldValue.increment(amount),
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Erreur lors de la contribution: $e');
    }
  }

  // Rechercher des tontines
  Future<List<TontineModel>> searchTontines(String query) async {
    if (query.isEmpty) {
      final snapshot = await _tontinesRef
          .where('isActive', isEqualTo: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return TontineModel.fromFirestore(doc);
            } catch (e) {
              print('Erreur lors du parsing de la tontine ${doc.id}: $e');
              return null;
            }
          })
          .where((tontine) => tontine != null)
          .cast<TontineModel>()
          .toList();
    }

    // Recherche par titre (simplifiée)
    final snapshot = await _tontinesRef
        .where('isActive', isEqualTo: true)
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) {
          try {
            return TontineModel.fromFirestore(doc);
          } catch (e) {
            print('Erreur lors du parsing de la tontine ${doc.id}: $e');
            return null;
          }
        })
        .where((tontine) => tontine != null)
        .cast<TontineModel>()
        .toList();
  }

  // Obtenir les statistiques des tontines
  Future<Map<String, dynamic>> getTontineStats(String userId) async {
    try {
      // Tontines actives de l'utilisateur
      final activeTontines = await _tontinesRef
          .where('members', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      // Contributions totales
      double totalContributions = 0;
      for (final tontineDoc in activeTontines.docs) {
        final contributions = await tontineDoc.reference
            .collection('contributions')
            .where('userId', isEqualTo: userId)
            .get();

        for (final contrib in contributions.docs) {
          totalContributions += (contrib.data()['amount'] ?? 0.0).toDouble();
        }
      }

      return {
        'activeTontinesCount': activeTontines.docs.length,
        'totalContributions': totalContributions,
        'averageContribution': activeTontines.docs.isNotEmpty
            ? totalContributions / activeTontines.docs.length
            : 0.0,
      };
    } catch (e) {
      return {
        'activeTontinesCount': 0,
        'totalContributions': 0.0,
        'averageContribution': 0.0,
      };
    }
  }

  // Simulated scheduled function to send reminders
  Future<void> sendTontineReminders() async {
    final notificationService = NotificationService();
    final now = DateTime.now();

    final snapshot = await _tontinesRef
        .where('status', isEqualTo: TontineStatus.active.name)
        .get();

    for (final doc in snapshot.docs) {
      final tontine = TontineModel.fromFirestore(doc);
      final dueDate = tontine.nextDueDate;

      // Send reminder 3 days before due date
      if (dueDate.isAfter(now) && dueDate.difference(now).inDays <= 3) {
        for (final memberId in tontine.memberIds) {
          await notificationService.createNotification(
            userId: memberId,
            title: 'Rappel de Tontine',
            message:
                'Votre contribution de ${tontine.contributionAmount.toInt()} FCFA pour la tontine "${tontine.name}" est bientôt due!',
            type: 'tontine_reminder',
            data: {'tontineId': tontine.id},
          );
        }
      }
    }
  }

  Future<void> updateAutoPayStatus(
      String tontineId, String userId, bool autoPayEnabled) async {
    try {
      final tontineDoc = await _tontinesRef.doc(tontineId).get();
      if (!tontineDoc.exists) {
        throw Exception('Tontine non trouvée');
      }

      final tontineData = tontineDoc.data() as Map<String, dynamic>;
      final members =
          (tontineData['members'] as List<dynamic>?)?.map((m) => m as Map<String, dynamic>).toList() ?? [];

      final memberIndex = members.indexWhere((m) => m['userId'] == userId);
      if (memberIndex == -1) {
        throw Exception('Membre non trouvé dans cette tontine');
      }

      members[memberIndex]['autoPayEnabled'] = autoPayEnabled;

      await _tontinesRef.doc(tontineId).update({
        'members': members,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut de paiement automatique: $e');
    }
  }

  // Simulated scheduled function to process automatic payments
  Future<void> processAutomaticPayments() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snapshot = await _tontinesRef
        .where('status', isEqualTo: TontineStatus.active.name)
        .get();

    for (final doc in snapshot.docs) {
      final tontine = TontineModel.fromFirestore(doc);
      final dueDate = tontine.nextDueDate;
      final todayDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

      if (todayDueDate == today) {
        for (final member in tontine.members) {
          if (member.autoPayEnabled && member.isActive) {
            try {
              // It's better to call the existing makeContribution method
              // This is a simulation, in a real app, this would be more robust
              await makeContribution(tontine.id, member.userId, tontine.contributionAmount);
              print('Automatic payment processed for ${member.name} in tontine ${tontine.name}');
            } catch (e) {
              print('Failed to process automatic payment for ${member.name}: $e');
              // Optionally, send a notification to the user about the failure
            }
          }
        }
      }
    }
  }
}
