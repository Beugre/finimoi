import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/real_credit_service.dart';
import '../../domain/entities/credit_model.dart';

// Provider pour le service de crédit
final realCreditServiceProvider = Provider<RealCreditService>((ref) {
  return RealCreditService();
});

// Provider pour les crédits de l'utilisateur
final userCreditsProvider = StreamProvider.family<List<CreditModel>, String>((
  ref,
  userId,
) {
  final creditService = ref.watch(realCreditServiceProvider);
  return creditService.getUserCredits(userId);
});

// Provider pour un crédit spécifique
final creditProvider = StreamProvider.family<CreditModel?, String>((
  ref,
  creditId,
) {
  final creditService = ref.watch(realCreditServiceProvider);
  return creditService.getCreditById(creditId);
});

// Provider pour les statistiques de crédit
final creditStatsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, userId) {
    final creditService = ref.watch(realCreditServiceProvider);
    return creditService.getCreditStats(userId);
  },
);

// Provider pour l'historique des paiements
final paymentHistoryProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, creditId) {
      final creditService = ref.watch(realCreditServiceProvider);
      return creditService.getPaymentHistory(creditId);
    });
