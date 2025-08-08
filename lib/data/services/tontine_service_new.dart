import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../domain/entities/tontine_model.dart';
import '../../core/constants/app_constants.dart';

class TontineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _tontinesCollection =>
      _firestore.collection(AppConstants.tontinesCollection);

  // Créer une nouvelle tontine
  Future<String> createTontine({
    required String name,
    required String description,
    required String creatorId,
    required String creatorName,
    required double contributionAmount,
    required TontineFrequency frequency,
    required TontineType type,
    required int maxMembers,
    required DateTime startDate,
    required Map<String, dynamic> rules,
    String? imageUrl,
    bool isPrivate = false,
  }) async {
    try {
      // Vérification de l'utilisateur connecté
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      if (currentUser.uid != creatorId) {
        throw Exception(
          'Vous ne pouvez créer une tontine qu\'avec votre propre compte',
        );
      }

      final tontine = TontineModel(
        id: '',
        name: name,
        description: description,
        creatorId: creatorId,
        creatorName: creatorName,
        contributionAmount: contributionAmount,
        frequency: frequency,
        type: type,
        status: TontineStatus.draft,
        maxMembers: maxMembers,
        currentMembers: 1,
        currentCycle: 1,
        startDate: startDate,
        memberIds: [creatorId],
        members: [
          TontineMember(
            userId: creatorId,
            name: creatorName,
            joinedAt: DateTime.now(),
            isActive: true,
            position: 1,
          ),
        ],
        cycles: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrl: imageUrl,
        rules: rules,
        isPrivate: isPrivate,
        inviteCode: isPrivate ? _generateInviteCode() : null,
      );

      final docRef = await _tontinesCollection.add(tontine.toFirestore());

      // Mettre à jour l'ID dans le document
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      print('Erreur création tontine: $e');
      throw Exception('Erreur lors de la création: $e');
    }
  }

  // Rejoindre une tontine
  Future<bool> joinTontine(
    String tontineId,
    String userId,
    String userName, {
    String? inviteCode,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Utilisateur non autorisé');
      }

      return await _firestore.runTransaction((transaction) async {
        final tontineDoc = await transaction.get(
          _tontinesCollection.doc(tontineId),
        );

        if (!tontineDoc.exists) {
          throw Exception('Tontine non trouvée');
        }

        final tontine = TontineModel.fromFirestore(tontineDoc);

        if (tontine.memberIds.contains(userId)) {
          throw Exception('Vous êtes déjà membre de cette tontine');
        }

        if (tontine.isPrivate && tontine.inviteCode != inviteCode) {
          throw Exception('Code d\'invitation invalide');
        }

        if (tontine.currentMembers >= tontine.maxMembers) {
          throw Exception('Cette tontine est complète');
        }

        if (tontine.status != TontineStatus.draft) {
          throw Exception('Cette tontine a déjà démarré');
        }

        final newMember = TontineMember(
          userId: userId,
          name: userName,
          joinedAt: DateTime.now(),
          isActive: true,
          position: tontine.currentMembers + 1,
        );

        transaction.update(_tontinesCollection.doc(tontineId), {
          'memberIds': FieldValue.arrayUnion([userId]),
          'members': FieldValue.arrayUnion([newMember.toMap()]),
          'currentMembers': FieldValue.increment(1),
          'updatedAt': Timestamp.now(),
        });

        return true;
      });
    } catch (e) {
      print('Erreur adhésion tontine: $e');
      throw Exception('Erreur lors de l\'adhésion: $e');
    }
  }

  // Démarrer une tontine
  Future<void> startTontine(String tontineId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _firestore.runTransaction((transaction) async {
        final tontineDoc = await transaction.get(
          _tontinesCollection.doc(tontineId),
        );

        if (!tontineDoc.exists) {
          throw Exception('Tontine non trouvée');
        }

        final tontine = TontineModel.fromFirestore(tontineDoc);

        // Vérifier que c'est le créateur
        if (tontine.creatorId != currentUser.uid) {
          throw Exception('Seul le créateur peut démarrer la tontine');
        }

        if (tontine.status != TontineStatus.draft) {
          throw Exception('Cette tontine a déjà été démarrée');
        }

        if (tontine.currentMembers < 2) {
          throw Exception('Il faut au moins 2 membres pour démarrer');
        }

        // Générer l'ordre de paiement aléatoire
        final shuffledMemberIds = [...tontine.memberIds]..shuffle(Random());
        final cycles = _generateCycles(tontine, shuffledMemberIds);

        transaction.update(_tontinesCollection.doc(tontineId), {
          'status': TontineStatus.active.name,
          'cycles': cycles.map((c) => c.toMap()).toList(),
          'startDate': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.now(),
        });
      });

      // Notifier tous les membres
      await _sendTontineNotification(
        tontineId,
        'Tontine démarrée',
        'La tontine a officiellement démarré !',
      );
    } catch (e) {
      print('Erreur démarrage tontine: $e');
      throw Exception('Erreur lors du démarrage: $e');
    }
  }

  // Effectuer une contribution
  Future<bool> makeContribution(
    String tontineId,
    String userId,
    double amount,
    int cycleNumber,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Utilisateur non autorisé');
      }

      return await _firestore.runTransaction((transaction) async {
        final tontineDoc = await transaction.get(
          _tontinesCollection.doc(tontineId),
        );

        if (!tontineDoc.exists) {
          throw Exception('Tontine non trouvée');
        }

        final tontine = TontineModel.fromFirestore(tontineDoc);

        if (!tontine.memberIds.contains(userId)) {
          throw Exception('Vous n\'êtes pas membre de cette tontine');
        }

        if (tontine.status != TontineStatus.active) {
          throw Exception('Cette tontine n\'est pas active');
        }

        if (amount != tontine.contributionAmount) {
          throw Exception('Montant de contribution incorrect');
        }

        // Vérifier que l'utilisateur n'a pas déjà contribué pour ce cycle
        final currentCycle = tontine.cycles.firstWhere(
          (c) => c.cycleNumber == cycleNumber,
          orElse: () => throw Exception('Cycle non trouvé'),
        );

        if (currentCycle.contributions.any((c) => c.memberId == userId)) {
          throw Exception('Vous avez déjà contribué pour ce cycle');
        }

        // Récupérer le nom du membre
        final member = tontine.members.firstWhere(
          (m) => m.userId == userId,
          orElse: () => throw Exception('Membre non trouvé'),
        );

        final contribution = TontineContribution(
          memberId: userId,
          memberName: member.name,
          amount: amount,
          contributionDate: DateTime.now(),
          isPaid: true,
        );

        // Mettre à jour les cycles dans la tontine
        final updatedCycles = tontine.cycles.map((cycle) {
          if (cycle.cycleNumber == cycleNumber) {
            return TontineCycle(
              cycleNumber: cycle.cycleNumber,
              winnerId: cycle.winnerId,
              winnerName: cycle.winnerName,
              beneficiaryName: cycle.beneficiaryName,
              startDate: cycle.startDate,
              endDate: cycle.endDate,
              payoutDate: cycle.payoutDate,
              amount: cycle.amount,
              totalAmount: cycle.totalAmount,
              contributions: [...cycle.contributions, contribution],
              isCompleted: cycle.isCompleted,
            );
          }
          return cycle;
        }).toList();

        transaction.update(_tontinesCollection.doc(tontineId), {
          'cycles': updatedCycles.map((c) => c.toMap()).toList(),
          'updatedAt': Timestamp.now(),
        });

        return true;
      });
    } catch (e) {
      print('Erreur contribution: $e');
      throw Exception('Erreur lors de la contribution: $e');
    }
  }

  // Récupérer les tontines de l'utilisateur
  Stream<List<TontineModel>> getUserTontines(String userId) {
    return _tontinesCollection
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TontineModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Récupérer les tontines publiques disponibles
  Stream<List<TontineModel>> getAvailableTontines() {
    return _tontinesCollection
        .where('isPrivate', isEqualTo: false)
        .where('status', isEqualTo: TontineStatus.draft.name)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TontineModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Récupérer une tontine par ID
  Stream<TontineModel?> getTontineById(String tontineId) {
    return _tontinesCollection.doc(tontineId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return TontineModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  // Rechercher des tontines
  Future<List<TontineModel>> searchTontines(String query) async {
    try {
      final snapshot = await _tontinesCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .where('isPrivate', isEqualTo: false)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => TontineModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur recherche: $e');
      return [];
    }
  }

  // Générer les cycles d'une tontine
  List<TontineCycle> _generateCycles(
    TontineModel tontine,
    List<String> memberOrder,
  ) {
    final cycles = <TontineCycle>[];
    final frequencyDays = _getFrequencyDays(tontine.frequency);

    for (int i = 0; i < tontine.currentMembers; i++) {
      final cycleDate = tontine.startDate.add(
        Duration(days: frequencyDays * i),
      );
      final beneficiaryId = memberOrder[i];
      final beneficiary = tontine.members.firstWhere(
        (m) => m.userId == beneficiaryId,
      );

      cycles.add(
        TontineCycle(
          cycleNumber: i + 1,
          winnerId: beneficiaryId,
          winnerName: beneficiary.name,
          beneficiaryName: beneficiary.name,
          startDate: cycleDate,
          endDate: cycleDate.add(Duration(days: frequencyDays)),
          payoutDate: cycleDate.add(Duration(days: frequencyDays)),
          amount: tontine.contributionAmount * tontine.currentMembers,
          totalAmount: tontine.contributionAmount * tontine.currentMembers,
          contributions: [],
          isCompleted: false,
        ),
      );
    }

    return cycles;
  }

  // Calculer les jours selon la fréquence
  int _getFrequencyDays(TontineFrequency frequency) {
    switch (frequency) {
      case TontineFrequency.weekly:
        return 7;
      case TontineFrequency.biweekly:
        return 14;
      case TontineFrequency.monthly:
        return 30;
      case TontineFrequency.quarterly:
        return 90;
    }
  }

  // Générer un code d'invitation
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Envoyer une notification à tous les membres
  Future<void> _sendTontineNotification(
    String tontineId,
    String title,
    String message,
  ) async {
    try {
      await _firestore.collection(AppConstants.notificationsCollection).add({
        'tontineId': tontineId,
        'title': title,
        'message': message,
        'type': 'tontine',
        'createdAt': Timestamp.now(),
        'isRead': false,
      });
    } catch (e) {
      print('Erreur notification: $e');
    }
  }
}
