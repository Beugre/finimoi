import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gamification_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  static User? get currentUser => _auth.currentUser;

  // Email & Password Sign Up
  static Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    String? referralCode,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(fullName);

      // Create user profile in Firestore
      if (result.user != null) {
        final names = fullName.split(' ');
        final firstName = names.isNotEmpty ? names.first : 'Utilisateur';
        final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

        await _createUserProfile(
          userId: result.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          referredBy: referralCode,
        );

        // Assign a referral code to the new user
        await GamificationService().assignReferralCode(result.user!.uid);

        // Handle the referral if a code was provided
        if (referralCode != null && referralCode.isNotEmpty) {
          await GamificationService().handleReferral(result.user!.uid, referralCode);
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  // Email & Password Sign In
  static Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Vérifier si le profil utilisateur existe, sinon le créer
      if (result.user != null) {
        await _ensureUserProfileExists(result.user!);

        // Mettre à jour la dernière connexion
        await _updateLastLogin(result.user!.uid);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  // Google Sign In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);

      // Créer ou mettre à jour le profil utilisateur
      if (result.user != null) {
        await _ensureUserProfileExists(result.user!);
        await _updateLastLogin(result.user!.uid);
      }

      return result;
    } catch (e) {
      throw Exception('Erreur lors de la connexion Google: $e');
    }
  }

  // Apple Sign In
  static Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final result = await _auth.signInWithCredential(oauthCredential);

      // Créer ou mettre à jour le profil utilisateur
      if (result.user != null) {
        await _ensureUserProfileExists(result.user!);
        await _updateLastLogin(result.user!.uid);
      }

      return result;
    } catch (e) {
      throw Exception('Erreur lors de la connexion Apple: $e');
    }
  }

  // Phone Sign In
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // Verify SMS Code
  static Future<UserCredential?> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);

      // Créer ou mettre à jour le profil utilisateur
      if (result.user != null) {
        await _ensureUserProfileExists(result.user!);
        await _updateLastLogin(result.user!.uid);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Password Reset
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // Delete Account
  static Future<void> deleteAccount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Supprimer d'abord le profil Firestore
        await _firestore.collection('users').doc(userId).delete();
      }
      await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }

  // Send Email Verification
  static Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception(
        'Erreur lors de l\'envoi de l\'email de vérification: $e',
      );
    }
  }

  // Check if email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload current user
  static Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Handle Firebase Auth Exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cette adresse email.';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cette adresse email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      case 'operation-not-allowed':
        return 'Cette méthode de connexion n\'est pas activée.';
      case 'invalid-credential':
        return 'Les identifiants fournis sont incorrects.';
      case 'network-request-failed':
        return 'Erreur de connexion réseau. Vérifiez votre connexion internet.';
      default:
        return 'Une erreur s\'est produite: ${e.message}';
    }
  }

  // Create user profile if it doesn't exist
  static Future<void> _ensureUserProfileExists(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        final displayName = user.displayName ?? 'Utilisateur';
        final names = displayName.split(' ');
        final firstName = names.isNotEmpty ? names.first : 'Utilisateur';
        final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

        await _createUserProfile(
          userId: user.uid,
          email: user.email ?? '',
          firstName: firstName,
          lastName: lastName,
        );
      }
    } catch (e) {
      print('Erreur lors de la vérification du profil utilisateur: $e');
    }
  }

  // Create user profile
  static Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    String? referredBy,
  }) async {
    try {
      final finimoimTag = await _generateUniqueFinIMoiTag(firstName, lastName);

      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName'.trim(),
        'balance': 0.0,
        'isEmailVerified': _auth.currentUser?.emailVerified ?? false,
        'isPhoneVerified': false,
        'createdAt': Timestamp.now(),
        'lastLoginAt': Timestamp.now(),
        'profilePicture': null,
        'phoneNumber': null,
        'dateOfBirth': null,
        'address': null,
        'finimoimtag': finimoimTag,
        'currency': 'XOF', // Devise par défaut
        'country': 'CI', // Pays par défaut (Côte d'Ivoire)
        'referredBy': referredBy,
      });
    } catch (e) {
      print('Erreur lors de la création du profil: $e');
      // Ne pas bloquer l'authentification
    }
  }

  // Update last login time
  static Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': Timestamp.now(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la dernière connexion: $e');
    }
  }

  // Generate unique FinIMoi tag
  static Future<String> _generateUniqueFinIMoiTag(
    String firstName,
    String lastName,
  ) async {
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

  // Check if tag exists
  static Future<bool> _tagExists(String tag) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('finimoimtag', isEqualTo: tag)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification du tag: $e');
      return false;
    }
  }
}
