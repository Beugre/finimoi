import 'package:finimoi/data/services/real_card_service.dart';
import 'package:finimoi/data/services/stripe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/card_providers.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../domain/entities/card_model.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final StripeService _stripeService = StripeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 320,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.primaryDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        Expanded(child: _buildCardsCarousel()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Mes Cartes'),
                    Tab(text: 'Transactions'),
                    Tab(text: 'Paramètres'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMyCardsTab(),
            _buildTransactionsTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOrderCardDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card),
        label: const Text('Commander une carte'),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Mes Cartes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => _showCardDetails(),
                icon: const Icon(Icons.visibility, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardsCarousel() {
    return Consumer(
      builder: (context, ref, child) {
        final cardsAsync = ref.watch(userCardsProvider);

        return cardsAsync.when(
          data: (cards) {
            if (cards.isEmpty) {
              return _buildNoCardsWidget();
            }

            return SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildCreditCard(cards[index]),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          error: (error, stack) => SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erreur de chargement des cartes',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoCardsWidget() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade400, Colors.grey.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.credit_card_outlined,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune carte disponible',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Demandez votre première carte',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(CardModel card) {
    // Détermine les couleurs en fonction du type de carte
    List<Color> getCardGradient() {
      switch (card.cardType.toLowerCase()) {
        case 'premium':
          return [AppColors.primary, AppColors.primaryDark];
        case 'business':
          return [AppColors.accent, AppColors.accentDark];
        case 'gold':
          return [const Color(0xFFFFD700), const Color(0xFFDAA520)];
        default:
          return [AppColors.textPrimary, const Color(0xFF374151)];
      }
    }

    final isBlocked = !card.isActive;
    // Hardcoded credit score for now.
    const creditScore = 720;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: getCardGradient(),
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.cardName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.cardTypeDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Solde disponible',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                CurrencyFormatter.formatCFA(card.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    card.maskedCardNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    children: [
                       if (card.isVirtual)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'VIRTUELLE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.yellow[600], size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Score: $creditScore',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isBlocked)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'CARTE BLOQUÉE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMyCardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildCardLimits(),
          const SizedBox(height: 24),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Consumer(builder: (context, ref, child) {
      final cardsAsync = ref.watch(userCardsProvider);
      return cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty || _currentPage >= cards.length) {
            return const SizedBox.shrink(); // Or a placeholder
          }
          final card = cards[_currentPage];
          final isBlocked = !card.isActive;

          final actions = [
            {
              'icon': isBlocked ? Icons.lock_open : Icons.lock,
              'label': isBlocked ? 'Débloquer' : 'Bloquer',
              'color': isBlocked ? Colors.green : Colors.red,
              'onTap': () => _showBlockCardDialog(),
            },
            {
              'icon': Icons.pin,
              'label': 'Code PIN',
              'color': Colors.blue,
              'onTap': () => _showChangePinDialog(),
            },
            {
              'icon': Icons.contactless,
              'label': 'Sans contact',
              'color': Colors.green,
              'onTap': () => _toggleContactless(),
            },
            {
              'icon': Icons.settings,
              'label': 'Limites',
              'color': Colors.orange,
              'onTap': () => _showLimitsDialog(),
            },
             {
              'icon': Icons.share,
              'label': 'Partager',
              'color': Colors.purple,
              'onTap': () => _showShareDialog(card),
            },
          ]..removeWhere((action) {
              // Only show share button if the user is the owner
              if (action['label'] == 'Partager') {
                final currentUserId = ref.read(authProvider).currentUser?.uid;
                return card.userId != currentUserId;
              }
              // Only show block/pin/limits buttons if the user is the owner
              if (['Bloquer', 'Débloquer', 'Code PIN', 'Limites'].contains(action['label'])) {
                 final currentUserId = ref.read(authProvider).currentUser?.uid;
                return card.userId != currentUserId;
              }
              return false;
            });

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                const Text(
                  'Actions rapides',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: actions.map((action) {
                    return GestureDetector(
                      onTap: action['onTap'] as VoidCallback,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: (action['color'] as Color).withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              color: action['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action['label'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (err, stack) => const Text('Error loading actions'),
      );
    });
  }
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: actions.map((action) {
              return GestureDetector(
                onTap: action['onTap'] as VoidCallback,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardLimits() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Limites de carte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildLimitItem(
            'Paiements journaliers',
            150000,
            500000,
            Icons.payment,
          ),
          const SizedBox(height: 12),
          _buildLimitItem('Retraits ATM', 50000, 200000, Icons.atm),
          const SizedBox(height: 12),
          _buildLimitItem(
            'Achats en ligne',
            200000,
            1000000,
            Icons.shopping_cart,
          ),
        ],
      ),
    );
  }

  Widget _buildLimitItem(
    String title,
    double used,
    double limit,
    IconData icon,
  ) {
    final percentage = (used / limit * 100).clamp(0, 100);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      color: percentage > 80 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 80 ? Colors.red : AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${CurrencyFormatter.formatCFA(used)} / ${CurrencyFormatter.formatCFA(limit)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transactions récentes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final cardsAsync = ref.watch(userCardsProvider);

              return cardsAsync.when(
                data: (cards) {
                  if (cards.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune transaction récente',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // Prendre la première carte pour les transactions
                  final firstCard = cards.first;
                  final transactionsAsync = ref.watch(
                    cardTransactionsProvider(firstCard.id),
                  );

                  return transactionsAsync.when(
                    data: (transactions) {
                      final recentTransactions = transactions.take(5).toList();

                      if (recentTransactions.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aucune transaction récente',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentTransactions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final transaction = recentTransactions[index];
                          return _buildTransactionItem(
                            merchant:
                                transaction['description'] ?? 'Transaction',
                            amount: (transaction['amount'] ?? 0.0).toDouble(),
                            time: _formatTransactionTime(
                              transaction['createdAt'],
                            ),
                            category: transaction['category'] ?? 'Général',
                            icon: _getTransactionIcon(
                              transaction['type'] ?? 'general',
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => const Center(
                      child: Text(
                        'Erreur de chargement des transactions',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(
                  child: Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTransactionTime(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return '--:--';
      }

      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'shopping':
      case 'retail':
        return Icons.shopping_bag;
      case 'transport':
        return Icons.directions_car;
      case 'fuel':
        return Icons.local_gas_station;
      case 'entertainment':
        return Icons.movie;
      case 'transfer':
        return Icons.send;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.receipt;
    }
  }

  Widget _buildTransactionItem({
    required String merchant,
    required double amount,
    required String time,
    required String category,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: amount > 0
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: amount > 0 ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                merchant,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                category,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatCFA(amount.abs()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: amount > 0 ? Colors.green : Colors.red,
              ),
            ),
            Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final cardsAsync = ref.watch(userCardsProvider);

        return cardsAsync.when(
          data: (cards) {
            if (cards.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucune carte disponible',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Demandez une carte pour voir vos transactions',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Prendre la première carte pour les transactions
            final firstCard = cards.first;
            final transactionsAsync = ref.watch(
              cardTransactionsProvider(firstCard.id),
            );

            return transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune transaction',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Vos transactions apparaîtront ici',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: _buildTransactionItem(
                        merchant: transaction['description'] ?? 'Transaction',
                        amount: (transaction['amount'] ?? 0.0).toDouble(),
                        time: _formatTransactionTime(transaction['createdAt']),
                        category: transaction['category'] ?? 'Général',
                        icon: _getTransactionIcon(
                          transaction['type'] ?? 'general',
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Impossible de charger les transactions',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final cardsAsync = ref.watch(userCardsProvider);
        return cardsAsync.when(
          data: (cards) {
            if (cards.isEmpty || _currentPage >= cards.length) {
              return const Center(child: Text("Aucune carte sélectionnée."));
            }
            final card = cards[_currentPage];
            final isBlocked = !card.isActive;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSettingsSection('Sécurité', [
                  _buildSettingsItem(
                    'Changer le code PIN',
                    'Modifier votre code PIN de carte',
                    Icons.pin,
                    () => _showChangePinDialog(),
                  ),
                  _buildSettingsItem(
                    isBlocked ? 'Débloquer la carte' : 'Bloquer la carte',
                    isBlocked
                        ? 'Rendre votre carte de nouveau utilisable'
                        : 'Bloquer temporairement votre carte',
                    isBlocked ? Icons.lock_open : Icons.block,
                    () => _showBlockCardDialog(),
                  ),
                  _buildSettingsItem(
                    'Activation 3D Secure',
                    'Sécurité renforcée pour les achats en ligne',
                    Icons.security,
                    () => _toggle3DSecure(),
                    trailing: Switch(value: true, onChanged: (v) => _toggle3DSecure()),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSettingsSection('Limites et contrôles', [
                  _buildSettingsItem(
                    'Limites de paiement',
                    'Gérer vos limites quotidiennes',
                    Icons.payment,
                    () => _showLimitsDialog(),
                  ),
                  _buildSettingsItem(
                    'Paiement sans contact',
                    'Activer/désactiver le sans contact',
                    Icons.contactless,
                    () => _toggleContactless(),
                    trailing: Switch(
                      value: true,
                      onChanged: (v) => _toggleContactless(),
                    ),
                  ),
                  _buildSettingsItem(
                    'Paiements internationaux',
                    'Autoriser les paiements à l\'étranger',
                    Icons.public,
                    () => _toggleInternationalPayments(),
                    trailing: Switch(
                      value: false,
                      onChanged: (v) => _toggleInternationalPayments(),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSettingsSection('Notifications', [
                  _buildSettingsItem(
                    'Notifications SMS',
                    'Recevoir des SMS pour chaque transaction',
                    Icons.sms,
                    () => _toggleSMSNotifications(),
                    trailing: Switch(
                      value: true,
                      onChanged: (v) => _toggleSMSNotifications(),
                    ),
                  ),
                  _buildSettingsItem(
                    'Notifications push',
                    'Notifications instantanées sur l\'app',
                    Icons.notifications,
                    () => _togglePushNotifications(),
                    trailing: Switch(
                      value: true,
                      onChanged: (v) => _togglePushNotifications(),
                    ),
                  ),
                ]),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Center(child: Text("Erreur de chargement des paramètres.")),
        );
      },
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  // Méthodes de gestion des actions
  void _showCardDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Affichage des détails de carte')),
    );
  }

  void _showOrderCardDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Commander une nouvelle carte',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.credit_card, color: AppColors.primary),
                title: const Text('Carte Virtuelle'),
                subtitle: const Text('Idéale pour les paiements en ligne'),
                onTap: () {
                  Navigator.pop(context);
                  _createVirtualCard();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.credit_card, color: AppColors.accent),
                title: const Text('Carte Physique'),
                subtitle: const Text('Recevez une carte physique à votre domicile'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/cards/physical-request');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.indigo),
                title: const Text('Carte Virtuelle Stripe'),
                subtitle: const Text('Créez une carte virtuelle via Stripe'),
                onTap: () {
                  Navigator.pop(context);
                  // In a real app, you might navigate to a form first.
                  // Here, we just call the service.
                  _stripeService.createVirtualCard();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Création de la carte virtuelle Stripe simulée.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _createVirtualCard() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Création de votre carte virtuelle...'),
          ],
        ),
      ),
    );

    try {
      final cardId = await ref.read(createCardProvider({
        'cardType': 'prepaid',
        'cardName': 'Carte Virtuelle',
        'isVirtual': true,
        'limit': 500000.0,
      }).future);

      Navigator.pop(context); // Close loading dialog

      if (cardId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Carte virtuelle créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(userCardsProvider);
      } else {
        throw Exception('Impossible de créer la carte');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBlockCardDialog() {
    final cardsAsync = ref.read(userCardsProvider);
    cardsAsync.whenData((cards) {
      if (cards.isEmpty || _currentPage >= cards.length) return;

      final card = cards[_currentPage];
      final isCurrentlyActive = card.isActive;
      final actionText = isCurrentlyActive ? 'Bloquer' : 'Débloquer';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$actionText la carte ?'),
          content: Text(
              'Êtes-vous sûr de vouloir ${isCurrentlyActive ? 'bloquer temporairement' : 'débloquer'} cette carte ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await RealCardService.toggleCardStatus(card.id, !isCurrentlyActive);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Carte ${isCurrentlyActive ? 'bloquée' : 'débloquée'} avec succès.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  ref.invalidate(userCardsProvider);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de l\'opération.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isBlocked ? Colors.green : Colors.red,
              ),
              child: Text(actionText),
            ),
          ],
        ),
      );
    });
  }

  void _showChangePinDialog() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Changement de code PIN')));
  }

  void _showLimitsDialog() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gestion des limites')));
  }

  void _toggleContactless() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Basculement sans contact')));
  }

  void _toggle3DSecure() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Basculement 3D Secure')));
  }

  void _toggleInternationalPayments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Basculement paiements internationaux')),
    );
  }

  void _toggleSMSNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Basculement notifications SMS')),
    );
  }

  void _togglePushNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Basculement notifications push')),
    );
  }

  void _showShareDialog(CardModel card) {
    // In a real app, we'd fetch user details from the IDs in card.sharedWith
    // For now, we'll just display the IDs.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Partager la carte'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Partagée avec:'),
                if (card.sharedWith.isEmpty)
                  const Text('Personne'),
                ...card.sharedWith.map((userId) => ListTile(
                      title: Text('Utilisateur ${userId.substring(0, 6)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          RealCardService.unshareCard(card.id, userId);
                          Navigator.pop(context);
                          ref.invalidate(userCardsProvider);
                        },
                      ),
                    )),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Simplified: add a mock user ID
                    final mockFriendId = 'friend_${DateTime.now().millisecondsSinceEpoch}';
                    RealCardService.shareCard(card.id, mockFriendId);
                    Navigator.pop(context);
                    ref.invalidate(userCardsProvider);
                  },
                  child: const Text('Partager avec un ami'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}
