import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/custom_app_bar.dart';

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Tableau de Bord Marchand'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSalesSummary(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildSalesChart(context),
            const SizedBox(height: 24),
            _buildRecentTransactions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Bienvenue, Marchand!',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSalesSummary(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            title: 'Ventes Aujourd\'hui',
            value: '15,250 FCFA',
            icon: Icons.point_of_sale,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            title: 'Transactions',
            value: '5',
            icon: Icons.receipt_long,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionItem(
          context,
          icon: Icons.qr_code_2,
          label: 'Générer QR',
          onTap: () => context.push('/merchant/qr'),
        ),
        _buildActionItem(
          context,
          icon: Icons.history,
          label: 'Historique',
          onTap: () {},
        ),
        _buildActionItem(
          context,
          icon: Icons.settings,
          label: 'Paramètres',
          onTap: () {},
        ),
        _buildActionItem(
          context,
          icon: Icons.subscriptions,
          label: 'Abonnements',
          onTap: () => context.push('/merchant/subscriptions'),
        ),
        _buildActionItem(
          context,
          icon: Icons.receipt,
          label: 'Factures',
          onTap: () => context.push('/merchant/invoices'),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 32),
          onPressed: onTap,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  Widget _buildSalesChart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ventes de la semaine',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: [
                _makeGroupData(0, 5),
                _makeGroupData(1, 6.5),
                _makeGroupData(2, 5),
                _makeGroupData(3, 7.5),
                _makeGroupData(4, 9),
                _makeGroupData(5, 11.5),
                _makeGroupData(6, 6.5),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const style = TextStyle(fontSize: 10);
                      String text;
                      switch (value.toInt()) {
                        case 0:
                          text = 'Lun';
                          break;
                        case 1:
                          text = 'Mar';
                          break;
                        case 2:
                          text = 'Mer';
                          break;
                        case 3:
                          text = 'Jeu';
                          break;
                        case 4:
                          text = 'Ven';
                          break;
                        case 5:
                          text = 'Sam';
                          break;
                        case 6:
                          text = 'Dim';
                          break;
                        default:
                          text = '';
                          break;
                      }
                      return SideTitleWidget(
                          axisSide: meta.axisSide, child: Text(text, style: style));
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.blue,
          width: 16,
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions Récentes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('Paiement de Client ${index + 1}'),
              subtitle: const Text('Il y a 5 minutes'),
              trailing: const Text(
                '+ 5,000 FCFA',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ],
    );
  }
}
