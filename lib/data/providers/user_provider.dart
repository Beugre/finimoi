import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_model.dart';
import '../../domain/entities/transfer_model.dart';
import '../services/user_service.dart';
import '../services/transfer_service.dart';
import '../services/payment_service.dart';
import 'auth_provider.dart';

// Services
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final juniorAccountsProvider = StreamProvider<List<UserModel>>((ref) {
  final parentId = ref.watch(currentUserProvider)?.uid;
  if (parentId == null) {
    return Stream.value([]);
  }
  return ref.watch(userServiceProvider).getJuniorAccounts(parentId);
});

final transferServiceProvider = Provider<TransferService>((ref) {
  return TransferService();
});

// User Profile Provider
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(null);

  return UserService.streamUserProfile(currentUser.uid);
});

// User Balance Provider
final userBalanceProvider = Provider<double>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  return userProfile.when(
    data: (user) => user?.balance ?? 0.0,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// User Transactions Provider - convertit TransferModel en TransactionModel pour l'affichage
final userTransactionsProvider = StreamProvider<List<TransferModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(<TransferModel>[]);
      }

      final transferService = ref.watch(transferServiceProvider);

      // Récupérer TOUS les transferts de l'utilisateur (envoyés ET reçus via senderId)
      return transferService.getUserTransfers(user.uid);
    },
    loading: () => Stream.value(<TransferModel>[]),
    error: (_, __) => Stream.value(<TransferModel>[]),
  );
});

// Fonctions d'aide pour la conversion
// Transaction Controller
// Provider pour les transactions récentes d'un utilisateur - utilise TransferService pour les vraies données
final recentTransactionsProvider = StreamProvider<List<TransferModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser?.uid == null) {
    return Stream.value([]);
  }

  // Utiliser TransferService pour récupérer les vraies données récentes
  final transferService = TransferService();

  // Récupérer TOUS les transferts (envoyés ET reçus) pour l'utilisateur actuel
  return transferService.getUserTransfers(currentUser!.uid).map((transfers) {
    // Trier par date et prendre les 10 plus récents
    transfers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transfers.take(10).toList();
  });
});

// Transaction Controller
final transactionControllerProvider = Provider<TransactionController>((ref) {
  return TransactionController(ref);
});

class TransactionController {
  final Ref _ref;

  TransactionController(this._ref);

  // Send money to another user by email
  Future<void> sendMoneyByEmail({
    required String recipientEmail,
    required double amount,
    String? description,
  }) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      // Find recipient by email
      final recipient = await UserService.findUserByEmail(recipientEmail);
      if (recipient == null) {
        throw Exception('Aucun utilisateur trouvé avec cet email');
      }

      final result = await TransferService().performTransfer(
        TransferRequest(
          recipientId: recipient.id,
          recipientName: recipient.fullName,
          recipientPhone: recipient.phoneNumber,
          amount: amount,
          currency: 'XOF',
          type: TransferType.internal,
          description: description,
        ),
      );

      if (!result.isSuccess) {
        throw Exception(result.error);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Send money to another user
  Future<void> sendMoney({
    required String recipientId,
    required double amount,
    String? description,
  }) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      // Cette méthode n'est plus nécessaire car on a d'autres méthodes plus spécifiques
      // Supprimé car redondant avec sendMoneyByEmail
    } catch (e) {
      rethrow;
    }
  }

  // Recharge account via payment service
  Future<void> rechargeAccount({
    required double amount,
    required PaymentMethod method,
  }) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      // Utiliser le service de paiement professionnel
      await PaymentService.initiateRecharge(
        userId: currentUser.uid,
        amount: amount,
        method: method,
        currency: 'XOF',
        metadata: {
          'description': 'Recharge compte FinIMoi',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get transaction history
  Future<List<TransferModel>> getTransactionHistory({int limit = 20}) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      // Utiliser le stream et le convertir en Future
      final transfers = await TransferService()
          .getUserTransfers(currentUser.uid)
          .first;
      return transfers.take(limit).toList();
    } catch (e) {
      rethrow;
    }
  }
}

// User Controller
final userControllerProvider = Provider((ref) => UserController(ref));

class UserController {
  final Ref _ref;

  UserController(this._ref);

  // Create user profile after registration
  Future<void> createUserProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      await UserService.createUserProfile(
        userId: currentUser.uid,
        email: currentUser.email!,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      // Update last login
      await UserService.updateLastLogin(currentUser.uid);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      await UserService.updateUserProfile(currentUser.uid, data);
    } catch (e) {
      rethrow;
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await UserService.searchUsers(query);
    } catch (e) {
      rethrow;
    }
  }
}
