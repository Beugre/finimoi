import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gamification_service.dart';
import '../../domain/entities/gamification_profile_model.dart';
import '../../domain/entities/badge_model.dart';
import '../../domain/entities/leaderboard_entry_model.dart';
import '../../domain/entities/question_model.dart';
import 'auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService();
});

final gamificationProfileProvider = StreamProvider<GamificationProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  final gamificationService = ref.watch(gamificationServiceProvider);
  return gamificationService.getGamificationProfile(user.uid);
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  final gamificationService = ref.watch(gamificationServiceProvider);
  return gamificationService.getLeaderboard();
});

import '../../domain/entities/challenge_model.dart';

final allBadgesProvider = StreamProvider<List<Badge>>((ref) {
  return FirebaseFirestore.instance.collection('badges').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Badge.fromFirestore(doc)).toList());
});

final activeChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  return FirebaseFirestore.instance
      .collection('challenges')
      .where('endDate', isGreaterThan: Timestamp.now())
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList());
});

final userChallengeProgressProvider =
    StreamProvider.family<DocumentSnapshot?, String>((ref, challengeId) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('user_challenges')
      .doc(challengeId)
      .snapshots();
});

final quizQuestionProvider = FutureProvider<Question?>((ref) {
  final gamificationService = ref.watch(gamificationServiceProvider);
  return gamificationService.getQuizQuestion();
});
