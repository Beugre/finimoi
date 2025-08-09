import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/tontine_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/tontine_provider.dart';

class TontineDetailScreen extends ConsumerStatefulWidget {
  final String tontineId;

  const TontineDetailScreen({super.key, required this.tontineId});

  @override
  ConsumerState<TontineDetailScreen> createState() =>
      _TontineDetailScreenState();
}

class _TontineDetailScreenState extends ConsumerState<TontineDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tontineAsync = ref.watch(tontineProvider(widget.tontineId));
    return tontineAsync.when(
      data: (tontine) {
        if (tontine == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: const Center(child: Text('Tontine non trouvée')),
          );
        }
        return _buildTontineDetail(tontine);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 18, color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text('$error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(tontineProvider(widget.tontineId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTontineDetail(TontineModel tontine) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec gradient
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getStatusColor(tontine.status),
                      _getStatusColor(tontine.status).withOpacity(0.8),
                      AppColors.primaryViolet.withOpacity(0.9),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getTypeIcon(tontine.type),
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tontine.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tontine.typeText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tontine.statusText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (tontine.description.isNotEmpty) ...[
                          Text(
                            tontine.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showMenuBottomSheet(tontine),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ),
            ],
          ),

          // Stats rapides
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildQuickStats(tontine),
            ),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryViolet,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primaryViolet,
                indicatorWeight: 3,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Aperçu'),
                  Tab(text: 'Membres'),
                  Tab(text: 'Cycles'),
                  Tab(text: 'Historique'),
                ],
              ),
            ),
          ),

          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(tontine),
                _buildMembersTab(tontine),
                _buildCyclesTab(tontine),
                _buildHistoryTab(tontine),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(tontine),
    );
  }

  Widget _buildQuickStats(TontineModel tontine) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Cagnotte',
            value: '${tontine.totalPool.toInt()} F',
            icon: Icons.account_balance,
            color: AppColors.primaryViolet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Membres',
            value: '${tontine.currentMembers}/${tontine.maxMembers}',
            icon: Icons.people,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Cycle',
            value: '${tontine.currentCycle}/${tontine.maxMembers}',
            icon: Icons.refresh,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
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
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(TontineModel tontine) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations principales
          _buildInfoSection(
            title: 'Informations principales',
            children: [
              _buildInfoRow('Créé par', tontine.creatorName),
              _buildInfoRow('Date de création', _formatDate(tontine.createdAt)),
              _buildInfoRow('Date de début', _formatDate(tontine.startDate)),
              if (tontine.endDate != null)
                _buildInfoRow('Date de fin', _formatDate(tontine.endDate!)),
              _buildInfoRow(
                'Contribution',
                '${tontine.contributionAmount.toInt()} FCFA',
              ),
              _buildInfoRow('Fréquence', tontine.frequencyText),
              _buildInfoRow('Type', tontine.typeText),
            ],
          ),

          const SizedBox(height: 32),

          // Progression
          _buildInfoSection(
            title: 'Progression',
            children: [
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: tontine.currentMembers / tontine.maxMembers,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  _getStatusColor(tontine.status),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${tontine.currentMembers} membres sur ${tontine.maxMembers} maximum',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Prochaines échéances
          if (tontine.status == TontineStatus.active) ...[
            _buildInfoSection(
              title: 'Mes Préférences',
              children: [
                SwitchListTile(
                  title: const Text('Paiement automatique'),
                  subtitle: const Text(
                      'Activer pour payer automatiquement vos contributions'),
                  value: tontine.members
                          .firstWhere(
                              (m) => m.userId == ref.watch(currentUserProvider)?.uid,
                              orElse: () => TontineMember(
                                  userId: '',
                                  name: '',
                                  joinedAt: DateTime.now(),
                                  isActive: false,
                                  position: 0))
                          .autoPayEnabled,
                  onChanged: (value) {
                    final userId = ref.read(currentUserProvider)?.uid;
                    if (userId != null) {
                      ref.read(tontineServiceProvider).updateAutoPayStatus(
                            tontine.id,
                            userId,
                            value,
                          );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildInfoSection(
              title: 'Prochaines échéances',
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: AppColors.warning),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prochaine contribution',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getNextContributionDate(tontine),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${tontine.contributionAmount.toInt()} F',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersTab(TontineModel tontine) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: tontine.members.length,
      itemBuilder: (context, index) {
        final member = tontine.members[index];
        final isCreator = member.userId == tontine.creatorId;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: isCreator
                ? Border.all(color: AppColors.primaryViolet.withOpacity(0.3))
                : null,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCreator
                  ? AppColors.primaryViolet
                  : AppColors.success.withOpacity(0.1),
              child: isCreator
                  ? const Icon(Icons.star, color: Colors.white)
                  : Text(
                      member.name[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            title: Text(
              member.name,
              style: TextStyle(
                fontWeight: isCreator ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCreator ? 'Créateur' : 'Membre',
                  style: TextStyle(
                    color: isCreator
                        ? AppColors.primaryViolet
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Rejoint le ${_formatDate(member.joinedAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: member.isActive
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.isActive ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      color: member.isActive
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pos. ${member.position}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCyclesTab(TontineModel tontine) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: tontine.cycles.length,
      itemBuilder: (context, index) {
        final cycle = tontine.cycles[index];
        final isCurrentCycle = cycle.cycleNumber == tontine.currentCycle;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: isCurrentCycle
                ? Border.all(color: AppColors.primaryViolet, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrentCycle
                            ? AppColors.primaryViolet.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCurrentCycle ? Icons.play_circle : Icons.check_circle,
                        color: isCurrentCycle
                            ? AppColors.primaryViolet
                            : Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cycle ${cycle.cycleNumber}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCurrentCycle
                                  ? AppColors.primaryViolet
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bénéficiaire: ${cycle.beneficiaryName}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentCycle)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryViolet,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'En cours',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCycleInfo(
                        'Date début',
                        _formatDate(cycle.startDate),
                        Icons.play_arrow,
                      ),
                    ),
                    if (cycle.endDate != null)
                      Expanded(
                        child: _buildCycleInfo(
                          'Date fin',
                          _formatDate(cycle.endDate!),
                          Icons.stop,
                        ),
                      ),
                    Expanded(
                      child: _buildCycleInfo(
                        'Montant',
                        '${cycle.totalAmount.toInt()} F',
                        Icons.monetization_on,
                      ),
                    ),
                  ],
                ),
                if (cycle.contributions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Contributions (${cycle.contributions.length}/${tontine.maxMembers})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: cycle.contributions.length / tontine.maxMembers,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      isCurrentCycle
                          ? AppColors.primaryViolet
                          : AppColors.success,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(TontineModel tontine) {
    // Simuler l'historique pour le moment
    final activities = [
      {
        'type': 'creation',
        'date': tontine.createdAt,
        'message': 'Tontine créée par ${tontine.creatorName}',
      },
      {
        'type': 'join',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'message': 'Marie K. a rejoint la tontine',
      },
      {
        'type': 'contribution',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'message': 'Contribution de 50 000 F reçue',
      },
      {
        'type': 'payout',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'message': 'Paiement de 300 000 F effectué',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getActivityColor(
                    activity['type'] as String,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getActivityIcon(activity['type'] as String),
                  color: _getActivityColor(activity['type'] as String),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['message'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(activity['date'] as DateTime),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryViolet),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget? _buildBottomActions(TontineModel tontine) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final isCreator = user.uid == tontine.creatorId;
    final isMember = tontine.members.any((m) => m.userId == user.uid);

    if (!isMember && tontine.status == TontineStatus.draft) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _joinTontine(tontine),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryViolet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Rejoindre cette tontine',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (isMember && tontine.status == TontineStatus.active) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _makeContribution(tontine),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Contribuer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (isCreator) ...[
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _manageTontine(tontine),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryViolet,
                    side: BorderSide(color: AppColors.primaryViolet),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Gérer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return null;
  }

  void _showMenuBottomSheet(TontineModel tontine) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Partager'),
            onTap: () {
              Navigator.pop(context);
              _shareTontine();
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              _manageNotifications();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Aide'),
            onTap: () {
              Navigator.pop(context);
              _showHelp();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _joinTontine(TontineModel tontine) async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Utilisateur non connecté');

      final tontineService = ref.read(tontineServiceProvider);
      await tontineService.joinTontine(
        tontine.id,
        user.uid,
        user.displayName ?? 'Utilisateur',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez rejoint la tontine !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _makeContribution(TontineModel tontine) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effectuer une contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Montant de contribution: ${tontine.contributionAmount.toStringAsFixed(0)} FCFA',
            ),
            const SizedBox(height: 16),
            const Text('Confirmez-vous cette contribution ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contribution effectuée avec succès !'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _manageTontine(TontineModel tontine) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Gérer la tontine',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier les paramètres'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paramètres modifiés !')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Gérer les membres'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gestion des membres !')),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _shareTontine() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager la tontine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Partager cette tontine avec vos contacts'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Code d\'invitation: TONT2024',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lien de partage copié !'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Partager'),
          ),
        ],
      ),
    );
  }

  void _manageNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Gérer les notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Notifications de contribution'),
              subtitle: const Text('Être notifié lors des contributions'),
              value: true,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Notifications ${value ? "activées" : "désactivées"}',
                    ),
                  ),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Rappels de tour'),
              subtitle: const Text('Rappel avant votre tour'),
              value: true,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Rappels ${value ? "activés" : "désactivés"}',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment fonctionne une tontine ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Chaque membre contribue un montant fixe'),
            Text('• Chaque tour, un membre reçoit la cagnotte'),
            Text('• Les tours sont planifiés selon la fréquence'),
            Text('• Tous les membres doivent participer'),
            SizedBox(height: 16),
            Text(
              'Besoin d\'aide ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Contactez-nous via le chat de support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support contacté !')),
              );
            },
            child: const Text('Contacter le support'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TontineStatus status) {
    switch (status) {
      case TontineStatus.draft:
        return AppColors.warning;
      case TontineStatus.active:
        return AppColors.success;
      case TontineStatus.completed:
        return AppColors.info;
      case TontineStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getTypeIcon(TontineType type) {
    switch (type) {
      case TontineType.classic:
        return Icons.group;
      case TontineType.rotating:
        return Icons.rotate_right;
      case TontineType.investment:
        return Icons.trending_up;
      case TontineType.emergency:
        return Icons.emergency;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'creation':
        return AppColors.primaryViolet;
      case 'join':
        return AppColors.success;
      case 'contribution':
        return AppColors.warning;
      case 'payout':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'creation':
        return Icons.add_circle;
      case 'join':
        return Icons.person_add;
      case 'contribution':
        return Icons.monetization_on;
      case 'payout':
        return Icons.payment;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getNextContributionDate(TontineModel tontine) {
    // Logique simple pour calculer la prochaine date
    final now = DateTime.now();
    switch (tontine.frequency) {
      case TontineFrequency.weekly:
        return _formatDate(now.add(const Duration(days: 7)));
      case TontineFrequency.biweekly:
        return _formatDate(now.add(const Duration(days: 14)));
      case TontineFrequency.monthly:
        return _formatDate(DateTime(now.year, now.month + 1, now.day));
      case TontineFrequency.quarterly:
        return _formatDate(DateTime(now.year, now.month + 3, now.day));
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
