import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/data/providers/gamification_provider.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Classement'),
      body: leaderboardAsync.when(
        data: (leaderboard) {
          if (leaderboard.isEmpty) {
            return const Center(
              child: Text("Le classement est vide pour le moment."),
            );
          }
          return ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(entry.rank.toString()),
                ),
                title: Text(entry.userName),
                trailing: Text('${entry.points} pts'),
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
