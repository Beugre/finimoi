import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/gift_card_provider.dart'; // Re-using this provider for now

class PartnerHubScreen extends ConsumerWidget {
  const PartnerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(partnerStoresProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Nos Partenaires'),
      body: storesAsync.when(
        data: (stores) {
          if (stores.isEmpty) {
            return const Center(child: Text('Aucun partenaire disponible.'));
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un partenaire...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: stores.length,
                itemBuilder: (context, index) {
                  final store = stores[index];
                  return Card(
                    child: Column(
                      children: [
                        Expanded(child: Center(child: Icon(Icons.store, size: 48))), // Placeholder for logo
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
