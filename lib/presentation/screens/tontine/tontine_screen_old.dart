import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';

class TontineScreen extends ConsumerStatefulWidget {
  const TontineScreen({super.key});

  @override
  ConsumerState<TontineScreen> createState() => _TontineScreenState();
}

class _TontineScreenState extends ConsumerState<TontineScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'Tontines', centerTitle: true),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primaryViolet,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.6),
              tabs: const [
                Tab(text: 'Mes Tontines'),
                Tab(text: 'Créer'),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_MyTontinesTab(), _CreateTontineTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyTontinesTab extends StatelessWidget {
  const _MyTontinesTab();

  @override
  Widget build(BuildContext context) {
    // TODO: Get from provider/state management
    final tontines = _getDummyTontines();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tontines.isEmpty)
            _buildEmptyState(context)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tontines.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final tontine = tontines[index];
                return _TontineCard(tontine: tontine);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune tontine',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première tontine ou rejoignez-en une',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<TontineModel> _getDummyTontines() {
    return [
      TontineModel(
        id: '1',
        name: 'Famille Beugre',
        description: 'Tontine familiale mensuelle',
        totalAmount: 5000.0,
        monthlyContribution: 200.0,
        participants: 25,
        currentRound: 3,
        totalRounds: 25,
        nextPaymentDate: DateTime.now().add(const Duration(days: 12)),
        status: TontineStatus.active,
      ),
      TontineModel(
        id: '2',
        name: 'Collègues Bureau',
        description: 'Épargne collective équipe',
        totalAmount: 2400.0,
        monthlyContribution: 100.0,
        participants: 12,
        currentRound: 8,
        totalRounds: 12,
        nextPaymentDate: DateTime.now().add(const Duration(days: 5)),
        status: TontineStatus.active,
      ),
    ];
  }
}

class _CreateTontineTab extends StatelessWidget {
  const _CreateTontineTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créer une nouvelle tontine',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Create options
          _buildCreateOption(
            context,
            icon: Icons.group_add,
            title: 'Tontine Classique',
            subtitle: 'Chacun cotise, chacun reçoit à tour de rôle',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildCreateOption(
            context,
            icon: Icons.savings,
            title: 'Épargne Collective',
            subtitle: 'Épargner ensemble pour un objectif commun',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildCreateOption(
            context,
            icon: Icons.card_membership,
            title: 'Tontine à Points',
            subtitle: 'Système de points et récompenses',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          CustomButton(
            text: 'Rejoindre une tontine',
            onPressed: () {
              // TODO: Navigate to join tontine
            },
            variant: ButtonVariant.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primaryViolet, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TontineCard extends StatelessWidget {
  final TontineModel tontine;

  const _TontineCard({required this.tontine});

  @override
  Widget build(BuildContext context) {
    final progress = tontine.currentRound / tontine.totalRounds;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tontine.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tontine.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(tontine.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(tontine.status),
                  style: TextStyle(
                    color: _getStatusColor(tontine.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tour ${tontine.currentRound}/${tontine.totalRounds}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.primaryViolet.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryViolet,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryViolet,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  context,
                  'Total',
                  '${tontine.totalAmount.toStringAsFixed(0)} €',
                ),
              ),
              Expanded(
                child: _buildStat(
                  context,
                  'Mensuel',
                  '${tontine.monthlyContribution.toStringAsFixed(0)} €',
                ),
              ),
              Expanded(
                child: _buildStat(
                  context,
                  'Participants',
                  '${tontine.participants}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Next payment
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: AppColors.info, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Prochain paiement: ${_formatDate(tontine.nextPaymentDate)}',
                  style: TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getStatusColor(TontineStatus status) {
    switch (status) {
      case TontineStatus.active:
        return AppColors.success;
      case TontineStatus.pending:
        return AppColors.warning;
      case TontineStatus.completed:
        return AppColors.info;
      case TontineStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getStatusText(TontineStatus status) {
    switch (status) {
      case TontineStatus.active:
        return 'Active';
      case TontineStatus.pending:
        return 'En attente';
      case TontineStatus.completed:
        return 'Terminée';
      case TontineStatus.cancelled:
        return 'Annulée';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Demain';
    } else {
      return 'Dans $difference jours';
    }
  }
}

class TontineModel {
  final String id;
  final String name;
  final String description;
  final double totalAmount;
  final double monthlyContribution;
  final int participants;
  final int currentRound;
  final int totalRounds;
  final DateTime nextPaymentDate;
  final TontineStatus status;

  TontineModel({
    required this.id,
    required this.name,
    required this.description,
    required this.totalAmount,
    required this.monthlyContribution,
    required this.participants,
    required this.currentRound,
    required this.totalRounds,
    required this.nextPaymentDate,
    required this.status,
  });
}

enum TontineStatus { active, pending, completed, cancelled }
