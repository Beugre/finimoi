import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/real_tontine_service.dart';
import '../../domain/entities/tontine_model.dart';

// Provider pour le vrai service des tontines
final realTontineServiceProvider = Provider<RealTontineService>((ref) {
  return RealTontineService();
});

// Provider pour les tontines de l'utilisateur
final userTontinesProvider = StreamProvider.family<List<TontineModel>, String>((
  ref,
  userId,
) {
  final tontineService = ref.watch(realTontineServiceProvider);
  return tontineService.getUserTontines(userId);
});

// Provider pour les tontines disponibles
final availableTontinesProvider = StreamProvider<List<TontineModel>>((ref) {
  final tontineService = ref.watch(realTontineServiceProvider);
  return tontineService.getAvailableTontines();
});

// Provider pour une tontine spécifique
final tontineProvider = StreamProvider.family<TontineModel?, String>((
  ref,
  tontineId,
) {
  final tontineService = ref.watch(realTontineServiceProvider);
  return tontineService.getTontineById(tontineId);
});

// Provider pour les résultats de recherche de tontines
final tontineSearchProvider = FutureProvider.family<List<TontineModel>, String>(
  (ref, query) {
    final tontineService = ref.watch(realTontineServiceProvider);
    return tontineService.searchTontines(query);
  },
);

// Provider pour les statistiques des tontines
final tontineStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
      final tontineService = ref.watch(realTontineServiceProvider);
      return tontineService.getTontineStats(userId);
    });
