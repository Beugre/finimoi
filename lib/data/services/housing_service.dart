import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finimoi/core/utils/auth_utils.dart';
import 'package:finimoi/domain/entities/housing_models.dart';

class HousingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For Tenant: Get their current tenancy agreement
  Stream<Tenancy?> getMyTenancy() {
    final userId = AuthUtils.getCurrentUser()?.uid;
    if (userId == null) return Stream.value(null);
    return _firestore
        .collection('tenancies')
        .where('tenantId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Tenancy.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // For Tenant: Get the details of their rented property
  Future<Property?> getPropertyDetails(String propertyId) async {
      final doc = await _firestore.collection('properties').doc(propertyId).get();
      if(doc.exists) {
          return Property(id: doc.id, landlordId: doc['landlordId'], address: doc['address'], rentAmount: doc['rentAmount']);
      }
      return null;
  }

  // For Tenant: Pay rent
  Future<void> payRent(String tenancyId, String propertyId, double amount) async {
    final tenantId = AuthUtils.getCurrentUser()?.uid;
    if (tenantId == null) throw Exception('Utilisateur non connecté.');

    final property = await getPropertyDetails(propertyId);
    if (property == null) throw Exception('Propriété non trouvée.');
    final landlordId = property.landlordId;

    await _firestore.runTransaction((transaction) async {
      final tenantRef = _firestore.collection('users').doc(tenantId);
      final landlordRef = _firestore.collection('users').doc(landlordId);
      final tenancyRef = _firestore.collection('tenancies').doc(tenancyId);

      final tenantDoc = await transaction.get(tenantRef);
      final balance = (tenantDoc.data()!['balance'] ?? 0.0).toDouble();

      if (balance < amount) throw Exception('Solde insuffisant.');

      // 1. Deduct rent from tenant
      transaction.update(tenantRef, {'balance': FieldValue.increment(-amount)});
      // 2. Add rent to landlord
      transaction.update(landlordRef, {'balance': FieldValue.increment(amount)});
      // 3. Update next rent due date
      final currentDueDate = (await transaction.get(tenancyRef)).data()!['rentDueDate'] as Timestamp;
      final newDueDate = DateTime(currentDueDate.toDate().year, currentDueDate.toDate().month + 1, currentDueDate.toDate().day);
      transaction.update(tenancyRef, {'rentDueDate': Timestamp.fromDate(newDueDate)});
    });
  }
}
