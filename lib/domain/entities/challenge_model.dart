import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType {
  transfer, // e.g., "Send money 5 times"
  save, // e.g., "Save 50,000 FCFA"
  login, // e.g., "Log in 7 days in a row"
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int target; // The goal to reach (e.g., 5 transfers, 50000 FCFA)
  final int rewardPoints;
  final Timestamp startDate;
  final Timestamp endDate;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.rewardPoints,
    required this.startDate,
    required this.endDate,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: ChallengeType.values
          .firstWhere((e) => e.name == data['type'], orElse: () => ChallengeType.transfer),
      target: data['target'] ?? 0,
      rewardPoints: data['rewardPoints'] ?? 0,
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
    );
  }
}
