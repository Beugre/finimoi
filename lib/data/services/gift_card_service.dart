import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finimoi/core/utils/auth_utils.dart';
import 'package:finimoi/domain/entities/gift_card_model.dart';
import 'package:finimoi/domain/entities/partner_store_model.dart';
import 'package:uuid/uuid.dart';

class GiftCardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PartnerStore>> getPartnerStores() {
    return _firestore.collection('partner_stores').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PartnerStore.fromFirestore(doc)).toList());
  }

  Stream<List<GiftCard>> getMyGiftCards() {
    final userId = AuthUtils.getCurrentUser()?.uid;
    if (userId == null) return Stream.value([]);
    return _firestore
        .collection('gift_cards')
        .where('ownerId', isEqualTo: userId)
        .where('expiryDate', isGreaterThan: Timestamp.now())
        .where('remainingBalance', isGreaterThan: 0)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GiftCard.fromFirestore(doc)).toList());
  }

  Future<void> purchaseGiftCard({
    required String storeId,
    required double amount,
    required String recipientId,
  }) async {
    final purchaserId = AuthUtils.getCurrentUser()?.uid;
    if (purchaserId == null) throw Exception('Utilisateur non connecté.');

    final storeDoc = await _firestore.collection('partner_stores').doc(storeId).get();
    if (!storeDoc.exists) throw Exception('Magasin partenaire non trouvé.');
    final store = PartnerStore.fromFirestore(storeDoc);

    await _firestore.runTransaction((transaction) async {
      final purchaserRef = _firestore.collection('users').doc(purchaserId);
      final purchaserDoc = await transaction.get(purchaserRef);
      final balance = (purchaserDoc.data()!['balance'] ?? 0.0).toDouble();

      if (balance < amount) throw Exception('Solde insuffisant.');

      // 1. Deduct amount from purchaser
      transaction.update(purchaserRef, {'balance': FieldValue.increment(-amount)});

      // 2. Create the gift card
      final giftCardRef = _firestore.collection('gift_cards').doc();
      final newGiftCard = GiftCard(
        id: giftCardRef.id,
        ownerId: recipientId,
        storeId: store.id,
        storeName: store.name,
        storeLogoUrl: store.logoUrl,
        initialAmount: amount,
        remainingBalance: amount,
        issueDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 365)), // 1 year expiry
        code: const Uuid().v4(),
      );
      transaction.set(giftCardRef, newGiftCard.toMap());
    });

    // 3. Send notification (outside transaction)
    // await NotificationService().createNotification(...)
  }

  Future<void> createSamplePartnerStores() async {
    final stores = [
      {'name': 'Super U', 'logoUrl': '', 'category': 'Supermarché'},
      {'name': 'Total Energies', 'logoUrl': '', 'category': 'Carburant'},
      {'name': 'Canal+ Store', 'logoUrl': '', 'category': 'Divertissement'},
    ];
    for (var store in stores) {
      await _firestore.collection('partner_stores').add(store);
    }
  }
}
