import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceItem {
  final String description;
  final int quantity;
  final double price;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'price': price,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }
}

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

class Invoice {
  final String id;
  final String merchantId;
  final String customerName;
  final String customerEmail;
  final List<InvoiceItem> items;
  final double totalAmount;
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime dueDate;

  Invoice({
    required this.id,
    required this.merchantId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.dueDate,
  });

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>?)
        ?.map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
        .toList() ?? [];

    return Invoice(
      id: doc.id,
      merchantId: data['merchantId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      items: itemsList,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: _statusFromString(data['status'] ?? 'draft'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': Timestamp.fromDate(dueDate),
    };
  }

  static InvoiceStatus _statusFromString(String status) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => InvoiceStatus.draft,
    );
  }
}
