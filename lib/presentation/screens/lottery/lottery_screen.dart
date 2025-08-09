import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/lottery_provider.dart';

class LotteryScreen extends ConsumerWidget {
  const LotteryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawsAsync = ref.watch(activeLotteryDrawsProvider);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Loterie'),
      body: drawsAsync.when(
        data: (draws) {
          if (draws.isEmpty) {
            return const Center(child: Text('Aucun tirage en cours.'));
          }
          return ListView.builder(
            itemCount: draws.length,
            itemBuilder: (context, index) {
              final draw = draws[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(draw.name, style: Theme.of(context).textTheme.headlineSmall),
                      Text('Gros lot actuel: ${draw.prizePool.toStringAsFixed(0)} FCFA'),
                      Text('Prix du ticket: ${draw.ticketPrice.toStringAsFixed(0)} FCFA'),
                      Text('Tirage le: ${draw.drawDate.toLocal().toString().split(' ')[0]}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(lotteryServiceProvider).buyTicket(draw.id);
                        },
                        child: const Text('Acheter un ticket'),
                      ),
                    ],
                  ),
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
