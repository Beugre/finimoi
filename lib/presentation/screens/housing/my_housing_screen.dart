import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/housing_provider.dart';

class MyHousingScreen extends ConsumerWidget {
  const MyHousingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenancyAsync = ref.watch(myTenancyProvider);
    final propertyAsync = ref.watch(myPropertyDetailsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Mon Logement'),
      body: tenancyAsync.when(
        data: (tenancy) {
          if (tenancy == null) {
            return const Center(child: Text('Aucun contrat de location trouvé.'));
          }
          return propertyAsync.when(
            data: (property) {
              if (property == null) {
                return const Center(child: Text('Détails de la propriété non trouvés.'));
              }
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adresse: ${property.address}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text('Loyer: ${property.rentAmount} FCFA'),
                    Text('Prochain paiement le: ${tenancy.rentDueDate.toLocal().toString().split(' ')[0]}'),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(housingServiceProvider).payRent(tenancy.id, property.id, property.rentAmount);
                      },
                      child: const Text('Payer le Loyer'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erreur: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
