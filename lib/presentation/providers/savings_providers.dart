import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/real_savings_service.dart';
import '../../domain/entities/savings_model.dart';

/// Provider pour toutes les épargnes de l'utilisateur
final userSavingsProvider = StreamProvider<List<SavingsModel>>((ref) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return Stream.value([]);
  }

  final service = ref.watch(realSavingsServiceProvider);
  return service.getUserSavings(currentUser.uid);
});

/// Provider pour les épargnes actives (où isActive = true)
final activeSavingsProvider = StreamProvider<List<SavingsModel>>((ref) {
  return ref
      .watch(userSavingsProvider)
      .when(
        data: (savings) =>
            Stream.value(savings.where((s) => s.isActive).toList()),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Provider pour les épargnes de groupe (simulé pour l'instant)
final groupSavingsProvider = StreamProvider<List<SavingsModel>>((ref) {
  return ref
      .watch(userSavingsProvider)
      .when(
        data: (savings) => Stream.value(
          // TODO: Ajouter la logique pour identifier les épargnes de groupe
          // Pour l'instant, on retourne une liste vide
          <SavingsModel>[],
        ),
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
});

/// Provider pour les statistiques d'épargne
final savingsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return {
      'totalSavings': 0,
      'totalAmount': 0.0,
      'activeSavings': 0,
      'completedSavings': 0,
    };
  }

  final service = ref.watch(realSavingsServiceProvider);
  return service.getSavingsStats(currentUser.uid);
});

/// Provider pour obtenir une épargne spécifique
final savingsByIdProvider = StreamProvider.family<SavingsModel?, String>((
  ref,
  savingsId,
) {
  final service = ref.watch(realSavingsServiceProvider);
  return service.getSavingsById(savingsId);
});

/// Provider pour créer une nouvelle épargne
final createSavingsProvider = FutureProvider.family<String?, SavingsModel>((
  ref,
  savings,
) async {
  final service = ref.watch(realSavingsServiceProvider);
  return service.createSavings(savings);
});
