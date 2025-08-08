import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/credit_request.dart';

class CreditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _creditRequestsCollection =>
      _firestore.collection('credit_requests');

  // Get user's credit requests
  Stream<List<CreditRequest>> getUserCreditRequests(String userId) {
    return _creditRequestsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CreditRequest.fromFirestore(doc))
              .toList(),
        );
  }

  // Get all credit requests (for admin)
  Stream<List<CreditRequest>> getAllCreditRequests() {
    return _creditRequestsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CreditRequest.fromFirestore(doc))
              .toList(),
        );
  }

  // Get credit requests by status
  Stream<List<CreditRequest>> getCreditRequestsByStatus(CreditStatus status) {
    return _creditRequestsCollection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CreditRequest.fromFirestore(doc))
              .toList(),
        );
  }

  // Create new credit request
  Future<String> createCreditRequest({
    required String userId,
    required double amount,
    required int durationMonths,
    required String purpose,
    required List<File> documents,
  }) async {
    try {
      // Calculate terms
      const double interestRate = 12.0; // 12% par an
      final monthlyPayment = _calculateMonthlyPayment(
        amount,
        interestRate,
        durationMonths,
      );
      final totalAmount = monthlyPayment * durationMonths;
      final totalInterest = totalAmount - amount;

      final firstPaymentDate = DateTime.now().add(const Duration(days: 30));
      final lastPaymentDate = DateTime(
        firstPaymentDate.year,
        firstPaymentDate.month + durationMonths - 1,
        firstPaymentDate.day,
      );

      // Upload documents
      final uploadedDocuments = await _uploadDocuments(documents, userId);

      // Create payment schedule
      final payments = _generatePaymentSchedule(
        monthlyPayment,
        firstPaymentDate,
        durationMonths,
      );

      final creditRequest = CreditRequest(
        id: '',
        userId: userId,
        amount: amount,
        durationMonths: durationMonths,
        purpose: purpose,
        interestRate: interestRate,
        status: CreditStatus.pending,
        createdAt: DateTime.now(),
        documents: uploadedDocuments,
        terms: CreditTerms(
          monthlyPayment: monthlyPayment,
          firstPaymentDate: firstPaymentDate,
          lastPaymentDate: lastPaymentDate,
          totalAmount: totalAmount,
          totalInterest: totalInterest,
          penaltyRate: 2.0, // 2% de pénalité
          gracePeriodDays: 7,
        ),
        payments: payments,
      );

      final docRef = await _creditRequestsCollection.add(
        creditRequest.toFirestore(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la demande de crédit: $e');
    }
  }

  // Upload documents to Firebase Storage
  Future<List<CreditDocument>> _uploadDocuments(
    List<File> files,
    String userId,
  ) async {
    final List<CreditDocument> documents = [];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName =
          'credit_documents/$userId/${DateTime.now().millisecondsSinceEpoch}_$i.pdf';

      final ref = _storage.ref().child(fileName);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      documents.add(
        CreditDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: file.path.split('/').last,
          url: url,
          type: 'pdf',
          uploadedAt: DateTime.now(),
          isVerified: false,
        ),
      );
    }

    return documents;
  }

  // Calculate monthly payment
  double _calculateMonthlyPayment(
    double amount,
    double annualRate,
    int months,
  ) {
    if (months == 0) return 0;
    final monthlyRate = annualRate / 100 / 12;
    if (monthlyRate == 0) return amount / months;

    return amount *
        monthlyRate *
        (1 + monthlyRate).pow(months) /
        ((1 + monthlyRate).pow(months) - 1);
  }

  // Generate payment schedule
  List<CreditPayment> _generatePaymentSchedule(
    double monthlyPayment,
    DateTime firstPaymentDate,
    int durationMonths,
  ) {
    final List<CreditPayment> payments = [];

    for (int i = 0; i < durationMonths; i++) {
      final dueDate = DateTime(
        firstPaymentDate.year,
        firstPaymentDate.month + i,
        firstPaymentDate.day,
      );

      payments.add(
        CreditPayment(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          paymentNumber: i + 1,
          amount: monthlyPayment,
          dueDate: dueDate,
          status: PaymentStatus.pending,
        ),
      );
    }

    return payments;
  }

  // Approve credit request
  Future<void> approveCreditRequest(String creditId, String adminId) async {
    await _firestore.runTransaction((transaction) async {
      final creditDoc = await transaction.get(
        _creditRequestsCollection.doc(creditId),
      );
      if (!creditDoc.exists) {
        throw Exception('Demande de crédit introuvable');
      }

      transaction.update(_creditRequestsCollection.doc(creditId), {
        'status': CreditStatus.approved.name,
        'approvedAt': Timestamp.fromDate(DateTime.now()),
        'adminId': adminId,
      });
    });

    // TODO: Send notification to user
    // TODO: Initiate fund transfer
  }

  // Reject credit request
  Future<void> rejectCreditRequest(
    String creditId,
    String adminId,
    String reason,
  ) async {
    await _creditRequestsCollection.doc(creditId).update({
      'status': CreditStatus.rejected.name,
      'rejectedAt': Timestamp.fromDate(DateTime.now()),
      'adminId': adminId,
      'rejectionReason': reason,
    });

    // TODO: Send notification to user
  }

  // Activate credit (disburse funds)
  Future<void> activateCredit(String creditId) async {
    await _firestore.runTransaction((transaction) async {
      final creditDoc = await transaction.get(
        _creditRequestsCollection.doc(creditId),
      );
      if (!creditDoc.exists) {
        throw Exception('Demande de crédit introuvable');
      }

      final creditData = creditDoc.data() as Map<String, dynamic>;
      if (creditData['status'] != CreditStatus.approved.name) {
        throw Exception('Le crédit doit être approuvé avant activation');
      }

      transaction.update(_creditRequestsCollection.doc(creditId), {
        'status': CreditStatus.active.name,
      });

      // TODO: Create transaction for fund disbursement
      // TODO: Update user balance
    });
  }

  // Process payment
  Future<void> processPayment(
    String creditId,
    int paymentNumber,
    double amount,
    String transactionId,
  ) async {
    await _firestore.runTransaction((transaction) async {
      final creditDoc = await transaction.get(
        _creditRequestsCollection.doc(creditId),
      );
      if (!creditDoc.exists) {
        throw Exception('Crédit introuvable');
      }

      final credit = CreditRequest.fromFirestore(creditDoc);
      final updatedPayments = credit.payments.map((payment) {
        if (payment.paymentNumber == paymentNumber) {
          return CreditPayment(
            id: payment.id,
            paymentNumber: payment.paymentNumber,
            amount: payment.amount,
            dueDate: payment.dueDate,
            paidDate: DateTime.now(),
            status: PaymentStatus.paid,
            transactionId: transactionId,
          );
        }
        return payment;
      }).toList();

      // Check if all payments are completed
      final allPaid = updatedPayments.every(
        (p) => p.status == PaymentStatus.paid,
      );
      final newStatus = allPaid ? CreditStatus.completed : CreditStatus.active;

      transaction.update(_creditRequestsCollection.doc(creditId), {
        'payments': updatedPayments.map((p) => p.toMap()).toList(),
        'status': newStatus.name,
      });
    });
  }

  // Get overdue payments
  Future<List<CreditPayment>> getOverduePayments(String userId) async {
    final credits = await _creditRequestsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: CreditStatus.active.name)
        .get();

    final List<CreditPayment> overduePayments = [];
    final now = DateTime.now();

    for (final doc in credits.docs) {
      final credit = CreditRequest.fromFirestore(doc);
      final overdue = credit.payments.where(
        (payment) =>
            payment.status != PaymentStatus.paid &&
            payment.dueDate.isBefore(now),
      );
      overduePayments.addAll(overdue);
    }

    return overduePayments;
  }

  // Get next payment due
  Future<CreditPayment?> getNextPaymentDue(String creditId) async {
    final doc = await _creditRequestsCollection.doc(creditId).get();
    if (!doc.exists) return null;

    final credit = CreditRequest.fromFirestore(doc);
    final pendingPayments = credit.payments
        .where((p) => p.status == PaymentStatus.pending)
        .toList();

    if (pendingPayments.isEmpty) return null;

    pendingPayments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pendingPayments.first;
  }

  // Get credit by id
  Future<CreditRequest?> getCreditById(String creditId) async {
    final doc = await _creditRequestsCollection.doc(creditId).get();
    if (doc.exists) {
      return CreditRequest.fromFirestore(doc);
    }
    return null;
  }

  // Calculate user's credit score (simplified)
  Future<double> calculateCreditScore(String userId) async {
    final credits = await _creditRequestsCollection
        .where('userId', isEqualTo: userId)
        .get();

    if (credits.docs.isEmpty) return 500.0; // Default score

    double score = 500.0;
    int totalCredits = 0;
    int completedCredits = 0;
    int overduePayments = 0;
    int totalPayments = 0;

    for (final doc in credits.docs) {
      final credit = CreditRequest.fromFirestore(doc);
      totalCredits++;

      if (credit.status == CreditStatus.completed) {
        completedCredits++;
        score += 50; // Bonus for completed credits
      }

      for (final payment in credit.payments) {
        totalPayments++;
        if (payment.status == PaymentStatus.paid) {
          score += 5; // Bonus for on-time payments
        } else if (payment.isOverdue) {
          overduePayments++;
          score -= 20; // Penalty for overdue payments
        }
      }
    }

    // Apply ratios
    if (totalCredits > 0) {
      final completionRate = completedCredits / totalCredits;
      score += completionRate * 100;
    }

    if (totalPayments > 0) {
      final overdueRate = overduePayments / totalPayments;
      score -= overdueRate * 200;
    }

    return score.clamp(300.0, 850.0); // Standard credit score range
  }
}

// Providers
final creditServiceProvider = Provider<CreditService>((ref) {
  return CreditService();
});

final userCreditRequestsProvider =
    StreamProvider.family<List<CreditRequest>, String>((ref, userId) {
      final creditService = ref.watch(creditServiceProvider);
      return creditService.getUserCreditRequests(userId);
    });

final allCreditRequestsProvider = StreamProvider<List<CreditRequest>>((ref) {
  final creditService = ref.watch(creditServiceProvider);
  return creditService.getAllCreditRequests();
});

final creditRequestsByStatusProvider =
    StreamProvider.family<List<CreditRequest>, CreditStatus>((ref, status) {
      final creditService = ref.watch(creditServiceProvider);
      return creditService.getCreditRequestsByStatus(status);
    });

final overduePaymentsProvider =
    FutureProvider.family<List<CreditPayment>, String>((ref, userId) {
      final creditService = ref.watch(creditServiceProvider);
      return creditService.getOverduePayments(userId);
    });

final creditScoreProvider = FutureProvider.family<double, String>((
  ref,
  userId,
) {
  final creditService = ref.watch(creditServiceProvider);
  return creditService.calculateCreditScore(userId);
});
