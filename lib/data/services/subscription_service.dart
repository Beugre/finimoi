import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finimoi/data/services/notification_service.dart';
import 'package:finimoi/domain/entities/subscription_model.dart';
import 'package:finimoi/domain/entities/subscription_plan_model.dart';
import 'package:finimoi/core/utils/auth_utils.dart';
import 'package:intl/intl.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createSubscriptionPlan({
    required String planName,
    required double amount,
    required String frequency,
  }) async {
    final merchantId = AuthUtils.getCurrentUser()?.uid;
    if (merchantId == null) {
      throw Exception('Aucun marchand connecté.');
    }

    final plan = SubscriptionPlanModel(
      id: '', // Firestore will generate it
      merchantId: merchantId,
      planName: planName,
      amount: amount,
      frequency: frequency,
    );

    final docRef = await _firestore.collection('subscription_plans').add(plan.toMap());
    return docRef.id;
  }

  Stream<List<SubscriptionPlanModel>> getSubscriptionPlansForMerchant() {
    final merchantId = AuthUtils.getCurrentUser()?.uid;
    if (merchantId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('subscription_plans')
        .where('merchantId', isEqualTo: merchantId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscriptionPlanModel.fromFirestore(doc))
            .toList());
  }

  Future<SubscriptionPlanModel?> getSubscriptionPlan(String planId) async {
    final doc = await _firestore.collection('subscription_plans').doc(planId).get();
    if (doc.exists) {
      return SubscriptionPlanModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> createSubscription(String planId) async {
    final customerId = AuthUtils.getCurrentUser()?.uid;
    if (customerId == null) {
      throw Exception('Aucun utilisateur connecté.');
    }

    final plan = await getSubscriptionPlan(planId);
    if (plan == null) {
      throw Exception('Plan d\'abonnement non trouvé.');
    }

    final now = DateTime.now();
    DateTime nextPaymentDate;
    if (plan.frequency == 'weekly') {
      nextPaymentDate = now.add(const Duration(days: 7));
    } else if (plan.frequency == 'yearly') {
      nextPaymentDate = DateTime(now.year + 1, now.month, now.day);
    } else { // monthly
      nextPaymentDate = DateTime(now.year, now.month + 1, now.day);
    }

    final subscription = SubscriptionModel(
      id: '', // Firestore will generate
      merchantId: plan.merchantId,
      customerId: customerId,
      amount: plan.amount,
      frequency: SubscriptionFrequency.values.firstWhere((e) => e.name == plan.frequency),
      startDate: now,
      nextPaymentDate: nextPaymentDate,
      status: SubscriptionStatus.active,
    );

    await _firestore.collection('subscriptions').add(subscription.toMap());

    // TODO: Process the first payment immediately
  }

  Stream<List<SubscriptionModel>> getSubscriptionsForCurrentUser() {
    final customerId = AuthUtils.getCurrentUser()?.uid;
    if (customerId == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('subscriptions')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscriptionModel.fromFirestore(doc))
            .toList());
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': SubscriptionStatus.cancelled.name,
    });
  }

  // --- SIMULATED CRON JOB ---
  Future<int> processRecurringPayments() async {
    print("Starting recurring payment processing...");
    final now = DateTime.now();

    // --- Process Due Payments ---
    final duePaymentsSnapshot = await _firestore
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .where('nextPaymentDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    if (duePaymentsSnapshot.docs.isEmpty) {
      print("No due payments found.");
    }

    // --- Send Reminders for Upcoming Payments ---
    final reminderEndDate = now.add(const Duration(days: 3));
    final upcomingPaymentsSnapshot = await _firestore
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .where('nextPaymentDate', isGreaterThan: Timestamp.fromDate(now))
        .where('nextPaymentDate', isLessThanOrEqualTo: Timestamp.fromDate(reminderEndDate))
        .get();

    for (final doc in upcomingPaymentsSnapshot.docs) {
      final subscription = SubscriptionModel.fromFirestore(doc);
      // Simple check to avoid sending multiple reminders. In a real app,
      // you'd store a `reminderSentAt` timestamp.
      final isDueSoon = subscription.nextPaymentDate.difference(now).inDays < 3;
      if (isDueSoon) {
         await NotificationService().createNotification(
          userId: subscription.customerId,
          title: 'Rappel de Paiement d\'Abonnement',
          message: 'Votre paiement de ${subscription.amount} FCFA est prévu pour le ${DateFormat('dd/MM/yyyy').format(subscription.nextPaymentDate)}.',
          type: 'subscription_reminder',
          data: {'subscriptionId': doc.id},
        );
      }
    }

    int successCount = 0;
    for (final doc in duePaymentsSnapshot.docs) {
      final subscription = SubscriptionModel.fromFirestore(doc);

      try {
        await _firestore.runTransaction((transaction) async {
          final customerRef = _firestore.collection('users').doc(subscription.customerId);
          final merchantRef = _firestore.collection('users').doc(subscription.merchantId);

          final customerDoc = await transaction.get(customerRef);
          final merchantDoc = await transaction.get(merchantRef);

          if (!customerDoc.exists || !merchantDoc.exists) {
            throw Exception('Customer or merchant not found.');
          }

          final customerBalance = (customerDoc.data()!['balance'] ?? 0.0).toDouble();
          if (customerBalance < subscription.amount) {
            // Not enough balance, skip for now. Could implement notifications here.
            print('Insufficient balance for user ${subscription.customerId}');
            return;
          }

          // 1. Decrement customer balance
          transaction.update(customerRef, {'balance': FieldValue.increment(-subscription.amount)});
          // 2. Increment merchant balance
          transaction.update(merchantRef, {'balance': FieldValue.increment(subscription.amount)});

          // 3. Create transaction record
          final transactionRef = _firestore.collection('transactions').doc();
          transaction.set(transactionRef, {
            'amount': subscription.amount,
            'senderId': subscription.customerId,
            'receiverId': subscription.merchantId,
            'type': 'subscription_payment',
            'description': 'Paiement abonnement',
            'status': 'completed',
            'createdAt': Timestamp.now(),
          });

          // 4. Update next payment date
          DateTime nextPaymentDate;
          final currentNextDate = subscription.nextPaymentDate;
          if (subscription.frequency == SubscriptionFrequency.weekly) {
            nextPaymentDate = currentNextDate.add(const Duration(days: 7));
          } else if (subscription.frequency == SubscriptionFrequency.yearly) {
            nextPaymentDate = DateTime(currentNextDate.year + 1, currentNextDate.month, currentNextDate.day);
          } else { // monthly
            nextPaymentDate = DateTime(currentNextDate.year, currentNextDate.month + 1, currentNextDate.day);
          }
          transaction.update(doc.reference, {'nextPaymentDate': Timestamp.fromDate(nextPaymentDate)});
        });
        successCount++;
        print('Successfully processed payment for subscription ${doc.id}');
      } catch (e) {
        print('Failed to process payment for subscription ${doc.id}: $e');
        // Optionally, update subscription status to 'failed' or 'paused'
      }
    }
    print("Finished processing. $successCount payments were successful.");
    return successCount;
  }
}
