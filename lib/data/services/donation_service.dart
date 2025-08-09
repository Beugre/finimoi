import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finimoi/core/utils/auth_utils.dart';
import 'package:finimoi/domain/entities/donation_model.dart';
import 'package:finimoi/domain/entities/partner_orphanage_model.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PartnerOrphanage>> getPartnerOrphanages() {
    return _firestore.collection('partner_orphanages').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => PartnerOrphanage.fromFirestore(doc))
            .toList());
  }

  Future<void> makeDonation({
    required String orphanageId,
    required double amount,
    bool isRecurring = false,
  }) async {
    final userId = AuthUtils.getCurrentUser()?.uid;
    if (userId == null) throw Exception('Utilisateur non connecté.');

    final orphanageDoc = await _firestore.collection('partner_orphanages').doc(orphanageId).get();
    if (!orphanageDoc.exists) throw Exception('Orphelinat partenaire non trouvé.');
    final orphanage = PartnerOrphanage.fromFirestore(orphanageDoc);

    // In a real app, the orphanage would have a user ID to receive funds.
    // Here, we'll just log the donation. A central Finimoi account would collect and distribute.
    await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        final balance = (userDoc.data()!['balance'] ?? 0.0).toDouble();

        if (balance < amount) throw Exception('Solde insuffisant.');

        // 1. Deduct amount from user
        transaction.update(userRef, {'balance': FieldValue.increment(-amount)});

        // 2. Create donation record
        final donationRef = _firestore.collection('donations').doc();
        final newDonation = Donation(
            id: donationRef.id,
            userId: userId,
            orphanageId: orphanageId,
            orphanageName: orphanage.name,
            amount: amount,
            isRecurring: isRecurring,
            createdAt: Timestamp.now(),
        );
        transaction.set(donationRef, newDonation.toMap());

        // 3. If recurring, create a recurring donation record (similar to subscription)
        if (isRecurring) {
            final recurringRef = _firestore.collection('recurring_donations').doc();
            transaction.set(recurringRef, {
                'userId': userId,
                'orphanageId': orphanageId,
                'amount': amount,
                'frequency': 'monthly',
                'nextDonationDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
                'status': 'active',
            });
        }
    });
  }

  Future<void> createSampleOrphanages() async {
      final orphanages = [
          {'name': 'La Maison du Bonheur', 'description': 'Aide aux enfants démunis.', 'logoUrl': ''},
          {'name': 'Village d\'Enfants SOS', 'description': 'Soutien aux familles et enfants.', 'logoUrl': ''},
      ];
      for (var o in orphanages) {
          await _firestore.collection('partner_orphanages').add(o);
      }
  }
}
