import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/donation_provider.dart';
import 'package:go_router/go_router.dart';

class DonationHubScreen extends ConsumerWidget {
  const DonationHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orphanagesAsync = ref.watch(partnerOrphanagesProvider);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Faire un Don'),
      body: orphanagesAsync.when(
        data: (orphanages) {
          if (orphanages.isEmpty) {
            return const Center(child: Text('Aucun orphelinat partenaire pour le moment.'));
          }
          return ListView.builder(
            itemCount: orphanages.length,
            itemBuilder: (context, index) {
              final orphanage = orphanages[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.home)),
                title: Text(orphanage.name),
                subtitle: Text(orphanage.description),
                onTap: () => context.push('/donations/${orphanage.id}', extra: orphanage),
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
