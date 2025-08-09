import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/transfer_model.dart';
import '../../domain/entities/user_model.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_service.dart';
import 'gamification_service.dart';
import 'notification_service.dart';
import 'real_savings_service.dart';
import 'user_service.dart';
import '../../domain/entities/challenge_model.dart';

class TransferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupère TOUTES les transactions d'un utilisateur (seulement les envoyées pour debug)
  Stream<List<TransferModel>> getUserTransfers(String userId) {
    // Pour l'instant, récupérons seulement les transferts envoyés pour débugger
    // TODO: Implémenter la combinaison avec les transferts reçus
    return _firestore
        .collection('transactions')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransferModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Effectue un transfert d'argent
  Future<TransferResult> performTransfer(TransferRequest request) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return TransferResult.error('Utilisateur non connecté');
      }

      // Vérification : empêcher l'auto-transfert
      if (request.type == TransferType.internal &&
          request.recipientId == currentUser.uid) {
        return TransferResult.error(
          'Vous ne pouvez pas vous envoyer de l\'argent à vous-même',
        );
      }

      // Vérification du solde
      final senderBalance = await getUserBalance(currentUser.uid);
      if (senderBalance < request.amount + request.fees) {
        return TransferResult.error('Solde insuffisant');
      }

      // Création de la transaction
      final transferId = _firestore.collection('transactions').doc().id;
      final transfer = TransferModel(
        id: transferId,
        senderId: currentUser.uid,
        recipientId: request.recipientId,
        recipientPhone: request.recipientPhone,
        recipientName: request.recipientName,
        amount: request.amount,
        fees: request.fees,
        totalAmount: request.amount + request.fees,
        currency: request.currency,
        type: request.type,
        provider: request.provider,
        status: TransferStatus.pending,
        createdAt: Timestamp.now(),
        reference: _generateReference(),
        description: request.description,
      );

      // Transaction Firestore pour garantir la cohérence
      await _firestore.runTransaction((transaction) async {
        // Débit du compte expéditeur
        final senderRef = _firestore.collection('users').doc(currentUser.uid);
        transaction.update(senderRef, {
          'balance': FieldValue.increment(-(request.amount + request.fees)),
          'lastTransactionAt': Timestamp.now(),
        });

        // Crédit du compte destinataire (si transfert interne)
        if (request.type == TransferType.internal &&
            request.recipientId != null) {
          final recipientRef = _firestore
              .collection('users')
              .doc(request.recipientId!);
          transaction.update(recipientRef, {
            'balance': FieldValue.increment(request.amount),
            'lastTransactionAt': Timestamp.now(),
          });

          // Créer deux entrées dans transfers : une pour l'envoyeur (négative) et une pour le destinataire (positive)

          // 1. Transaction pour l'envoyeur (montant négatif)
          final senderTransferId = _firestore
              .collection('transactions')
              .doc()
              .id;
          final senderTransfer = TransferModel(
            id: senderTransferId,
            senderId: currentUser.uid,
            recipientId: request.recipientId,
            recipientPhone: request.recipientPhone,
            recipientName: request.recipientName,
            amount: -request.amount, // Montant négatif pour l'envoyeur
            fees: request.fees,
            totalAmount: -(request.amount + request.fees),
            currency: request.currency,
            type: request.type,
            provider: request.provider,
            status: TransferStatus.completed,
            createdAt: Timestamp.now(),
            completedAt: Timestamp.now(),
            reference: _generateReference(),
            description:
                request.description ??
                'Transfert envoyé à ${request.recipientName}',
          );

          // 2. Transaction pour le destinataire (montant positif)
          final recipientTransferId = _firestore
              .collection('transactions')
              .doc()
              .id;
          final recipientTransfer = TransferModel(
            id: recipientTransferId,
            senderId: request
                .recipientId!, // Le destinataire devient l'owner de cette transaction
            recipientId: currentUser
                .uid, // L'expéditeur devient le recipientId pour cette transaction
            recipientPhone: request.recipientPhone,
            recipientName: request.recipientName,
            amount: request.amount, // Montant positif pour le destinataire
            fees: 0.0, // Pas de frais pour le destinataire
            totalAmount: request.amount,
            currency: request.currency,
            type: request.type,
            provider: request.provider,
            status: TransferStatus.completed,
            createdAt: Timestamp.now(),
            completedAt: Timestamp.now(),
            reference: senderTransfer.reference, // Même référence
            description:
                request.description ?? 'Transfert reçu de l\'expéditeur',
          );

          // Enregistrer les deux transactions
          final senderTransferRef = _firestore
              .collection('transactions')
              .doc(senderTransferId);
          transaction.set(senderTransferRef, senderTransfer.toFirestore());

          final recipientTransferRef = _firestore
              .collection('transactions')
              .doc(recipientTransferId);
          transaction.set(
            recipientTransferRef,
            recipientTransfer.toFirestore(),
          );
        } else {
          // Pour les autres types de transferts (non internes), garder l'ancien comportement
          final transferRef = _firestore
              .collection('transactions')
              .doc(transferId);
          transaction.set(transferRef, transfer.toFirestore());
        }

        // Mise à jour des statistiques
        _updateTransferStats(transaction, currentUser.uid, request.amount);
      });

      // Award points for the transfer
      await GamificationService().awardPoints(currentUser.uid, 10, 'Transfer');

      // Handle round-up savings
      await _handleRoundUpSavings(currentUser.uid, request.amount);

      // Update transfer challenge progress
      await GamificationService().updateChallengeProgress(
          currentUser.uid, ChallengeType.transfer, 1);

      // Handle cashback for QR code payments
      if (request.type == TransferType.qrCode) {
        await _handleCashback(currentUser.uid, request.amount);
      }

      // Traitement selon le type de transfert (seulement pour les transferts non internes)
      if (request.type != TransferType.internal) {
        await _processTransferByType(transfer);
      }

      // Créer un message de notification dans la conversation pour les transferts internes
      if (request.type == TransferType.internal &&
          request.recipientId != null) {
        await _createTransferChatMessage(
          currentUser.uid,
          request.recipientId!,
          request.amount,
          request.description ?? 'Transfert d\'argent',
        );
      }

      return TransferResult.success(transfer);
    } catch (e) {
      return TransferResult.error('Erreur lors du transfert: $e');
    }
  }

  /// Traite le transfert selon son type
  Future<void> _processTransferByType(TransferModel transfer) async {
    switch (transfer.type) {
      case TransferType.internal:
        await _processInternalTransfer(transfer);
        break;
      case TransferType.mobileMoney:
        await _processMobileMoneyTransfer(transfer);
        break;
      case TransferType.bankTransfer:
        await _processBankTransfer(transfer);
        break;
      case TransferType.qrCode:
        await _processQRCodeTransfer(transfer);
        break;
    }
  }

  /// Traite un transfert interne
  Future<void> _processInternalTransfer(TransferModel transfer) async {
    try {
      // Marquer comme complété (déjà traité dans la transaction)
      await _updateTransferStatus(transfer.id, TransferStatus.completed);

      // Envoyer notification au destinataire
      await _sendTransferNotification(transfer);
    } catch (e) {
      await _updateTransferStatus(transfer.id, TransferStatus.failed);
      throw e;
    }
  }

  /// Traite un transfert Mobile Money
  Future<void> _processMobileMoneyTransfer(TransferModel transfer) async {
    try {
      // Simuler l'API Mobile Money
      await Future.delayed(const Duration(seconds: 2));

      // Ici on intégrerait avec l'API du provider (Orange Money, MTN, etc.)
      final success = await _callMobileMoneyAPI(transfer);

      if (success) {
        await _updateTransferStatus(transfer.id, TransferStatus.completed);
      } else {
        await _updateTransferStatus(transfer.id, TransferStatus.failed);
        // Remboursement en cas d'échec
        await _refundFailedTransfer(transfer);
      }
    } catch (e) {
      await _updateTransferStatus(transfer.id, TransferStatus.failed);
      await _refundFailedTransfer(transfer);
      throw e;
    }
  }

  /// Traite un virement bancaire
  Future<void> _processBankTransfer(TransferModel transfer) async {
    try {
      // Simuler l'API bancaire
      await Future.delayed(const Duration(seconds: 3));

      // Ici on intégrerait avec l'API bancaire
      final success = await _callBankAPI(transfer);

      if (success) {
        await _updateTransferStatus(transfer.id, TransferStatus.completed);
      } else {
        await _updateTransferStatus(transfer.id, TransferStatus.failed);
        await _refundFailedTransfer(transfer);
      }
    } catch (e) {
      await _updateTransferStatus(transfer.id, TransferStatus.failed);
      await _refundFailedTransfer(transfer);
      throw e;
    }
  }

  /// Traite un transfert par QR Code
  Future<void> _processQRCodeTransfer(TransferModel transfer) async {
    try {
      // Le QR Code transfer est instantané
      await _updateTransferStatus(transfer.id, TransferStatus.completed);
      await _sendTransferNotification(transfer);
    } catch (e) {
      await _updateTransferStatus(transfer.id, TransferStatus.failed);
      await _refundFailedTransfer(transfer);
      throw e;
    }
  }

  /// Simule un appel API Mobile Money
  Future<bool> _callMobileMoneyAPI(TransferModel transfer) async {
    // Simulation d'une API Mobile Money
    // En production, ceci appellerait les vraies APIs
    await Future.delayed(const Duration(milliseconds: 500));

    // 95% de succès en simulation
    return DateTime.now().millisecond % 100 < 95;
  }

  /// Simule un appel API bancaire
  Future<bool> _callBankAPI(TransferModel transfer) async {
    // Simulation d'une API bancaire
    await Future.delayed(const Duration(milliseconds: 800));

    // 90% de succès en simulation
    return DateTime.now().millisecond % 100 < 90;
  }

  /// Met à jour le statut d'un transfert
  Future<void> _updateTransferStatus(
    String transferId,
    TransferStatus status,
  ) async {
    await _firestore.collection('transactions').doc(transferId).update({
      'status': status.name,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Rembourse un transfert échoué
  Future<void> _refundFailedTransfer(TransferModel transfer) async {
    await _firestore.runTransaction((transaction) async {
      final senderRef = _firestore.collection('users').doc(transfer.senderId);
      transaction.update(senderRef, {
        'balance': FieldValue.increment(transfer.amount + transfer.fees),
      });
    });
  }

  /// Envoie une notification de transfert
  Future<void> _sendTransferNotification(TransferModel transfer) async {
    final notificationService = NotificationService();
    // Notification à l'expéditeur
    await notificationService.createNotification(
      userId: transfer.senderId,
      title: 'Transfert effectué',
      message: 'Transfert de ${transfer.amount} FCFA envoyé avec succès',
      type: 'transfer_sent',
      data: {'transferId': transfer.id},
    );

    // Notification au destinataire (si transfert interne)
    if (transfer.recipientId != null) {
      await notificationService.createNotification(
        userId: transfer.recipientId!,
        title: 'Argent reçu',
        message: 'Vous avez reçu ${transfer.amount} FCFA',
        type: 'transfer_received',
        data: {'transferId': transfer.id},
      );
    }
  }

  /// Met à jour les statistiques de transfert
  void _updateTransferStats(
    Transaction transaction,
    String userId,
    double amount,
  ) {
    final statsRef = _firestore.collection('user_stats').doc(userId);
    transaction.set(statsRef, {
      'totalTransfersSent': FieldValue.increment(1),
      'totalAmountSent': FieldValue.increment(amount),
      'lastTransferAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  /// Génère une référence unique pour le transfert
  String _generateReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TRF$random${timestamp.toString().substring(8)}';
  }

  /// Récupère le solde d'un utilisateur
  Future<double> getUserBalance(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    return (userData?['balance'] as num?)?.toDouble() ?? 0.0;
  }

  /// Récupère les transferts reçus par un utilisateur
  Stream<List<TransferModel>> getReceivedTransfers(String userId) {
    return _firestore
        .collection('transactions')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransferModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Recherche des utilisateurs par téléphone ou nom
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final phoneQuery = _firestore
        .collection('users')
        .where('phone', isGreaterThanOrEqualTo: query)
        .where('phone', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10);

    final nameQuery = _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10);

    final phoneResults = await phoneQuery.get();
    final nameResults = await nameQuery.get();

    final allResults = <UserModel>[];

    for (final doc in phoneResults.docs) {
      allResults.add(UserModel.fromFirestore(doc));
    }

    for (final doc in nameResults.docs) {
      final user = UserModel.fromFirestore(doc);
      if (!allResults.any((u) => u.id == user.id)) {
        allResults.add(user);
      }
    }

    return allResults;
  }

  /// Calcule les frais de transfert
  double calculateTransferFees({
    required double amount,
    required TransferType type,
    String? provider,
  }) {
    switch (type) {
      case TransferType.internal:
        return 0.0; // Gratuit entre utilisateurs de l'app

      case TransferType.mobileMoney:
        switch (provider?.toLowerCase()) {
          case 'orange':
            return amount * 0.01; // 1%
          case 'mtn':
            return amount * 0.012; // 1.2%
          case 'moov':
            return amount * 0.008; // 0.8%
          case 'wave':
            return 0.0; // Gratuit
          default:
            return amount * 0.01;
        }

      case TransferType.bankTransfer:
        if (amount <= 50000) return 500;
        if (amount <= 100000) return 750;
        if (amount <= 500000) return 1000;
        return 1500;

      case TransferType.qrCode:
        return 0.0; // Gratuit
    }
  }

  /// Valide une demande de transfert
  TransferValidationResult validateTransferRequest(TransferRequest request) {
    final errors = <String>[];

    // Validation du montant
    if (request.amount <= 0) {
      errors.add('Le montant doit être supérieur à 0');
    }

    if (request.amount > 2000000) {
      errors.add('Le montant ne peut pas dépasser 2 000 000 FCFA');
    }

    // Validation du destinataire
    if (request.type == TransferType.internal && request.recipientId == null) {
      errors.add('Destinataire requis pour un transfert interne');
    }

    if (request.type == TransferType.mobileMoney &&
        request.recipientPhone == null) {
      errors.add('Numéro de téléphone requis pour Mobile Money');
    }

    // Validation du provider
    if (request.type == TransferType.mobileMoney && request.provider == null) {
      errors.add('Provider Mobile Money requis');
    }

    return TransferValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Transfert direct vers un utilisateur FinIMoi
  static Future<void> transferMoney({
    required String senderId,
    required String recipientPhone,
    required double amount,
    required String description,
  }) async {
    try {
      // Rechercher le destinataire par téléphone
      final recipientQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: recipientPhone)
          .limit(1)
          .get();

      if (recipientQuery.docs.isEmpty) {
        throw Exception('Utilisateur destinataire non trouvé');
      }

      final recipientId = recipientQuery.docs.first.id;

      // Effectuer le transfert
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Vérifier et débiter l'expéditeur
        final senderDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(senderId);
        final senderSnapshot = await transaction.get(senderDoc);
        if (!senderSnapshot.exists) throw Exception('Expéditeur non trouvé');

        final senderBalance = (senderSnapshot.data()?['balance'] ?? 0.0)
            .toDouble();
        if (senderBalance < amount) throw Exception('Solde insuffisant');

        // Créditer le destinataire
        final recipientDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(recipientId);
        final recipientSnapshot = await transaction.get(recipientDoc);
        if (!recipientSnapshot.exists)
          throw Exception('Destinataire non trouvé');

        final recipientBalance = (recipientSnapshot.data()?['balance'] ?? 0.0)
            .toDouble();

        // Mettre à jour les soldes
        transaction.update(senderDoc, {'balance': senderBalance - amount});
        transaction.update(recipientDoc, {
          'balance': recipientBalance + amount,
        });

        // Créer l'historique de transfert
        transaction.set(
          FirebaseFirestore.instance.collection('transactions').doc(),
          {
            'senderId': senderId,
            'recipientId': recipientId,
            'recipientPhone': recipientPhone,
            'amount': amount,
            'fees': 0.0,
            'totalAmount': amount,
            'type': 'internal',
            'status': 'completed',
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
            'metadata': {'transfer_type': 'user_to_user'},
          },
        );
      });
    } catch (e) {
      throw Exception('Erreur lors du transfert: $e');
    }
  }

  /// Transfert vers Mobile Money
  static Future<void> transferToMobileMoney({
    required String senderId,
    required String recipientPhone,
    required double amount,
    required String provider,
    required String description,
  }) async {
    try {
      // Calculer les frais
      final fees = _calculateMobileMoneyFees(amount);
      final totalAmount = amount + fees;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Vérifier et débiter l'expéditeur
        final senderDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(senderId);
        final senderSnapshot = await transaction.get(senderDoc);
        if (!senderSnapshot.exists) throw Exception('Expéditeur non trouvé');

        final senderBalance = (senderSnapshot.data()?['balance'] ?? 0.0)
            .toDouble();
        if (senderBalance < totalAmount)
          throw Exception(
            'Solde insuffisant (frais inclus: ${fees.toStringAsFixed(0)} XOF)',
          );

        // Débiter l'expéditeur
        transaction.update(senderDoc, {'balance': senderBalance - totalAmount});

        // Créer l'historique de transfert
        transaction.set(
          FirebaseFirestore.instance.collection('transactions').doc(),
          {
            'senderId': senderId,
            'recipientPhone': recipientPhone,
            'amount': amount,
            'fees': fees,
            'totalAmount': totalAmount,
            'type': 'mobile_money',
            'provider': provider,
            'status': 'processing',
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
            'metadata': {'transfer_type': 'mobile_money', 'provider': provider},
          },
        );
      });
    } catch (e) {
      throw Exception('Erreur lors du transfert Mobile Money: $e');
    }
  }

  /// Transfert vers banque
  static Future<void> transferToBank({
    required String senderId,
    required String bankCode,
    required String accountNumber,
    required String accountName,
    required double amount,
    required String description,
  }) async {
    try {
      // Calculer les frais bancaires
      final fees = _calculateBankTransferFees(amount);
      final totalAmount = amount + fees;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Vérifier et débiter l'expéditeur
        final senderDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(senderId);
        final senderSnapshot = await transaction.get(senderDoc);
        if (!senderSnapshot.exists) throw Exception('Expéditeur non trouvé');

        final senderBalance = (senderSnapshot.data()?['balance'] ?? 0.0)
            .toDouble();
        if (senderBalance < totalAmount)
          throw Exception(
            'Solde insuffisant (frais inclus: ${fees.toStringAsFixed(0)} XOF)',
          );

        // Débiter l'expéditeur
        transaction.update(senderDoc, {'balance': senderBalance - totalAmount});

        // Créer l'historique de transfert
        transaction.set(
          FirebaseFirestore.instance.collection('transactions').doc(),
          {
            'senderId': senderId,
            'bankCode': bankCode,
            'accountNumber': accountNumber,
            'accountName': accountName,
            'amount': amount,
            'fees': fees,
            'totalAmount': totalAmount,
            'type': 'bank_transfer',
            'status': 'processing',
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
            'metadata': {
              'transfer_type': 'bank_transfer',
              'bank_code': bankCode,
            },
          },
        );
      });
    } catch (e) {
      throw Exception('Erreur lors du virement bancaire: $e');
    }
  }

  /// Créer un message de notification de transfert dans la conversation
  Future<void> _createTransferChatMessage(
    String senderId,
    String recipientId,
    double amount,
    String description,
  ) async {
    try {
      // Utiliser un délai pour éviter les conflits de transaction
      await Future.delayed(const Duration(milliseconds: 100));

      final chatService = ChatService();

      // Récupérer les informations de l'utilisateur envoyeur
      final senderDoc = await _firestore
          .collection('users')
          .doc(senderId)
          .get();
      final senderData = senderDoc.data();
      final senderName = senderData?['firstName'] ?? 'Utilisateur';
      final senderAvatar = senderData?['profileImageUrl'] ?? '';

      // Créer ou récupérer le chat entre les deux utilisateurs
      final chatId = await chatService.getOrCreateDirectChat(
        senderId,
        recipientId,
      );

      // Créer un message de notification de transfert réussi
      await chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content:
            '💰 Transfert de ${amount.toStringAsFixed(0)} FCFA effectué avec succès',
        type: MessageType.system,
        metadata: {
          'transferAmount': amount,
          'transferDescription': description,
          'transferType': 'completed',
          'timestamp': Timestamp.now().toDate().toIso8601String(),
        },
      );
    } catch (e) {
      print('❌ Erreur lors de la création du message de chat: $e');
      // Ne pas faire échouer le transfert si la création du message échoue
    }
  }

  /// Calculer les frais Mobile Money
  static double _calculateMobileMoneyFees(double amount) {
    if (amount <= 1000) return 50;
    if (amount <= 5000) return 100;
    if (amount <= 10000) return 150;
    if (amount <= 25000) return 200;
    if (amount <= 50000) return 300;
    return 500; // Montants supérieurs
  }

  /// Calculer les frais de virement bancaire
  static double _calculateBankTransferFees(double amount) {
    if (amount <= 10000) return 500;
    if (amount <= 50000) return 1000;
    if (amount <= 100000) return 1500;
    return 2000; // Montants supérieurs
  }

  Future<void> _handleRoundUpSavings(String userId, double amount) async {
    try {
      final user = await UserService.getUserProfile(userId);
      if (user != null && user.roundUpSavingsEnabled && user.roundUpSavingsGoalId != null) {
        final roundUpAmount = amount.ceil() - amount;
        if (roundUpAmount > 0) {
          await RealSavingsService().addToSavings(user.roundUpSavingsGoalId!, userId, roundUpAmount);
        }
      }
    } catch (e) {
      // Log error, but don't fail the whole transfer
      print('Error processing round-up savings: $e');
    }
  }

  Future<void> _handleCashback(String userId, double amount) async {
    try {
      final cashbackAmount = amount * 0.01; // 1% cashback
      if (cashbackAmount > 0) {
        final userRef = _firestore.collection('users').doc(userId);
        await userRef.update({
          'cashbackBalance': FieldValue.increment(cashbackAmount),
        });
      }
    } catch (e) {
      // Log error, but don't fail the whole transfer
      print('Error processing cashback: $e');
    }
  }
}
