import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/subscription_provider.dart';

class ManageSubscriptionsScreen extends ConsumerWidget {
  const ManageSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(userSubscriptionsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Mes Abonnements'),
      body: subscriptionsAsync.when(
        data: (subscriptions) {
          if (subscriptions.isEmpty) {
            return const Center(
              child: Text("Vous n'avez aucun abonnement actif."),
            );
          }
          return ListView.builder(
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final sub = subscriptions[index];
              final isActive = sub.status.name == 'active';
              return ListTile(
                title: Text('Abonnement Marchand ${sub.merchantId.substring(0, 6)}'), // Placeholder name
                subtitle: Text('${sub.amount} FCFA / ${sub.frequency.name}'),
                trailing: ElevatedButton(
                  onPressed: isActive ? () {
                    ref.read(subscriptionServiceProvider).cancelSubscription(sub.id);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.red : Colors.grey,
                  ),
                  child: Text(isActive ? 'Annuler' : 'Annulé'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
