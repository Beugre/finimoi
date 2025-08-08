import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/transfer_model.dart';

class RealTransferService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection des transferts
  static const String _transfersCollection = 'transfers';
  static const String _contactsCollection = 'contacts';

  /// Obtenir tous les transferts d'un utilisateur (envoyés et reçus) - Version simplifiée pour éviter les erreurs d'index
  static Stream<List<TransferModel>> getUserTransfers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print(
        '🔍 RealTransferService.getUserTransfers: Aucun utilisateur connecté',
      );
      return Stream.value([]);
    }

    print(
      '🔍 RealTransferService.getUserTransfers: Utilisateur connecté: ${currentUser.uid}',
    );

    // Version simplifiée : récupérer tous les transferts et filtrer localement
    return _firestore
        .collection(_transfersCollection)
        .orderBy('createdAt', descending: true)
        .limit(100) // Limiter pour les performances
        .snapshots()
        .map((snapshot) {
          final allTransfers = <TransferModel>[];

          print(
            '🔍 RealTransferService.getUserTransfers: ${snapshot.docs.length} documents récupérés',
          );

          for (final doc in snapshot.docs) {
            try {
              final transfer = TransferModel.fromFirestore(doc);

              // Filtrer pour ne garder que les transferts de l'utilisateur
              if (transfer.senderId == currentUser.uid ||
                  transfer.recipientId == currentUser.uid) {
                allTransfers.add(transfer);
                print(
                  '🔍 ✅ Transfert ajouté: ${transfer.id} - ${transfer.amount} FCFA',
                );
              }
            } catch (e) {
              print('🔍 ❌ Erreur parsing transfert ${doc.id}: $e');
            }
          }

          // Trier par date
          allTransfers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print(
            '🔍 RealTransferService.getUserTransfers: ${allTransfers.length} transferts retournés',
          );
          return allTransfers;
        });
  }

  /// Obtenir les transferts récents (dernières 24h) - envoyés et reçus - Version simplifiée
  static Stream<List<TransferModel>> getRecentTransfers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    // Version simplifiée : récupérer tous les transferts récents et filtrer localement
    return _firestore
        .collection(_transfersCollection)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limiter pour les performances
        .snapshots()
        .map((snapshot) {
          final recentTransfers = <TransferModel>[];

          print(
            '🔍 RealTransferService.getRecentTransfers: ${snapshot.docs.length} documents récupérés',
          );

          for (final doc in snapshot.docs) {
            try {
              final transfer = TransferModel.fromFirestore(doc);

              // Filtrer pour ne garder que les transferts de l'utilisateur et récents
              final isUserTransfer =
                  transfer.senderId == currentUser.uid ||
                  transfer.recipientId == currentUser.uid;
              final isRecent = transfer.createdAt.toDate().isAfter(yesterday);

              if (isUserTransfer && isRecent) {
                recentTransfers.add(transfer);
                print(
                  '🔍 ✅ Transfert récent ajouté: ${transfer.id} - ${transfer.amount} FCFA',
                );
              }
            } catch (e) {
              print('🔍 ❌ Erreur parsing transfert récent ${doc.id}: $e');
            }
          }

          // Trier par date
          recentTransfers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print(
            '🔍 RealTransferService.getRecentTransfers: ${recentTransfers.length} transferts récents retournés',
          );
          return recentTransfers;
        });
  }

  /// Obtenir les contacts fréquents
  static Stream<List<ContactModel>> getFrequentContacts() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection(_contactsCollection)
        .orderBy('lastTransferDate', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ContactModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Ajouter un contact
  static Future<void> addContact(ContactModel contact) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection(_contactsCollection)
        .doc(contact.id)
        .set(contact.toFirestore());
  }

  /// Créer un nouveau transfert
  static Future<String?> createTransfer(TransferModel transfer) async {
    try {
      final docRef = await _firestore
          .collection(_transfersCollection)
          .add(transfer.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création du transfert: $e');
      return null;
    }
  }

  /// Mettre à jour le statut d'un transfert
  static Future<void> updateTransferStatus(
    String transferId,
    TransferStatus newStatus, {
    String? failureReason,
  }) async {
    try {
      final updateData = {
        'status': newStatus.index,
        'updatedAt': Timestamp.now(),
      };

      if (newStatus == TransferStatus.completed) {
        updateData['completedAt'] = Timestamp.now();
      }

      if (failureReason != null) {
        updateData['failureReason'] = failureReason;
      }

      await _firestore
          .collection(_transfersCollection)
          .doc(transferId)
          .update(updateData);
    } catch (e) {
      print('Erreur lors de la mise à jour du transfert: $e');
    }
  }

  /// Obtenir un transfert par ID
  static Future<TransferModel?> getTransferById(String transferId) async {
    try {
      final doc = await _firestore
          .collection(_transfersCollection)
          .doc(transferId)
          .get();

      if (doc.exists) {
        return TransferModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du transfert: $e');
      return null;
    }
  }

  /// Obtenir les statistiques des transferts
  static Future<Map<String, dynamic>> getTransferStats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'totalTransfers': 0,
        'totalAmount': 0.0,
        'successfulTransfers': 0,
        'pendingTransfers': 0,
      };
    }

    try {
      final snapshot = await _firestore
          .collection(_transfersCollection)
          .where('senderId', isEqualTo: currentUser.uid)
          .get();

      int totalTransfers = snapshot.docs.length;
      double totalAmount = 0.0;
      int successfulTransfers = 0;
      int pendingTransfers = 0;

      for (var doc in snapshot.docs) {
        final transfer = TransferModel.fromFirestore(doc);
        totalAmount += transfer.totalAmount;

        if (transfer.status == TransferStatus.completed) {
          successfulTransfers++;
        } else if (transfer.status == TransferStatus.pending ||
            transfer.status == TransferStatus.processing) {
          pendingTransfers++;
        }
      }

      return {
        'totalTransfers': totalTransfers,
        'totalAmount': totalAmount,
        'successfulTransfers': successfulTransfers,
        'pendingTransfers': pendingTransfers,
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {
        'totalTransfers': 0,
        'totalAmount': 0.0,
        'successfulTransfers': 0,
        'pendingTransfers': 0,
      };
    }
  }
}

/// Modèle pour les contacts (simplifié)
class ContactModel {
  final String id;
  final String name;
  final String phone;
  final String? avatar;
  final DateTime? lastTransferDate;

  ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    this.avatar,
    this.lastTransferDate,
  });

  factory ContactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      avatar: data['avatar'],
      lastTransferDate: (data['lastTransferDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'avatar': avatar,
      'lastTransferDate': lastTransferDate != null
          ? Timestamp.fromDate(lastTransferDate!)
          : null,
    };
  }
}
