import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/credit_model.dart';
import '../../domain/entities/user_model.dart';
import 'transfer_service.dart';
import 'user_service.dart';
import 'notification_service.dart';
import 'real_tontine_service.dart';
import 'real_savings_service.dart';

final realCreditServiceProvider = Provider<RealCreditService>((ref) {
  return RealCreditService();
});

class RealCreditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _creditsRef => _firestore.collection('credits');

  // Obtenir les crédits de l'utilisateur
  Stream<List<CreditModel>> getUserCredits(String userId) {
    return _creditsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return CreditModel.fromFirestore(doc);
                } catch (e) {
                  print('Erreur lors du parsing du crédit ${doc.id}: $e');
                  return null;
                }
              })
              .where((credit) => credit != null)
              .cast<CreditModel>()
              .toList();
        });
  }

  // Obtenir un crédit par ID
  Stream<CreditModel?> getCreditById(String creditId) {
    return _creditsRef.doc(creditId).snapshots().map((doc) {
      if (!doc.exists) return null;
      try {
        return CreditModel.fromFirestore(doc);
      } catch (e) {
        print('Erreur lors du parsing du crédit $creditId: $e');
        return null;
      }
    });
  }

  // Calculer le score de crédit
  Future<int> calculateCreditScore(String userId) async {
    int score = 0;

    // Account age
    final user = await UserService.getUserProfile(userId);
    if (user != null) {
      final accountAgeInMonths = DateTime.now().difference(user.createdAt).inDays ~/ 30;
      score += accountAgeInMonths * 10;
    }

    // Transaction volume
    final transactions = await TransferService().getUserTransfers(userId).first;
    score += transactions.length;

    // Tontine activity
    final tontines = await RealTontineService().getUserTontines(userId).first;
    score += tontines.where((t) => t.status == TontineStatus.active).length * 20;
    score += tontines.where((t) => t.status == TontineStatus.completed).length * 50;

    // Savings history
    final savingsStats = await RealSavingsService().getSavingsStats(userId);
    score += (savingsStats['totalSaved'] ?? 0) ~/ 1000; // 1 point per 1000 saved

    // Credit history
    final credits = await getUserCredits(userId).first;
    score += credits.where((c) => c.status == 'completed').length * 100; // Bonus for completed credits

    return score;
  }

  // Demander un crédit
  Future<String> requestCredit({
    required String userId,
    required double amount,
    required String purpose,
    required int duration,
    double interestRate = 0.15, // 15% par défaut
  }) async {
    final creditScore = await calculateCreditScore(userId);

    // Auto-approve small loans for users with good score
    if (creditScore > 50 && amount <= 50000) {
      // Create and approve the credit in one go
      final creditId = await _createAndApproveCredit(
        userId: userId,
        amount: amount,
        purpose: purpose,
        duration: duration,
        interestRate: interestRate,
      );
      return creditId;
    }

    if (amount <= 0) {
      throw Exception('Le montant doit être positif');
    }

    if (duration <= 0) {
      throw Exception('La durée doit être positive');
    }

    try {
      // Calculer le paiement mensuel
      final totalAmount = amount + (amount * interestRate);
      final monthlyPayment = totalAmount / duration;

      final credit = CreditModel(
        id: '', // Sera mis à jour avec l'ID du document
        userId: userId,
        amount: amount,
        purpose: purpose,
        duration: duration,
        interestRate: interestRate,
        status: 'pending',
        monthlyPayment: monthlyPayment,
        remainingAmount: totalAmount,
        applicationDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _creditsRef.add(credit.toFirestore());

      // Mettre à jour l'ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la demande de crédit: $e');
    }
  }

  // Approuver un crédit
  Future<void> approveCredit(String creditId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final creditRef = _creditsRef.doc(creditId);
        final creditDoc = await transaction.get(creditRef);

        if (!creditDoc.exists) {
          throw Exception('Crédit introuvable');
        }

        final creditData = creditDoc.data() as Map<String, dynamic>;
        if (creditData['status'] != 'pending') {
          throw Exception('Ce crédit ne peut pas être approuvé');
        }

        final userId = creditData['userId'];
        final amount = (creditData['amount'] ?? 0.0).toDouble();

        // Approuver le crédit
        transaction.update(creditRef, {
          'status': 'approved',
          'approvalDate': Timestamp.now(),
          'nextPaymentDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 30)),
          ),
          'updatedAt': Timestamp.now(),
        });

        // Ajouter le montant au solde de l'utilisateur
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final currentBalance = (userData['balance'] ?? 0.0).toDouble();

          transaction.update(userRef, {'balance': currentBalance + amount});
        }
      });

      // Send notification to user
      await NotificationService().createNotification(
        userId: userId,
        title: 'Crédit Approuvé',
        message: 'Votre demande de crédit de $amount FCFA a été approuvée!',
        type: 'credit_approved',
        data: {'creditId': creditId},
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'approbation du crédit: $e');
    }
  }

  // Rejeter un crédit
  Future<void> rejectCredit(String creditId, String reason) async {
    try {
      await _creditsRef.doc(creditId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors du rejet du crédit: $e');
    }
  }

  // Effectuer un paiement
  Future<void> makePayment(
    String creditId,
    String userId,
    double amount,
  ) async {
    if (amount <= 0) {
      throw Exception('Le montant doit être positif');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final creditRef = _creditsRef.doc(creditId);
        final userRef = _firestore.collection('users').doc(userId);

        // Vérifier le crédit
        final creditDoc = await transaction.get(creditRef);
        if (!creditDoc.exists) {
          throw Exception('Crédit introuvable');
        }

        final creditData = creditDoc.data() as Map<String, dynamic>;
        if (creditData['status'] != 'approved') {
          throw Exception('Ce crédit n\'est pas actif');
        }

        final remainingAmount = (creditData['remainingAmount'] ?? 0.0)
            .toDouble();
        if (amount > remainingAmount) {
          throw Exception('Le montant dépasse le solde restant');
        }

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

        final newRemainingAmount = remainingAmount - amount;
        final isCompleted = newRemainingAmount <= 0;

        // Mettre à jour le solde de l'utilisateur
        transaction.update(userRef, {'balance': userBalance - amount});

        // Mettre à jour le crédit
        final nextPaymentDate = isCompleted
            ? null
            : DateTime.now().add(const Duration(days: 30));

        transaction.update(creditRef, {
          'remainingAmount': newRemainingAmount,
          'status': isCompleted ? 'completed' : 'approved',
          'nextPaymentDate': nextPaymentDate != null
              ? Timestamp.fromDate(nextPaymentDate)
              : null,
          'updatedAt': Timestamp.now(),
        });

        // Ajouter l'historique du paiement
        final paymentRef = creditRef.collection('payments').doc();
        transaction.set(paymentRef, {
          'amount': amount,
          'createdAt': Timestamp.now(),
          'userId': userId,
        });
      });
    } catch (e) {
      throw Exception('Erreur lors du paiement: $e');
    }
  }

  // Obtenir les statistiques de crédit
  Future<Map<String, dynamic>> getCreditStats(String userId) async {
    try {
      final snapshot = await _creditsRef
          .where('userId', isEqualTo: userId)
          .get();

      double totalBorrowed = 0;
      double totalRemaining = 0;
      int activeCredits = 0;
      int completedCredits = 0;
      int pendingCredits = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] ?? 0.0).toDouble();
        final remainingAmount = (data['remainingAmount'] ?? 0.0).toDouble();
        final status = data['status'] ?? '';

        totalBorrowed += amount;

        switch (status) {
          case 'approved':
            activeCredits++;
            totalRemaining += remainingAmount;
            break;
          case 'completed':
            completedCredits++;
            break;
          case 'pending':
            pendingCredits++;
            break;
        }
      }

      return {
        'totalBorrowed': totalBorrowed,
        'totalRemaining': totalRemaining,
        'totalPaid': totalBorrowed - totalRemaining,
        'activeCredits': activeCredits,
        'completedCredits': completedCredits,
        'pendingCredits': pendingCredits,
        'totalCredits': snapshot.docs.length,
      };
    } catch (e) {
      return {
        'totalBorrowed': 0.0,
        'totalRemaining': 0.0,
        'totalPaid': 0.0,
        'activeCredits': 0,
        'completedCredits': 0,
        'pendingCredits': 0,
        'totalCredits': 0,
      };
    }
  }

  // Obtenir l'historique des paiements
  Stream<List<Map<String, dynamic>>> getPaymentHistory(String creditId) {
    return _creditsRef
        .doc(creditId)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
  }

  Future<String> _createAndApproveCredit({
    required String userId,
    required double amount,
    required String purpose,
    required int duration,
    double interestRate = 0.15,
  }) async {
    try {
      final totalAmount = amount + (amount * interestRate);
      final monthlyPayment = totalAmount / duration;
      final creditId = _creditsRef.doc().id;

      await _firestore.runTransaction((transaction) async {
        final creditRef = _creditsRef.doc(creditId);
        final userRef = _firestore.collection('users').doc(userId);

        final credit = CreditModel(
          id: creditId,
          userId: userId,
          amount: amount,
          purpose: purpose,
          duration: duration,
          interestRate: interestRate,
          status: 'approved',
          monthlyPayment: monthlyPayment,
          remainingAmount: totalAmount,
          applicationDate: DateTime.now(),
          approvalDate: DateTime.now(),
          nextPaymentDate: DateTime.now().add(const Duration(days: 30)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        transaction.set(creditRef, credit.toFirestore());

        transaction.update(userRef, {'balance': FieldValue.increment(amount)});
      });

      return creditId;
    } catch (e) {
      throw Exception('Erreur lors de la création et approbation du crédit: $e');
    }
  }

  // Simulated scheduled function to send credit reminders
  Future<void> sendCreditReminders() async {
    final notificationService = NotificationService();
    final now = DateTime.now();

    final snapshot = await _creditsRef
        .where('status', isEqualTo: 'approved')
        .get();

    for (final doc in snapshot.docs) {
      final credit = CreditModel.fromFirestore(doc);
      if (credit.nextPaymentDate != null) {
        final dueDate = credit.nextPaymentDate!;
        if (dueDate.isAfter(now) && dueDate.difference(now).inDays <= 3) {
          await notificationService.createNotification(
            userId: credit.userId,
            title: 'Rappel de Paiement de Crédit',
            message:
                'Votre paiement de ${credit.monthlyPayment.toInt()} FCFA pour votre crédit "${credit.purpose}" est bientôt dû!',
            type: 'credit_reminder',
            data: {'creditId': credit.id},
          );
        }
      }
    }
  }

  // Générer le calendrier de remboursement
  List<RepaymentSchedule> generateRepaymentSchedule(CreditModel credit) {
    final schedule = <RepaymentSchedule>[];
    double remainingBalance = credit.totalAmount;
    final monthlyInterestRate = credit.interestRate / 12;

    for (int i = 1; i <= credit.duration; i++) {
      final interest = remainingBalance * monthlyInterestRate;
      final principal = credit.monthlyPayment - interest;
      remainingBalance -= principal;

      schedule.add(RepaymentSchedule(
        month: i,
        dueDate: DateTime(credit.applicationDate.year, credit.applicationDate.month + i, credit.applicationDate.day),
        principal: principal,
        interest: interest,
        totalPayment: credit.monthlyPayment,
        remainingBalance: remainingBalance > 0 ? remainingBalance : 0,
      ));
    }
    return schedule;
  }
}
