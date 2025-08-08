import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tontine_model.dart';

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
}
