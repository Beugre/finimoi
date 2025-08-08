import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/real_savings_service.dart';
import '../../domain/entities/savings_model.dart';

// Provider pour le service d'épargne
final realSavingsServiceProvider = Provider<RealSavingsService>((ref) {
  return RealSavingsService();
});

// Provider pour les épargnes de l'utilisateur
final userSavingsProvider = StreamProvider.family<List<SavingsModel>, String>((
  ref,
  userId,
) {
  final savingsService = ref.watch(realSavingsServiceProvider);
  return savingsService.getUserSavings(userId);
});

// Provider pour une épargne spécifique
final savingsProvider = StreamProvider.family<SavingsModel?, String>((
  ref,
  savingsId,
) {
  final savingsService = ref.watch(realSavingsServiceProvider);
  return savingsService.getSavingsById(savingsId);
});

// Provider pour les statistiques d'épargne
final savingsStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
      final savingsService = ref.watch(realSavingsServiceProvider);
      return savingsService.getSavingsStats(userId);
    });

// Provider pour l'historique des contributions
final contributionHistoryProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, savingsId) {
      final savingsService = ref.watch(realSavingsServiceProvider);
      return savingsService.getContributionHistory(savingsId);
    });

// Provider pour l'historique des retraits
final withdrawalHistoryProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, savingsId) {
      final savingsService = ref.watch(realSavingsServiceProvider);
      return savingsService.getWithdrawalHistory(savingsId);
    });
