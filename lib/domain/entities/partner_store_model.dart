import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerStore {
  final String id;
  final String name;
  final String logoUrl;
  final String category;
  final String description;
  final String address;
  final GeoPoint? location;

  PartnerStore({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.category,
    required this.description,
    required this.address,
    this.location,
  });

  factory PartnerStore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartnerStore(
      id: doc.id,
      name: data['name'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      category: data['category'] ?? 'Général',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] as GeoPoint?,
    );
  }
}
