import 'package:cloud_firestore/cloud_firestore.dart';

class GamificationProfile {
  final String userId;
  final int points;
  final int level;
  final List<String> earnedBadgeIds;
  final List<String> answeredQuestionIds;
  final Timestamp lastUpdated;

  GamificationProfile({
    required this.userId,
    this.points = 0,
    this.level = 1,
    this.earnedBadgeIds = const [],
    this.answeredQuestionIds = const [],
    required this.lastUpdated,
  });

  factory GamificationProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GamificationProfile(
      userId: doc.id,
      points: data['points'] ?? 0,
      level: data['level'] ?? 1,
      earnedBadgeIds: List<String>.from(data['earnedBadgeIds'] ?? []),
      answeredQuestionIds: List<String>.from(data['answeredQuestionIds'] ?? []),
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points,
      'level': level,
      'earnedBadgeIds': earnedBadgeIds,
      'answeredQuestionIds': answeredQuestionIds,
      'lastUpdated': lastUpdated,
    };
  }
}
