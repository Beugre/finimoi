import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finimoi/core/utils/auth_utils.dart';
import 'package:finimoi/domain/entities/invoice_model.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createInvoice({
    required String customerName,
    required String customerEmail,
    required DateTime dueDate,
    required List<InvoiceItem> items,
  }) async {
    final merchantId = AuthUtils.getCurrentUser()?.uid;
    if (merchantId == null) {
      throw Exception('Aucun marchand connecté.');
    }

    final totalAmount = items.fold(0.0, (sum, item) => sum + item.total);

    final invoice = Invoice(
      id: '', // Firestore will generate
      merchantId: merchantId,
      customerName: customerName,
      customerEmail: customerEmail,
      items: items,
      totalAmount: totalAmount,
      status: InvoiceStatus.draft,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );

    final docRef = await _firestore.collection('invoices').add(invoice.toMap());
    return docRef.id;
  }

  Stream<List<Invoice>> getInvoicesForMerchant() {
    final merchantId = AuthUtils.getCurrentUser()?.uid;
    if (merchantId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('invoices')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList());
  }

  Future<void> updateInvoiceStatus(String invoiceId, InvoiceStatus newStatus) async {
    await _firestore.collection('invoices').doc(invoiceId).update({
      'status': newStatus.name,
    });
  }

  // In a real app, this would generate and email a PDF.
  // Here, we'll just mark it as sent.
  Future<void> sendInvoice(String invoiceId) async {
    await updateInvoiceStatus(invoiceId, InvoiceStatus.sent);
    // TODO: Add notification for the customer if they are a user.
  }
}
