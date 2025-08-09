import 'package:cloud_firestore/cloud_firestore.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int pointsRequired;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.pointsRequired,
  });

  factory Badge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Badge(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      pointsRequired: data['pointsRequired'] ?? 0,
    );
  }
}
