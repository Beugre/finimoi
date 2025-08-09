import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/presentation/widgets/common/custom_button.dart';
import 'package:finimoi/data/providers/subscription_provider.dart';
import 'package:go_router/go_router.dart';

class SubscriptionApprovalScreen extends ConsumerStatefulWidget {
  final String planId;
  const SubscriptionApprovalScreen({super.key, required this.planId});

  @override
  ConsumerState<SubscriptionApprovalScreen> createState() =>
      _SubscriptionApprovalScreenState();
}

class _SubscriptionApprovalScreenState
    extends ConsumerState<SubscriptionApprovalScreen> {
  bool _isLoading = false;

  Future<void> _subscribe() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ref
          .read(subscriptionServiceProvider)
          .createSubscription(widget.planId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abonnement réussi!')),
        );
        context.go('/home'); // Or to a subscription management screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final planAsync =
        ref.watch(subscriptionPlanDetailsProvider(widget.planId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Confirmer l\'Abonnement'),
      body: planAsync.when(
        data: (plan) {
          if (plan == null) {
            return const Center(child: Text('Plan non trouvé.'));
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Vous êtes sur le point de souscrire à:',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  plan.planName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  '${plan.amount} FCFA',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '/ ${plan.frequency}',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                CustomButton(
                  text: 'Confirmer et Payer',
                  onPressed: _subscribe,
                  isLoading: _isLoading,
                )
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
