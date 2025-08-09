import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/user_provider.dart';

class JuniorDashboardScreen extends ConsumerWidget {
  const JuniorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juniorAccountsAsync = ref.watch(juniorAccountsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Finimoi Junior'),
      body: juniorAccountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Text("Vous n'avez aucun compte junior."),
            );
          }
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: CircleAvatar(child: Text(account.initials)),
                title: Text(account.fullName),
                subtitle: Text('Solde: ${account.balance} FCFA'),
                onTap: () {
                  // TODO: Navigate to junior account details screen
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profile/junior/create'),
        label: const Text('Créer un Compte Junior'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
