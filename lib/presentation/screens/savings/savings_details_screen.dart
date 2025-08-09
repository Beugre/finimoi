import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/real_savings_provider.dart';
import '../../../domain/entities/savings_model.dart';
import '../../widgets/common/custom_text_field.dart';

class SavingsDetailsScreen extends ConsumerWidget {
  final String savingsId;
  const SavingsDetailsScreen({super.key, required this.savingsId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(savingsProvider(savingsId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'Objectif'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        ],
      ),
      body: savingsAsync.when(
        data: (savings) {
          if (savings == null) {
            return const Center(child: Text('Objectif non trouvé.'));
          }
          return _buildSavingsDetails(context, ref, savings);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildSavingsDetails(
      BuildContext context, WidgetRef ref, SavingsModel savings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGoalHeader(context, savings),
        const SizedBox(height: 24),
        _buildStatsCards(context, savings),
        const SizedBox(height: 24),
        _buildAutoSaveSection(context, ref, savings),
        const SizedBox(height: 24),
        _buildContributionHistory(context, ref, savings.id),
      ],
    );
  }

  Widget _buildGoalHeader(BuildContext context, SavingsModel savings) {
    final color = AppColors.info;
    final progress = savings.progressPercentage / 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.savings, size: 64, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            savings.goalName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${savings.currentAmount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${savings.targetAmount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${savings.progressPercentage.toStringAsFixed(1)}% de l\'objectif atteint',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, SavingsModel savings) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Restant',
            '${(savings.targetAmount - savings.currentAmount).toStringAsFixed(0)} FCFA',
            Icons.flag,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'Échéance',
            '${savings.deadline.difference(DateTime.now()).inDays} jours',
            Icons.calendar_today,
            AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildContributionHistory(
      BuildContext context, WidgetRef ref, String savingsId) {
    final historyAsync = ref.watch(contributionHistoryProvider(savingsId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dépôts récents',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return const Text('Aucune contribution pour le moment.');
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return _buildDepositTile(item);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erreur: $err')),
        ),
      ],
    );
  }

  Widget _buildDepositTile(Map<String, dynamic> contribution) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: AppColors.success),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dépôt manuel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  (contribution['createdAt'] as Timestamp).toDate().toString(),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '+ ${contribution['amount']} FCFA',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSaveSection(
      BuildContext context, WidgetRef ref, SavingsModel savings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dépôts Automatiques',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Activer les dépôts automatiques'),
          value: savings.autoSave,
          onChanged: (value) {
            ref
                .read(realSavingsServiceProvider)
                .updateSavings(savings.id, {'autoSave': value});
          },
        ),
        if (savings.autoSave)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CustomTextField(
              label: 'Montant du dépôt automatique',
              initialValue: savings.autoSaveAmount.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null) {
                  ref
                      .read(realSavingsServiceProvider)
                      .updateSavings(savings.id, {'autoSaveAmount': amount});
                }
              },
            ),
          ),
      ],
    );
  }
}
