import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/services/statistics_service.dart';
import '../../widgets/common/custom_app_bar.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(userTransactionsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Statistiques'),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('Aucune transaction à analyser.'));
          }

          final stats = StatisticsService.calculateStats(transactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(context, stats),
                const SizedBox(height: 24),
                _buildSpendingChart(context, stats),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, TransactionStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(context, 'Revenus', stats.totalIncome, Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(context, 'Dépenses', stats.totalExpenses, Colors.red),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, String title, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${value.toStringAsFixed(0)} FCFA',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart(BuildContext context, TransactionStats stats) {
    final List<PieChartSectionData> sections =
        stats.spendingByCategory.entries.map((entry) {
      return PieChartSectionData(
        color: Colors.primaries[
            stats.spendingByCategory.keys.toList().indexOf(entry.key) %
                Colors.primaries.length],
        value: entry.value,
        title: stats.totalExpenses > 0
            ? '${(entry.value / stats.totalExpenses * 100).toStringAsFixed(0)}%'
            : '0%',
        radius: 80,
        titleStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dépenses par catégorie',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: stats.spendingByCategory.keys.map((category) {
            return Chip(
              label: Text(category),
              backgroundColor: Colors.primaries[
                  stats.spendingByCategory.keys.toList().indexOf(category) %
                      Colors.primaries.length]
                  .withOpacity(0.2),
            );
          }).toList(),
        ),
      ],
    );
  }
}
