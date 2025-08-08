import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_model.dart';

class UserSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Rechercher des utilisateurs par FinIMoiTag
  Future<List<UserModel>> searchUsersByTag(String tag) async {
    if (tag.isEmpty) return [];

    try {
      final query = await _firestore
          .collection('users')
          .where('finimoi_tag', isGreaterThanOrEqualTo: tag.toLowerCase())
          .where('finimoi_tag', isLessThan: '${tag.toLowerCase()}z')
          .limit(20)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Rechercher par numéro de téléphone
  Future<UserModel?> searchUserByPhone(String phone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Rechercher par email
  Future<UserModel?> searchUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Obtenir les contacts récents
  Future<List<UserModel>> getRecentContacts(String userId) async {
    try {
      // Récupérer les transactions récentes pour trouver les contacts
      final transactions = await _firestore
          .collection('transactions')
          .where('senderId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final Set<String> contactIds = {};
      for (final doc in transactions.docs) {
        final data = doc.data();
        if (data['recipientId'] != null) {
          contactIds.add(data['recipientId']);
        }
      }

      if (contactIds.isEmpty) return [];

      final users = <UserModel>[];
      for (final contactId in contactIds) {
        final userDoc = await _firestore
            .collection('users')
            .doc(contactId)
            .get();
        if (userDoc.exists) {
          users.add(UserModel.fromFirestore(userDoc));
        }
      }

      return users;
    } catch (e) {
      return [];
    }
  }

  // Recherche globale dans tous les champs
  Future<List<UserModel>> searchUsers(
    String query, {
    String? excludeUserId,
  }) async {
    if (query.isEmpty || query.length < 2) return [];

    try {
      final queryLower = query.toLowerCase();

      // Récupérer tous les utilisateurs et filtrer côté client
      // (Firebase ne supporte pas la recherche textuelle avancée)
      final allUsersQuery = await _firestore
          .collection('users')
          .limit(100) // Limite pour éviter de charger trop de données
          .get();

      final matchingUsers = <UserModel>[];

      for (final doc in allUsersQuery.docs) {
        final user = UserModel.fromFirestore(doc);

        // Exclure l'utilisateur connecté
        if (excludeUserId != null && user.id == excludeUserId) {
          continue;
        }

        // Rechercher dans nom complet, email, et finimoi_tag
        final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
        final email = user.email.toLowerCase();
        final tag = user.finimoiTag?.toLowerCase() ?? '';

        if (fullName.contains(queryLower) ||
            email.contains(queryLower) ||
            tag.contains(queryLower) ||
            (queryLower.startsWith('@') &&
                tag.contains(queryLower.substring(1)))) {
          matchingUsers.add(user);
        }
      }

      return matchingUsers;
    } catch (e) {
      print('Erreur recherche utilisateurs: $e');
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Générer un FinIMoiTag unique
  Future<String> generateUniqueTag(String firstName, String lastName) async {
    final baseName = '${firstName.toLowerCase()}${lastName.toLowerCase()}'
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    String tag = baseName;
    int counter = 1;

    while (await _tagExists(tag)) {
      tag = '$baseName$counter';
      counter++;
    }

    return tag;
  }

  Future<bool> _tagExists(String tag) async {
    final query = await _firestore
        .collection('users')
        .where('finimoi_tag', isEqualTo: tag)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // Vérifier si un tag est disponible
  Future<bool> isTagAvailable(String tag) async {
    return !(await _tagExists(tag));
  }
}

// Provider
final userSearchServiceProvider = Provider<UserSearchService>((ref) {
  return UserSearchService();
});

// Provider pour la recherche en temps réel
final userSearchProvider = FutureProvider.family<List<UserModel>, String>((
  ref,
  query,
) {
  final searchService = ref.watch(userSearchServiceProvider);
  if (query.length < 2) return Future.value([]);

  // Obtenir l'ID de l'utilisateur connecté pour l'exclure
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  return searchService.searchUsers(query, excludeUserId: currentUserId);
});

// Provider pour les contacts récents
final recentContactsProvider = FutureProvider.family<List<UserModel>, String>((
  ref,
  userId,
) {
  final searchService = ref.watch(userSearchServiceProvider);
  return searchService.getRecentContacts(userId);
});
