import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/gamification_provider.dart';
import '../../../domain/entities/badge_model.dart';
import '../../../domain/entities/challenge_model.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../../data/providers/user_provider.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamificationProfileAsync = ref.watch(gamificationProfileProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Récompenses'),
      body: gamificationProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Aucun profil de gamification trouvé.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPointsCard(context, profile.points, profile.level),
                const SizedBox(height: 16),
                _buildCashbackCard(context, ref.watch(userProfileProvider).value?.cashbackBalance ?? 0.0),
                const SizedBox(height: 16),
                _buildReferralCard(context),
                const SizedBox(height: 16),
                _buildQuizCard(context),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Mes Badges'),
                _buildBadgesSection(ref),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Défis de la Semaine'),
                _buildChallengesSection(ref),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, int points, int level) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mes Points', style: Theme.of(context).textTheme.titleMedium),
                      Text(points.toString(), style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mon Niveau', style: Theme.of(context).textTheme.titleMedium),
                      Text(level.toString(), style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/rewards/leaderboard'),
                icon: const Icon(Icons.leaderboard),
                label: const Text('Voir le classement'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBadgesSection(WidgetRef ref) {
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final profileAsync = ref.watch(gamificationProfileProvider);

    return allBadgesAsync.when(
      data: (allBadges) {
        return profileAsync.when(
          data: (profile) {
            if (profile == null || profile.earnedBadgeIds.isEmpty) {
              return const Text('Aucun badge gagné pour le moment.');
            }
            final earnedBadges = allBadges
                .where((b) => profile.earnedBadgeIds.contains(b.id))
                .toList();

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: earnedBadges.length,
                itemBuilder: (context, index) {
                  final badge = earnedBadges[index];
                  return _buildBadge(badge);
                },
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, s) => Text('Erreur: $e'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Erreur: $e'),
    );
  }

  Widget _buildBadge(Badge badge) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(badge.name.substring(0, 2)), // Placeholder for image
          ),
          const SizedBox(height: 8),
          Text(badge.name, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildChallengesSection(WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider);
    return challengesAsync.when(
      data: (challenges) {
        if (challenges.isEmpty) {
          return const Text('Aucun défi disponible pour le moment.');
        }
        return Column(
          children: challenges.map((c) => _buildChallengeCard(c, ref)).toList(),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Erreur: $e'),
    );
  }

  Widget _buildChallengeCard(Challenge challenge, WidgetRef ref) {
    final progressAsync = ref.watch(userChallengeProgressProvider(challenge.id));
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(challenge.description),
            const SizedBox(height: 8),
            progressAsync.when(
              data: (progressDoc) {
                final progress = progressDoc?.data() as Map<String, dynamic>?;
                final currentProgress = (progress?['progress'] ?? 0.0).toDouble();
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: currentProgress / challenge.target,
                    ),
                    Text('$currentProgress / ${challenge.target}'),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(value: 0),
              error: (e, s) => const Text('Erreur de chargement du progrès'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashbackCard(BuildContext context, double cashbackBalance) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard, color: Colors.orange, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mon Cashback', style: Theme.of(context).textTheme.titleMedium),
                  Text('${cashbackBalance.toStringAsFixed(2)} FCFA',
                      style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            ),
            ElevatedButton(onPressed: () {}, child: const Text('Utiliser')),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: const Icon(Icons.group_add, color: Colors.blue, size: 40),
        title: const Text('Parrainer un ami'),
        subtitle: const Text('Gagnez des points pour chaque ami parrainé!'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => context.push('/rewards/referral'),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: const Icon(Icons.quiz, color: Colors.orange, size: 40),
        title: const Text('Quiz Financier'),
        subtitle: const Text('Testez vos connaissances et gagnez des points!'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => context.push('/rewards/quiz'),
      ),
    );
  }
}
