import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/merchant_model.dart';

class MerchantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createMerchant({
    required String businessName,
    required String businessCategory,
    required String phoneNumber,
    required String address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final qrCodeData = 'finimoi://pay?merchantId=${user.uid}';

    final merchant = MerchantModel(
      id: user.uid, // Use user's UID as merchant ID
      userId: user.uid,
      businessName: businessName,
      businessCategory: businessCategory,
      address: {'fullAddress': address},
      phoneNumber: phoneNumber,
      email: user.email ?? '',
      qrCodeData: qrCodeData,
      createdAt: Timestamp.now(),
    );

    await _firestore
        .collection('merchants')
        .doc(user.uid)
        .set(merchant.toMap());

    // Also update the user's role
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update({'role': 'merchant'});
  }

  Future<MerchantModel?> getMerchantProfile(String userId) async {
    final doc = await _firestore.collection('merchants').doc(userId).get();
    if (doc.exists) {
      return MerchantModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<bool> isCurrentUserMerchant() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data() as Map<String, dynamic>;
      return data['role'] == 'merchant';
    });
  }
}
