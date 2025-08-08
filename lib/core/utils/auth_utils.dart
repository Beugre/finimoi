import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthUtils {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir l'utilisateur actuel
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Vérifier si l'utilisateur est connecté
  static bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Obtenir l'ID de l'utilisateur actuel
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Obtenir l'email de l'utilisateur actuel
  static String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // Obtenir les données de l'utilisateur actuel depuis Firestore
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final currentUser = getCurrentUser();
      if (currentUser == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

  // Obtenir le nom complet de l'utilisateur actuel
  static Future<String> getCurrentUserFullName() async {
    try {
      final userData = await getCurrentUserData();
      if (userData != null) {
        final firstName = userData['firstName'] ?? '';
        final lastName = userData['lastName'] ?? '';
        return '$firstName $lastName'.trim();
      }
      return getCurrentUser()?.displayName ?? 'Utilisateur';
    } catch (e) {
      print('Erreur lors de la récupération du nom utilisateur: $e');
      return 'Utilisateur';
    }
  }

  // Déconnexion
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      throw e;
    }
  }

  // Mettre à jour les données utilisateur
  static Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      final currentUser = getCurrentUser();
      if (currentUser == null) return false;

      await _firestore.collection('users').doc(currentUser.uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour des données utilisateur: $e');
      return false;
    }
  }

  // Vérifier si l'utilisateur a complété son profil
  static Future<bool> isProfileComplete() async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return false;

      // Vérifier les champs obligatoires
      final requiredFields = ['firstName', 'lastName', 'phone'];
      for (String field in requiredFields) {
        if (userData[field] == null || userData[field].toString().isEmpty) {
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Erreur lors de la vérification du profil: $e');
      return false;
    }
  }
}
