import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String landlordId;
  final String address;
  final double rentAmount;

  Property({
    required this.id,
    required this.landlordId,
    required this.address,
    required this.rentAmount,
  });
}

class Tenancy {
  final String id;
  final String propertyId;
  final String tenantId;
  final DateTime rentDueDate;

  Tenancy({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.rentDueDate,
  });

  factory Tenancy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tenancy(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      tenantId: data['tenantId'] ?? '',
      rentDueDate: (data['rentDueDate'] as Timestamp).toDate(),
    );
  }
}
