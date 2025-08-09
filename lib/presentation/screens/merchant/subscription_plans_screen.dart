import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/subscription_provider.dart';
import 'package:finimoi/domain/entities/subscription_plan_model.dart';

class SubscriptionPlansScreen extends ConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(merchantSubscriptionPlansProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Mes Plans d\'Abonnement'),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(
              child: Text("Vous n'avez aucun plan d'abonnement."),
            );
          }
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return ListTile(
                title: Text(plan.planName),
                subtitle: Text('${plan.amount} FCFA / ${plan.frequency}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Navigate to plan details to see subscribers
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/merchant/subscriptions/create'),
        label: const Text('Créer un Plan'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
