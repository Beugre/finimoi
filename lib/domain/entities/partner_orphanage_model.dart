import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerOrphanage {
  final String id;
  final String name;
  final String description;
  final String logoUrl;

  PartnerOrphanage({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
  });

  factory PartnerOrphanage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartnerOrphanage(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
    );
  }
}
