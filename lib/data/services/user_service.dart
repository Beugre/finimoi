import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _usersCollection = _firestore.collection(
    'users',
  );

  // Create or update user profile
  static Future<void> createUserProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    final userModel = UserModel(
      id: userId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      balance: 0.0,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified:
          FirebaseAuth.instance.currentUser?.emailVerified ?? false,
      isPhoneVerified: false,
    );

    await _usersCollection.doc(userId).set(userModel.toFirestore());
  }

  // Get user profile
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  // Stream user profile - for real-time updates
  static Stream<UserModel?> streamUserProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update user profile
  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _usersCollection.doc(userId).update(data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  // Update user balance
  static Future<void> updateBalance(String userId, double newBalance) async {
    try {
      await _usersCollection.doc(userId).update({'balance': newBalance});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du solde: $e');
    }
  }

  // Add amount to user balance
  static Future<void> addToBalance(String userId, double amount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(_usersCollection.doc(userId));
        if (!userDoc.exists) {
          throw Exception('Utilisateur non trouvé');
        }

        final currentBalance =
            (userDoc.data() as Map<String, dynamic>)['balance'] ?? 0.0;
        final newBalance = currentBalance + amount;

        transaction.update(_usersCollection.doc(userId), {
          'balance': newBalance,
        });
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout au solde: $e');
    }
  }

  // Rechercher un utilisateur par email
  static Future<UserModel?> findUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return UserModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Erreur lors de la recherche de l\'utilisateur: $e');
    }
  }

  // Rechercher des utilisateurs par nom/email pour auto-complétion
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      final results = await _usersCollection
          .where('firstName', isGreaterThanOrEqualTo: query)
          .where('firstName', isLessThan: query + 'z')
          .limit(10)
          .get();

      return results.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Update last login
  static Future<void> updateLastLogin(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Non-critical error, log it but don't throw
      print('Error updating last login: $e');
    }
  }

  // Delete user profile
  static Future<void> deleteUserProfile(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du profil: $e');
    }
  }

  // Get all users
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  // Save FCM token for push notifications
  static Future<void> saveFcmToken(String userId, String token) async {
    try {
      await _usersCollection.doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      // Non-critical error, log it but don't throw
      print('Error saving FCM token: $e');
    }
  }

  // Add test funds to user balance (temporary method for testing)
  static Future<void> addTestFunds(String userId, double amount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _usersCollection.doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('Utilisateur non trouvé');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final currentBalance = (userData['balance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance + amount;

        transaction.update(userRef, {'balance': newBalance});
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout des fonds: $e');
    }
  }

  // --- Finimoi Junior ---
  static Future<String> createJuniorAccount({
    required String parentAccountId,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Junior accounts don't have their own email/auth for this simplified version.
      // The parent's email could be used or a placeholder.
      final parentData = await getUserProfile(parentAccountId);
      if (parentData == null) throw Exception('Parent account not found');

      final juniorUserModel = UserModel(
        id: '', // Firestore will generate
        email: 'junior.${firstName.toLowerCase()}.${lastName.toLowerCase()}@finimoi.app', // Placeholder email
        firstName: firstName,
        lastName: lastName,
        balance: 0.0,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: false,
        isPhoneVerified: false,
        isJuniorAccount: true,
        parentAccountId: parentAccountId,
      );

      final docRef = await _usersCollection.add(juniorUserModel.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du compte junior: $e');
    }
  }

  static Stream<List<UserModel>> getJuniorAccounts(String parentAccountId) {
    return _usersCollection
        .where('parentAccountId', isEqualTo: parentAccountId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }
}
