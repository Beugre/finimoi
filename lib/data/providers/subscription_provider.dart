import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/data/services/subscription_service.dart';
import 'package:finimoi/domain/entities/subscription_plan_model.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

final merchantSubscriptionPlansProvider = StreamProvider<List<SubscriptionPlanModel>>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.getSubscriptionPlansForMerchant();
});

final subscriptionPlanDetailsProvider =
    FutureProvider.family<SubscriptionPlanModel?, String>((ref, planId) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.getSubscriptionPlan(planId);
});

final userSubscriptionsProvider = StreamProvider<List<SubscriptionModel>>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.getSubscriptionsForCurrentUser();
});
