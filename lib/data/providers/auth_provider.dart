import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref
      .watch(authStateProvider)
      .when(data: (user) => user, loading: () => null, error: (_, __) => null);
});

// Auth Controller
final authControllerProvider = Provider((ref) => AuthController(ref));

class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  // Sign Up with Email & Password
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    String? referralCode,
  }) async {
    try {
      final result = await AuthService.signUpWithEmailPassword(
        email: email,
        password: password,
        fullName: fullName,
        referralCode: referralCode,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign In with Email & Password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await AuthService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      return await AuthService.signInWithGoogle();
    } catch (e) {
      rethrow;
    }
  }

  // Sign In with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      return await AuthService.signInWithApple();
    } catch (e) {
      rethrow;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await AuthService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await AuthService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      await AuthService.deleteAccount();
    } catch (e) {
      rethrow;
    }
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      await AuthService.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Check Authentication State
  bool get isAuthenticated => AuthService.currentUser != null;
  bool get isEmailVerified => AuthService.isEmailVerified;
  User? get currentUser => AuthService.currentUser;
}
