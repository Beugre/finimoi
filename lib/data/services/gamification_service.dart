import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finimoi/domain/entities/leaderboard_entry_model.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/gamification_profile_model.dart';
import '../../domain/entities/question_model.dart';
import 'package:finimoi/core/utils/auth_utils.dart';


class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> awardPoints(String userId, int points, String reason) async {
    final gamificationRef =
        _firestore.collection('gamification_profiles').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(gamificationRef);

      if (!snapshot.exists) {
        // Create a new gamification profile if it doesn't exist
        final newProfile = GamificationProfile(
          userId: userId,
          points: points,
          lastUpdated: Timestamp.now(),
        );
        transaction.set(gamificationRef, newProfile.toMap());
      } else {
        final newPoints = (snapshot.data()!['points'] ?? 0) + points;
        transaction.update(gamificationRef, {
          'points': newPoints,
          'lastUpdated': Timestamp.now(),
        });
      }
    });

    // After awarding points, check for new badges
    await checkAndAwardBadges(userId);
  }

  Future<void> checkAndAwardBadges(String userId) async {
    final gamificationRef =
        _firestore.collection('gamification_profiles').doc(userId);
    final badgesRef = _firestore.collection('badges');

    final gamificationSnapshot = await gamificationRef.get();
    if (!gamificationSnapshot.exists) return;

    final profile = GamificationProfile.fromFirestore(gamificationSnapshot);
    final userPoints = profile.points;
    final earnedBadges = profile.earnedBadgeIds;

    final availableBadgesSnapshot = await badgesRef.get();
    for (final badgeDoc in availableBadgesSnapshot.docs) {
      final badgeId = badgeDoc.id;
      final pointsRequired = badgeDoc.data()['pointsRequired'] ?? 0;

      if (userPoints >= pointsRequired && !earnedBadges.contains(badgeId)) {
        // Award new badge
        await gamificationRef.update({
          'earnedBadgeIds': FieldValue.arrayUnion([badgeId])
        });

        // Send notification
        await NotificationService().createNotification(
          userId: userId,
          title: 'Nouveau Badge Débloqué!',
          message: 'Félicitations! Vous avez gagné le badge "${badgeDoc.data()['name']}".',
          type: 'badge_unlocked',
          data: {'badgeId': badgeId},
        );
      }
    }
  }

  Future<void> updateChallengeProgress(
      String userId, ChallengeType type, double value) async {
    final challengesRef = _firestore
        .collection('challenges')
        .where('type', isEqualTo: type.name)
        .where('endDate', isGreaterThan: Timestamp.now());

    final snapshot = await challengesRef.get();
    for (final challengeDoc in snapshot.docs) {
      final challenge = Challenge.fromFirestore(challengeDoc);
      final userChallengeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_challenges')
          .doc(challenge.id);

      final userChallengeSnapshot = await userChallengeRef.get();
      if (!userChallengeSnapshot.exists) {
        await userChallengeRef.set({
          'challengeId': challenge.id,
          'progress': value,
          'completed': value >= challenge.target,
        });
      } else {
        await userChallengeRef.update({
          'progress': FieldValue.increment(value),
          'completed': (userChallengeSnapshot.data()!['progress'] + value) >=
              challenge.target,
        });
      }
    }
  }

  Stream<GamificationProfile?> getGamificationProfile(String userId) {
    return _firestore
        .collection('gamification_profiles')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return GamificationProfile.fromFirestore(snapshot);
      }
      return null;
    });
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final gamificationSnapshot = await _firestore
          .collection('gamification_profiles')
          .orderBy('points', descending: true)
          .limit(50)
          .get();

      final List<LeaderboardEntry> leaderboard = [];
      int rank = 1;

      for (final doc in gamificationSnapshot.docs) {
        final profile = GamificationProfile.fromFirestore(doc);
        final userDoc =
            await _firestore.collection('users').doc(profile.userId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final userName = (userData['firstName'] ?? 'Utilisateur') +
              ' ' +
              (userData['lastName'] ?? 'Anonyme');

          leaderboard.add(LeaderboardEntry(
            userId: profile.userId,
            userName: userName,
            points: profile.points,
            rank: rank,
          ));
          rank++;
        }
      }
      return leaderboard;
    } catch (e) {
      print("Error getting leaderboard: $e");
      return [];
    }
  }

  // --- Referral System ---
  static const int referralBonusPoints = 50;

  String _generateReferralCode() {
    return const Uuid().v4().substring(0, 8).toUpperCase();
  }

  Future<void> assignReferralCode(String userId) async {
    final code = _generateReferralCode();
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'referralCode': code});
    } catch (e) {
      print("Failed to assign referral code: $e");
    }
  }

  Future<void> handleReferral(String newUserId, String referralCode) async {
    if (referralCode.isEmpty) return;

    try {
      // Find the referrer
      final querySnapshot = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Referral code not found.");
        return;
      }

      final referrerDoc = querySnapshot.docs.first;
      final referrerId = referrerDoc.id;

      // Avoid self-referral
      if (referrerId == newUserId) {
         print("User cannot refer themselves.");
        return;
      }

      // Award points
      await awardPoints(referrerId, referralBonusPoints, 'Ami parrainé');
      await awardPoints(newUserId, referralBonusPoints, 'Utilisation du code de parrainage');

      // Update new user's profile with the referrer's code
      await _firestore
          .collection('users')
          .doc(newUserId)
          .update({'referredBy': referralCode});

      print("Referral handled successfully!");

    } catch (e) {
      print("Error handling referral: $e");
    }
  }

  // Helper to create sample badges for testing
  Future<void> createSampleBadges() async {
    final badgesRef = _firestore.collection('badges');
    final batch = _firestore.batch();

    final badges = [
      {'id': 'beginner', 'name': 'Débutant', 'description': 'Vous avez fait votre premier pas!', 'imageUrl': '', 'pointsRequired': 10},
      {'id': 'explorer', 'name': 'Explorateur', 'description': 'Vous avez atteint 100 points!', 'imageUrl': '', 'pointsRequired': 100},
      {'id': 'veteran', 'name': 'Vétéran', 'description': 'Vous avez atteint 500 points!', 'imageUrl': '', 'pointsRequired': 500},
    ];

    for (final badgeData in badges) {
      batch.set(badgesRef.doc(badgeData['id'] as String), badgeData);
    }

    await batch.commit();
  }

  // Helper to create sample challenges for testing
  Future<void> createSampleChallenges() async {
    final challengesRef = _firestore.collection('challenges');
    final batch = _firestore.batch();

    final challenges = [
      {
        'title': 'Pro du Transfert',
        'description': 'Faites 5 transferts cette semaine',
        'type': 'transfer',
        'target': 5,
        'rewardPoints': 50,
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      },
      {
        'title': 'Super Épargnant',
        'description': 'Épargnez 100,000 FCFA',
        'type': 'save',
        'target': 100000,
        'rewardPoints': 100,
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      },
    ];

    for (final challengeData in challenges) {
      batch.set(challengesRef.doc(), challengeData);
    }

    await batch.commit();
  }

  // --- Quiz System ---
  Future<Question?> getQuizQuestion() async {
    final userId = AuthUtils.getCurrentUser()?.uid;
    if (userId == null) return null;

    final profileDoc = await _firestore.collection('gamification_profiles').doc(userId).get();
    final answeredIds = List<String>.from(profileDoc.data()?['answeredQuestionIds'] ?? []);

    QuerySnapshot questionsSnapshot;
    if (answeredIds.isEmpty) {
      questionsSnapshot = await _firestore.collection('questions').limit(1).get();
    } else {
      // This is not perfectly random and might be slow on large datasets,
      // but it's sufficient for this demo. A real implementation might use a
      // more sophisticated method to fetch a random document.
      questionsSnapshot = await _firestore
          .collection('questions')
          .where(FieldPath.documentId, whereNotIn: answeredIds)
          .limit(1)
          .get();
    }

    if (questionsSnapshot.docs.isNotEmpty) {
      return Question.fromFirestore(questionsSnapshot.docs.first);
    }
    return null; // No more questions available
  }

  Future<bool> submitQuizAnswer(String questionId, int answerIndex) async {
    final userId = AuthUtils.getCurrentUser()?.uid;
    if (userId == null) return false;

    final questionDoc = await _firestore.collection('questions').doc(questionId).get();
    if (!questionDoc.exists) return false;

    final question = Question.fromFirestore(questionDoc);
    final bool isCorrect = question.correctAnswerIndex == answerIndex;

    // Update answered questions list regardless of correctness to prevent re-answering
    await _firestore.collection('gamification_profiles').doc(userId).update({
      'answeredQuestionIds': FieldValue.arrayUnion([questionId]),
    });

    if (isCorrect) {
      await awardPoints(userId, question.points, 'Réponse correcte au quiz');
    }

    return isCorrect;
  }

  Future<void> createSampleQuestions() async {
    final questionsRef = _firestore.collection('questions');
    final batch = _firestore.batch();

    final questions = [
      {
        'text': 'Quel est le principal avantage d\'un compte épargne ?',
        'options': ['Dépenser sans compter', 'Gagner des intérêts', 'Payer des factures', 'Obtenir un crédit'],
        'correctAnswerIndex': 1,
        'points': 10,
      },
      {
        'text': 'Qu\'est-ce qu\'une tontine ?',
        'options': ['Un jeu de hasard', 'Un système d\'épargne rotatif', 'Une assurance vie', 'Un type de prêt'],
        'correctAnswerIndex': 1,
        'points': 10,
      },
      {
        'text': 'Que signifie "arrondi automatique" ?',
        'options': ['Payer plus cher', 'Ignorer les centimes', 'Mettre de côté la petite monnaie de chaque transaction', 'Recevoir une réduction'],
        'correctAnswerIndex': 2,
        'points': 15,
      },
    ];

    for (final q in questions) {
      batch.set(questionsRef.doc(), q);
    }
    await batch.commit();
  }
}
