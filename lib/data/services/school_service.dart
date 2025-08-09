import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finimoi/core/utils/auth_utils.dart';
import 'package:finimoi/domain/entities/school_models.dart';

class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get students linked to the current parent user
  Stream<List<Student>> getMyStudents() {
    final parentId = AuthUtils.getCurrentUser()?.uid;
    if (parentId == null) return Stream.value([]);
    return _firestore
        .collection('students')
        .where('parentUserId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                Student(id: doc.id, name: doc['name'], schoolId: doc['schoolId'], parentUserId: doc['parentUserId']))
            .toList());
  }

  // Get fees for a specific student
  Stream<List<Fee>> getFeesForStudent(String studentId) {
    return _firestore
        .collection('fees')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'unpaid')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Fee.fromFirestore(doc)).toList());
  }

  // Pay a fee
  Future<void> payFee(String feeId) async {
     final parentId = AuthUtils.getCurrentUser()?.uid;
    if (parentId == null) throw Exception('Utilisateur non connecté.');

    final feeDoc = await _firestore.collection('fees').doc(feeId).get();
    if (!feeDoc.exists) throw Exception('Facture non trouvée.');
    final fee = Fee.fromFirestore(feeDoc);

    // In a real app, the school would have a user ID to receive funds.
    await _firestore.runTransaction((transaction) async {
        final parentRef = _firestore.collection('users').doc(parentId);
        final parentDoc = await transaction.get(parentRef);
        final balance = (parentDoc.data()!['balance'] ?? 0.0).toDouble();

        if (balance < fee.amount) throw Exception('Solde insuffisant.');

        // 1. Deduct amount from parent
        transaction.update(parentRef, {'balance': FieldValue.increment(-fee.amount)});

        // 2. Mark fee as paid
        transaction.update(feeDoc.reference, {'status': 'paid'});
    });
  }
}
